#!/usr/bin/env python3
"""Local scratch field for manual end-to-end paste checks. No external requests."""
from http.server import BaseHTTPRequestHandler, HTTPServer

PAGE = b'''<!doctype html><html lang="en"><meta charset="utf-8">
<title>GPT Voice paste check</title>
<style>body{font:18px system-ui;margin:48px;max-width:760px}textarea{display:block;width:100%;height:240px;font:20px system-ui;padding:16px;margin-top:16px}</style>
<h1>Dictation paste check</h1><p>This is a local scratch field. Nothing is submitted.</p>
<label for="transcript">Transcript</label><textarea id="transcript" autofocus spellcheck="false"></textarea>
</html>'''


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path != "/":
            self.send_error(404)
            return
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(PAGE)))
        self.end_headers()
        self.wfile.write(PAGE)


if __name__ == "__main__":
    HTTPServer(("127.0.0.1", 9971), Handler).serve_forever()
