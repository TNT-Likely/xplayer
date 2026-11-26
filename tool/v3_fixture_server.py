"""仅监听本机的 v3 验收源：M3U、XMLTV、失败切换与支持 Range 的合成视频。"""
import argparse
import datetime as dt
import json
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlparse, parse_qs

parser = argparse.ArgumentParser()
parser.add_argument('--media', required=True, type=Path)
parser.add_argument('--port-file', required=True, type=Path)
args = parser.parse_args()
media = args.media.read_bytes()
mode = 'normal'

class Handler(BaseHTTPRequestHandler):
    def log_message(self, *_): pass
    def reply(self, body, content_type='text/plain; charset=utf-8', status=200):
        data = body.encode() if isinstance(body, str) else body
        self.send_response(status)
        self.send_header('Content-Type', content_type)
        self.send_header('Content-Length', str(len(data)))
        self.send_header('Cache-Control', 'no-store')
        self.end_headers()
        if self.command != 'HEAD': self.wfile.write(data)
    def do_HEAD(self): self.do_GET()
    def do_GET(self):
        global mode
        path = urlparse(self.path)
        base = f'http://{self.headers["Host"]}'
        if path.path == '/mode':
            value = parse_qs(path.query).get('epg', ['normal'])[0]
            if value not in ['normal', 'error', 'stale', 'empty']: self.reply('invalid', status=400); return
            mode = value
            self.reply(json.dumps({'epg': mode}), 'application/json'); return
        if path.path in ['/live.m3u', '/noepg.m3u']:
            header = f'#EXTM3U x-tvg-url="{base}/guide.xml"' if path.path == '/live.m3u' else '#EXTM3U'
            lines = [header]
            for ident, name, group in [('qa-one', '验收一台', '综合'), ('qa-two', '验收二台', '体育'), ('qa-missing', '无节目单频道', '综合')]:
                lines += [f'#EXTINF:-1 tvg-id="{ident}" group-title="{group}",{name}', f'{base}/sample.mp4?channel={ident}']
            self.reply('\n'.join(lines), 'audio/x-mpegurl'); return
        if path.path == '/guide.xml':
            if mode == 'error': self.reply('fixture unavailable', status=503); return
            if mode == 'empty': self.reply('<tv/>', 'application/xml'); return
            now = dt.datetime.now(dt.timezone.utc)
            if mode == 'stale': now -= dt.timedelta(days=2)
            start = now.replace(minute=0, second=0, microsecond=0)
            entries = []
            for ident in ['qa-one', 'qa-two']:
                for offset in range(4):
                    a, b = start + dt.timedelta(hours=offset), start + dt.timedelta(hours=offset+1)
                    entries.append(f'<programme channel="{ident}" start="{a:%Y%m%d%H%M%S} +0000" stop="{b:%Y%m%d%H%M%S} +0000"><title>验证节目 {offset+1}</title></programme>')
            self.reply('<tv>'+''.join(entries)+'</tv>', 'application/xml'); return
        if path.path == '/sample.mp4':
            start, end, status = 0, len(media)-1, 200
            value = self.headers.get('Range')
            if value and value.startswith('bytes='):
                first, last = value[6:].split('-', 1)
                start = int(first or 0); end = min(int(last) if last else end, end); status = 206
            if start > end or start >= len(media):
                self.send_response(416); self.send_header('Content-Range', f'bytes */{len(media)}'); self.end_headers(); return
            self.send_response(status); self.send_header('Content-Type', 'video/mp4')
            self.send_header('Accept-Ranges', 'bytes'); self.send_header('Content-Length', str(end-start+1))
            if status == 206: self.send_header('Content-Range', f'bytes {start}-{end}/{len(media)}')
            self.end_headers()
            if self.command != 'HEAD':
                try: self.wfile.write(media[start:end+1])
                except (BrokenPipeError, ConnectionResetError): pass
            return
        self.reply('missing', status=404)

server = ThreadingHTTPServer(('127.0.0.1', 0), Handler)
args.port_file.parent.mkdir(parents=True, exist_ok=True)
args.port_file.write_text(json.dumps({'port': server.server_port, 'baseUrl': f'http://127.0.0.1:{server.server_port}'}))
print(f'v3 fixture server: http://127.0.0.1:{server.server_port}', flush=True)
server.serve_forever()
