"""本机播放验收服务；短效直播地址从私有 JSON 读取，不写入测试源码。"""
import argparse
import json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlparse

parser = argparse.ArgumentParser()
parser.add_argument('--root', required=True, type=Path)
parser.add_argument('--cases', type=Path)
parser.add_argument('--playlists', type=Path)
parser.add_argument('--port-file', required=True, type=Path)
args = parser.parse_args()


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *_):
        pass

    def do_GET(self):
        path = urlparse(self.path).path
        if path == '/config.json':
            base = f'http://{self.headers["Host"]}'
            cases = [
                {'name': name, 'url': f'{base}/{name}.flv', 'headers': {}}
                for name in ['h264-aac', 'h264-mp3']
            ] + (json.loads(args.cases.read_text()) if args.cases else [])
            data = json.dumps({'sources': cases}).encode()
            content_type = 'application/json'
        elif path == '/playlists.json' and args.playlists:
            data = args.playlists.read_bytes()
            content_type = 'application/json'
        elif path == '/flv-test.m3u' and args.playlists:
            data = (args.root / 'flv-test.m3u').read_bytes()
            content_type = 'audio/x-mpegurl'
        elif path in ['/h264-aac.flv', '/h264-mp3.flv']:
            data = (args.root / path.removeprefix('/')).read_bytes()
            content_type = 'video/x-flv'
        else:
            self.send_error(404)
            return
        self.send_response(200)
        self.send_header('Content-Type', content_type)
        self.send_header('Content-Length', str(len(data)))
        self.send_header('Cache-Control', 'no-store')
        self.end_headers()
        try:
            self.wfile.write(data)
        except (BrokenPipeError, ConnectionResetError):
            pass


server = ThreadingHTTPServer(('127.0.0.1', 0), Handler)
args.port_file.parent.mkdir(parents=True, exist_ok=True)
args.port_file.write_text(json.dumps({'port': server.server_port}))
print(f'Live-source QA server on 127.0.0.1:{server.server_port}', flush=True)
server.serve_forever()
