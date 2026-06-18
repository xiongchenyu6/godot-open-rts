#!/usr/bin/env python3
"""Serve a Godot web export over HTTPS with the headers browsers require."""

from __future__ import annotations

import argparse
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
import ssl


class GodotWebHandler(SimpleHTTPRequestHandler):
    extensions_map = {
        **SimpleHTTPRequestHandler.extensions_map,
        ".js": "application/javascript",
        ".mjs": "application/javascript",
        ".wasm": "application/wasm",
        ".pck": "application/octet-stream",
    }

    def end_headers(self) -> None:
        self.send_header("Cross-Origin-Opener-Policy", "same-origin")
        self.send_header("Cross-Origin-Embedder-Policy", "require-corp")
        self.send_header("Cross-Origin-Resource-Policy", "same-origin")
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Cache-Control", "no-store, no-cache, must-revalidate, max-age=0")
        self.send_header("Pragma", "no-cache")
        self.send_header("Expires", "0")
        super().end_headers()


def _parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--bind", default="127.0.0.1", help="Address to bind.")
    parser.add_argument("--port", type=int, default=8765, help="TCP port to bind.")
    parser.add_argument(
        "--directory",
        default="docs",
        help="Directory containing index.html, index.js, index.wasm, and index.pck.",
    )
    parser.add_argument("--cert", required=True, help="TLS certificate path.")
    parser.add_argument("--key", required=True, help="TLS private key path.")
    return parser.parse_args()


def main() -> None:
    args = _parse_args()
    directory = Path(args.directory).resolve()
    cert = Path(args.cert).resolve()
    key = Path(args.key).resolve()
    if not directory.is_dir():
        raise SystemExit(f"Missing web export directory: {directory}")
    if not cert.is_file():
        raise SystemExit(f"Missing TLS certificate: {cert}")
    if not key.is_file():
        raise SystemExit(f"Missing TLS private key: {key}")

    handler = partial(GodotWebHandler, directory=str(directory))
    server = ThreadingHTTPServer((args.bind, args.port), handler)
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    context.load_cert_chain(str(cert), str(key))
    server.socket = context.wrap_socket(server.socket, server_side=True)
    print(f"Serving {directory} at https://{args.bind}:{args.port}/", flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()
