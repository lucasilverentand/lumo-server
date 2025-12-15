#!/usr/bin/env python3
"""
Minecraft Wake Listener - Accepts connections when server is paused
and sends a friendly "starting up" message to the client.

Handles both server list ping and login attempts.
"""

import socket
import struct
import json
import sys
import signal

def write_varint(value):
    """Encode an integer as a Minecraft VarInt."""
    result = b''
    while True:
        byte = value & 0x7F
        value >>= 7
        if value != 0:
            byte |= 0x80
        result += bytes([byte])
        if value == 0:
            break
    return result

def read_varint(data, offset=0):
    """Decode a VarInt from bytes, return (value, bytes_read)."""
    result = 0
    shift = 0
    for i in range(5):
        if offset + i >= len(data):
            return None, 0
        byte = data[offset + i]
        result |= (byte & 0x7F) << shift
        if not (byte & 0x80):
            return result, i + 1
        shift += 7
    return None, 0

def create_string_packet(packet_id, text):
    """Create a Minecraft packet with a string payload."""
    text_bytes = text.encode('utf-8')
    payload = write_varint(packet_id) + write_varint(len(text_bytes)) + text_bytes
    return write_varint(len(payload)) + payload

def create_status_response():
    """Create a server status response (for server list ping)."""
    status = {
        "version": {"name": "Sleeping", "protocol": 767},
        "players": {"max": 0, "online": 0},
        "description": {"text": "§6⏳ Server is sleeping\n§7Connect to wake it up!"},
        "enforcesSecureChat": False
    }
    return create_string_packet(0x00, json.dumps(status))

def create_disconnect_packet(state):
    """Create a disconnect packet with a friendly message."""
    if state == 'login':
        # Login disconnect uses packet ID 0x00
        message = json.dumps({
            "text": "⏳ Server is starting up...\n\n",
            "color": "gold",
            "extra": [{"text": "Please reconnect in a moment!", "color": "gray"}]
        })
        return create_string_packet(0x00, message)
    else:
        # For status, we don't disconnect
        return b''

def handle_client(client_socket):
    """Handle a single client connection."""
    try:
        client_socket.settimeout(5.0)
        data = client_socket.recv(1024)
        if not data:
            return False

        # Parse the handshake packet
        offset = 0
        packet_len, bytes_read = read_varint(data, offset)
        if packet_len is None:
            return True  # Trigger wake anyway
        offset += bytes_read

        packet_id, bytes_read = read_varint(data, offset)
        if packet_id is None or packet_id != 0x00:
            return True
        offset += bytes_read

        protocol_version, bytes_read = read_varint(data, offset)
        offset += bytes_read

        # Skip server address string
        str_len, bytes_read = read_varint(data, offset)
        if str_len is None:
            return True
        offset += bytes_read + str_len

        # Skip port (2 bytes)
        offset += 2

        # Next state: 1 = status, 2 = login
        next_state, bytes_read = read_varint(data, offset)

        if next_state == 1:
            # Status request (server list ping)
            # Wait for status request packet
            try:
                status_req = client_socket.recv(16)
            except:
                pass
            # Send status response
            client_socket.sendall(create_status_response())

            # Try to receive and respond to ping
            try:
                ping_data = client_socket.recv(32)
                if ping_data:
                    # Echo back the ping packet
                    client_socket.sendall(ping_data)
            except:
                pass
            return False  # Don't wake for status ping

        elif next_state == 2:
            # Login attempt - send disconnect and trigger wake
            client_socket.sendall(create_disconnect_packet('login'))
            return True  # Wake the server

        return True  # Unknown state, wake anyway

    except socket.timeout:
        return True  # Connection attempt, wake
    except Exception as e:
        print(f"[WakeListener] Error handling client: {e}", file=sys.stderr)
        return True  # Wake on error to be safe

def main():
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 25565
    wake_signal_file = sys.argv[2] if len(sys.argv) > 2 else '/tmp/autopause_wake'

    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.settimeout(1.0)

    try:
        server.bind(('0.0.0.0', port))
        server.listen(5)
        print(f"[WakeListener] Listening on port {port}", file=sys.stderr)

        while True:
            try:
                client, addr = server.accept()
                print(f"[WakeListener] Connection from {addr[0]}", file=sys.stderr)

                should_wake = handle_client(client)
                client.close()

                if should_wake:
                    print(f"[WakeListener] Triggering wake signal", file=sys.stderr)
                    # Write wake signal
                    with open(wake_signal_file, 'w') as f:
                        f.write('wake')
                    break

            except socket.timeout:
                # Check if we should still be running
                continue
            except Exception as e:
                print(f"[WakeListener] Accept error: {e}", file=sys.stderr)

    finally:
        server.close()

if __name__ == '__main__':
    signal.signal(signal.SIGTERM, lambda s, f: sys.exit(0))
    signal.signal(signal.SIGINT, lambda s, f: sys.exit(0))
    main()
