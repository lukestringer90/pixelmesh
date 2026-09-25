#!/usr/bin/env python3
"""
mock_companion_server.py

Zero-dependency WebSocket server for debugging the pixelmesh iOS wrapper and
Apple Watch companion without starting the full detection stack or cameras.
Uses standard library only (asyncio, hashlib, base64, struct).

Usage:
    python3 tools/mock_companion_server.py [--port 16924]
"""

import sys
import os
import time
import json
import base64
import hashlib
import struct
import asyncio
import argparse

WS_MAGIC = b"258EAFA5-E914-47DA-95CA-C5AB0DC85B11"

def make_ws_handshake_response(key: str) -> bytes:
    accept_val = base64.b64encode(hashlib.sha1(key.encode("utf-8") + WS_MAGIC).digest()).decode("utf-8")
    response = (
        "HTTP/1.1 101 Switching Protocols\r\n"
        "Upgrade: websocket\r\n"
        "Connection: Upgrade\r\n"
        f"Sec-WebSocket-Accept: {accept_val}\r\n\r\n"
    )
    return response.encode("utf-8")

def encode_ws_frame(text: str) -> bytes:
    data = text.encode("utf-8")
    length = len(data)
    frame = bytearray([0x81]) # Fin bit + Text opcode (1)
    if length <= 125:
        frame.append(length)
    elif length <= 65535:
        frame.append(126)
        frame.extend(struct.pack("!H", length))
    else:
        frame.append(127)
        frame.extend(struct.pack("!Q", length))
    frame.extend(data)
    return bytes(frame)

def decode_ws_frame(data: bytes):
    if len(data) < 2:
        return None, b""
    masked = bool(data[1] & 0x80)
    payload_len = data[1] & 0x7F
    offset = 2

    if payload_len == 126:
        if len(data) < 4:
            return None, b""
        payload_len = struct.unpack("!H", data[2:4])[0]
        offset = 4
    elif payload_len == 127:
        if len(data) < 10:
            return None, b""
        payload_len = struct.unpack("!Q", data[2:10])[0]
        offset = 10

    if masked:
        if len(data) < offset + 4 + payload_len:
            return None, b""
        mask = data[offset:offset+4]
        raw_payload = data[offset+4:offset+4+payload_len]
        decoded = bytes(b ^ mask[i % 4] for i, b in enumerate(raw_payload))
        remaining = data[offset+4+payload_len:]
        return decoded.decode("utf-8", errors="ignore"), remaining
    else:
        if len(data) < offset + payload_len:
            return None, b""
        decoded = data[offset:offset+payload_len]
        remaining = data[offset+payload_len:]
        return decoded.decode("utf-8", errors="ignore"), remaining

class MockCompanionServer:
    def __init__(self, port: int):
        self.port = port
        self.clients = set()

    async def handle_client(self, reader: asyncio.StreamReader, writer: asyncio.StreamWriter):
        headers = {}
        request_line = await reader.readline()
        if not request_line:
            writer.close()
            return

        while True:
            line = await reader.readline()
            if not line or line == b"\r\n":
                break
            parts = line.decode("utf-8", errors="ignore").split(":", 1)
            if len(parts) == 2:
                headers[parts[0].strip().lower()] = parts[1].strip()

        ws_key = headers.get("sec-websocket-key")
        if not ws_key:
            # HTTP fallback response
            writer.write(b"HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\npixelmesh mock server running\r\n")
            await writer.drain()
            writer.close()
            return

        # Complete WebSocket handshake
        writer.write(make_ws_handshake_response(ws_key))
        await writer.drain()
        print(f"[mock_server] Client connected ({len(self.clients) + 1} active)")
        self.clients.add(writer)

        # Initial server hello
        writer.write(encode_ws_frame(json.dumps({"type": "server_hello", "build_id": "mock-build"})))
        await writer.drain()

        # Task to receive messages
        async def read_loop():
            buffer = b""
            try:
                while True:
                    chunk = await reader.read(4096)
                    if not chunk:
                        break
                    buffer += chunk
                    while True:
                        msg_str, remaining = decode_ws_frame(buffer)
                        if msg_str is None:
                            break
                        buffer = remaining
                        try:
                            msg = json.loads(msg_str)
                            await self.handle_message(msg, writer)
                        except Exception as e:
                            pass
            except asyncio.CancelledError:
                pass
            finally:
                self.clients.discard(writer)
                print(f"[mock_server] Client disconnected ({len(self.clients)} active)")

        await read_loop()

    async def handle_message(self, msg: dict, writer: asyncio.StreamWriter):
        mtype = msg.get("type")
        if mtype == "hello":
            print(f"[mock_server] Received hello from {msg.get('device_id')}")
            # Assign Phone #42
            assigned = {
                "type": "assigned",
                "blink_id": 41,
                "u": 0.5,
                "v": 0.5,
                "calibrated": False
            }
            writer.write(encode_ws_frame(json.dumps(assigned)))
            await writer.drain()

        elif mtype == "sync_ping":
            client_time = msg.get("client_time", 0)
            pong = {
                "type": "sync_pong",
                "client_time": client_time,
                "server_time": time.time() * 1000.0
            }
            writer.write(encode_ws_frame(json.dumps(pong)))
            await writer.drain()

    async def broadcast_loop(self):
        step = 0
        while True:
            await asyncio.sleep(4.0)
            if not self.clients:
                continue

            step = (step + 1) % 4
            now_ms = time.time() * 1000.0

            if step == 1:
                # Located
                print("[mock_server] Broadcasting: update_position (Located)")
                payload = {"type": "update_position", "u": 0.5, "v": 0.5, "calibrated": True}
            elif step == 2:
                # Wave Effect
                print("[mock_server] Broadcasting: effect (Wave)")
                payload = {
                    "type": "effect",
                    "effect": "wave",
                    "start_time": now_ms,
                    "speed": 0.4,
                    "spatial_freq": 1.5,
                    "bpm": 100.0,
                    "angle": 0.0,
                    "origin_u": 0.5,
                    "origin_v": 0.5,
                    "color_r": 0.0,
                    "color_g": 220.0,
                    "color_b": 255.0
                }
            elif step == 3:
                # Effect Stop
                print("[mock_server] Broadcasting: effect_stop")
                payload = {"type": "effect_stop"}
            else:
                # Waiting / Get ready
                print("[mock_server] Broadcasting: reset")
                payload = {"type": "reset"}

            frame = encode_ws_frame(json.dumps(payload))
            for c in list(self.clients):
                try:
                    c.write(frame)
                    await c.drain()
                except Exception:
                    self.clients.discard(c)

    async def run(self):
        server = await asyncio.start_server(self.handle_client, "0.0.0.0", self.port)
        print(f"[mock_server] Listening on ws://0.0.0.0:{self.port}/ws")
        asyncio.create_task(self.broadcast_loop())
        async with server:
            await server.serve_forever()

def main():
    parser = argparse.ArgumentParser(description="pixelmesh mock companion WebSocket server")
    parser.add_argument("--port", type=int, default=16924, help="Port to listen on (default 16924)")
    args = parser.parse_args()

    server = MockCompanionServer(args.port)
    try:
        asyncio.run(server.run())
    except KeyboardInterrupt:
        print("\n[mock_server] Stopped.")

if __name__ == "__main__":
    main()
