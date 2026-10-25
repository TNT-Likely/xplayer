"""Exercise HTTP/HLS regressions against the real pinned native decoder, offline."""
import argparse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import threading
import time
from urllib.parse import urlsplit

from check_decoder_compatibility import ROOT, dart_binary, native_library, package_configuration, native_package_root


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--fixtures', required=True)
    parser.add_argument('--report', required=True)
    parser.add_argument('--dart')
    parser.add_argument('--cache', default=str(Path(tempfile.gettempdir()) / 'xplayer-native-probe'))
    args = parser.parse_args()
    fixtures = Path(args.fixtures).resolve()
    env = dict(os.environ)
    cache = Path(args.cache).resolve()
    cache.mkdir(parents=True, exist_ok=True)
    manifest = json.loads((native_package_root() / 'native_builds.json').read_text(encoding="utf-8"))
    library = native_library(manifest, cache, env)
    requests = []

    class Handler(BaseHTTPRequestHandler):
        def log_message(self, *_args):
            pass

        def do_GET(self):
            target = urlsplit(self.path)
            requests.append((target.path, target.query))
            if self.headers.get('User-Agent') != 'Mozilla/5.0':
                self.send_error(423)
                return
            if target.path == '/forbidden.flv':
                self.send_error(403)
                return
            if target.path in ['/browser.flv', '/redirect/master.m3u8']:
                self.send_response(302)
                self.send_header('Location', '/cdn/live.flv' if target.path == '/browser.flv' else '/cdn/master.m3u8')
                self.send_header('Content-Length', '0')
                self.end_headers()
                return
            if target.path == '/slow.flv':
                # Reproduce first-byte latency exceeding media_kit's old 5s.
                time.sleep(6)
            if target.path in ['/cdn/master.m3u8', '/recovery/master.m3u8']:
                primary = '/cdn/primary.m3u8?token=signed%2Bbytes'
                high, low = (primary, '/unusable/master.m3u8') if target.path.startswith('/cdn/') else ('/unusable/master.m3u8', primary)
                data = (f'#EXTM3U\n#EXT-X-STREAM-INF:BANDWIDTH=2800000\n{high}\n'
                        f'#EXT-X-STREAM-INF:BANDWIDTH=1200000\n{low}\n').encode()
                content_type = 'application/vnd.apple.mpegurl'
            elif target.path == '/unusable/master.m3u8':
                self.send_error(503)
                return
            elif target.path == '/cdn/primary.m3u8':
                if target.query != 'token=signed%2Bbytes':
                    self.send_error(403)
                    return
                data = (fixtures / 'hls/index.m3u8').read_bytes()
                content_type = 'application/vnd.apple.mpegurl'
            elif target.path.startswith('/cdn/') and target.path.endswith('.ts'):
                file = fixtures / 'hls' / Path(target.path).name
                if not file.is_file():
                    self.send_error(404)
                    return
                data = file.read_bytes()
                content_type = 'video/mp2t'
            else:
                if target.path not in ['/cdn/live.flv', '/slow.flv']:
                    self.send_error(404)
                    return
                data = (fixtures / 'h264-aac.flv').read_bytes()
                content_type = 'video/x-flv'
            start, end = 0, len(data) - 1
            range_header = self.headers.get('Range', '')
            if range_header.startswith('bytes='):
                lower, _, upper = range_header[6:].partition('-')
                start, end = int(lower or 0), int(upper) if upper else end
            end = min(end, len(data) - 1)
            if start > end:
                self.send_error(416)
                return
            self.send_response(206 if range_header else 200)
            self.send_header('Content-Type', content_type)
            self.send_header('Accept-Ranges', 'bytes')
            if range_header:
                self.send_header('Content-Range', f'bytes {start}-{end}/{len(data)}')
            self.send_header('Content-Length', str(end - start + 1))
            self.end_headers()
            try:
                self.wfile.write(data[start:end + 1])
            except (BrokenPipeError, ConnectionResetError):
                pass

    server = ThreadingHTTPServer(('127.0.0.1', 0), Handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    base = f'http://127.0.0.1:{server.server_port}'
    cases = [
        ('browser-agent-redirect-flv', '/browser.flv', [], True),
        ('signed-hls-master-redirect', '/redirect/master.m3u8', [], True),
        ('lower-bandwidth-recovery', '/recovery/master.m3u8', ['--lower-bandwidth'], True),
        ('slow-first-byte', '/slow.flv', [], True),
        ('http-403-classification', '/forbidden.flv', [], False),
    ]
    results = []
    try:
        for name, path, options, expect_decode in cases:
            requests.clear()
            command = [args.dart or dart_binary(), f'--packages={package_configuration()}',
                       'tool/probe_decoder.dart', f'--libmpv={library}',
                       '--require-audio', '--require-video', '--diagnose-errors', *options, base + path]
            try:
                completed = subprocess.run(command, cwd=ROOT, env=env, capture_output=True, text=True, timeout=45, encoding="utf-8")
                records = [json.loads(line) for line in completed.stdout.splitlines() if line.startswith('{"source":')]
                result = records[-1] if records else {'decoded': False, 'error': 'No decoder result'}
                passed = result.get('decoded') is expect_decode
                if expect_decode:
                    passed = passed and completed.returncode == 0
                else:
                    passed = passed and completed.returncode != 0 and result.get('httpStatus') == 403
                if name in ['signed-hls-master-redirect', 'lower-bandwidth-recovery']:
                    passed = passed and result.get('hlsRenditionSelected') is True
                    passed = passed and not any(p == '/unusable/master.m3u8' for p, _ in requests)
                    passed = passed and any(q == 'token=signed%2Bbytes' for _, q in requests)
                result.update(name=name, passed=bool(passed))
            except subprocess.TimeoutExpired:
                result = {'name': name, 'passed': False, 'error': 'ProcessTimeout'}
            results.append(result)
            print(json.dumps(result), flush=True)
    finally:
        server.shutdown()
        server.server_close()
    report = {'passed': sum(r['passed'] for r in results), 'total': len(results), 'results': results}
    Path(args.report).write_text(json.dumps(report, indent=2) + '\n', encoding="utf-8")
    return 0 if report['passed'] == report['total'] else 1


if __name__ == '__main__':
    sys.exit(main())
