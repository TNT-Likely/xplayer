"""Run the independent codec harness in the example, collect checkpoints and HTML."""
import argparse
from functools import partial
import html
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
import json
from pathlib import Path
import plistlib
import shutil
import subprocess
import threading
import time

ROOT = Path(__file__).resolve().parent.parent


def render(report, output):
    rows = ''.join('<tr><td>' + html.escape(str(r.get('name', ''))) + '</td><td>' +
                   html.escape(str(r.get('mode', ''))) + '</td><td>' +
                   ('预期失败已验证' if r.get('passed') and r.get('expectedFailure') else '通过' if r.get('passed') else '未通过') + '</td><td>' +
                   html.escape(str(r.get('message', ''))) + '</td></tr>' for r in report.get('results', []))
    output.write_text('''<!doctype html><html lang="zh-CN"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>独立包设备播放验收</title><style>body{font:15px/1.8 -apple-system,BlinkMacSystemFont,"PingFang SC",sans-serif;padding:24px;background:#f5f6f8;color:#182334}main{max-width:1100px;margin:auto;background:white;padding:28px;border-radius:14px}table{border-collapse:collapse;width:100%}th,td{padding:10px;border-bottom:1px solid #ddd;text-align:left}p,td{overflow-wrap:anywhere}.scroll{overflow:auto}table{min-width:600px}</style><main><h1>独立播放器包设备验收</h1><p><b>''' + str(report.get('passed', 0)) + ' / ' + str(report.get('expectedTotal', 0)) + ' 项通过</b> · ' + ('已完成' if report.get('complete') else '未完整完成') + '</p><p>' + html.escape(str(report.get('device', ''))) + ' · ' + html.escape(str(report.get('platform', ''))) + '</p><p>此流程使用独立示例中的核心后端，检查解码、视频输出状态与时钟。默认静音；不替代物理声音、真实像素、多声道或长稳验收。</p><p>' + html.escape(str(report.get('error', ''))) + '</p><div class="scroll"><table><thead><tr><th>样本</th><th>模式</th><th>结果</th><th>失败说明</th></tr></thead><tbody>' + rows + '</tbody></table></div></main></html>', encoding="utf-8")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--platform', choices=['android', 'ios', 'macos'], required=True)
    parser.add_argument('--device', required=True, help='Explicit adb/simctl device ID; use macos on desktop')
    parser.add_argument('--fixtures', required=True)
    parser.add_argument('--report', required=True)
    parser.add_argument('--flutter', default=shutil.which('flutter'))
    parser.add_argument('--adb', default=shutil.which('adb'))
    parser.add_argument('--mode', choices=['auto', 'software', 'both'], default='both')
    parser.add_argument('--filter', default='')
    parser.add_argument('--audible', action='store_true')
    parser.add_argument('--debug', action='store_true')
    parser.add_argument('--timeout', type=int, default=1200)
    args = parser.parse_args()
    if not args.flutter: parser.error('Supply --flutter=/path/to/flutter')
    if args.platform == 'android' and not args.adb: parser.error('Supply --adb=/path/to/adb')
    fixtures = Path(args.fixtures).resolve(); output = Path(args.report).resolve(); output.parent.mkdir(parents=True, exist_ok=True)
    entries = [e for e in json.loads((fixtures / 'manifest.json').read_text(encoding="utf-8")) if args.filter in e['name']]
    if not entries: parser.error('No matching fixtures')
    expected = len(entries) * (2 if args.mode == 'both' else 1)
    report = {'platform': args.platform, 'device': args.device, 'expectedTotal': expected,
              'complete': False, 'passed': 0, 'total': 0, 'results': [],
              'audioMode': 'system (audible)' if args.audible else 'system (muted)'}
    example = ROOT / 'example'; target = example / f'tool/playback_probe_{args.platform}.g.dart'; target.parent.mkdir(exist_ok=True)
    previous = target.read_bytes() if target.exists() else None
    target.write_bytes((ROOT / 'tool/playback_device_probe.dart').read_bytes())
    log = output.with_suffix('.log'); desktop = None; reverse = False; app_id = None
    device_logger = None; device_log_stream = None
    awake = None
    server = None; server_thread = None
    def command(parts, *, capture=False, cwd=example, timeout=600):
        if capture:
            return subprocess.check_output(parts, cwd=cwd, text=True, stderr=subprocess.DEVNULL, timeout=timeout, encoding="utf-8").strip()
        with log.open('a', encoding="utf-8") as stream:
            subprocess.run(parts, cwd=cwd, stdout=stream, stderr=subprocess.STDOUT, timeout=timeout, check=True)
    def adb(*parts, capture=False):
        return command([args.adb, '-s', args.device, *parts], capture=capture, timeout=20 if capture else 120)
    try:
        command([args.flutter, 'pub', 'get'], timeout=180)
        class Handler(SimpleHTTPRequestHandler):
            def log_message(self, *_args): pass
            def do_GET(self):
                if self.path == '/probe-config.json':
                    sources = [{**e, 'url': e.get('url') or f'http://127.0.0.1:{server.server_port}/' + e['file']} for e in entries]
                    body = json.dumps({'sources': sources}).encode()
                    self.send_response(200); self.send_header('Content-Type', 'application/json')
                    self.send_header('Content-Length', str(len(body))); self.end_headers(); self.wfile.write(body)
                else: super().do_GET()
        server = ThreadingHTTPServer(('127.0.0.1', 0), partial(Handler, directory=str(fixtures)))
        server_thread = threading.Thread(target=server.serve_forever, daemon=True); server_thread.start()
        defines = ['--dart-define=PLAYBACK_PROBE_CONFIG=http://127.0.0.1:' + str(server.server_port) + '/probe-config.json']
        if args.mode != 'both': defines.append('--dart-define=PLAYBACK_PROBE_MODE=' + args.mode)
        if args.audible: defines.append('--dart-define=PLAYBACK_PROBE_AUDIBLE=true')
        if args.debug: defines.append('--dart-define=PLAYBACK_PROBE_DEBUG=true')
        base = [args.flutter, 'build', 'apk' if args.platform == 'android' else args.platform,
                '--debug', '--no-pub', '-t', target.relative_to(example).as_posix(), *defines]
        if args.platform == 'android':
            command([args.adb, '-s', args.device, 'wait-for-device'], timeout=120)
            boot_deadline = time.monotonic() + 120
            while adb('shell', 'getprop', 'sys.boot_completed', capture=True) != '1':
                if time.monotonic() >= boot_deadline: raise TimeoutError('Android device did not finish booting')
                time.sleep(2)
            abi = adb('shell', 'getprop', 'ro.product.cpu.abi', capture=True)
            arch = {'arm64-v8a': 'android-arm64', 'armeabi-v7a': 'android-arm', 'x86_64': 'android-x64'}[abi]
            command([*base, '--target-platform=' + arch], timeout=1200)
            app_id = 'com.tntlikely.xplayer_player_example.probe'
            adb('shell', 'am', 'force-stop', app_id)
            adb('install', '-r', str(example / 'build/app/outputs/flutter-apk/app-debug.apk'))
            adb('shell', 'run-as', app_id, 'rm', '-f', 'files/codec_probe.json')
            adb('reverse', f'tcp:{server.server_port}', f'tcp:{server.server_port}'); reverse = True
            adb('shell', 'am', 'start', '-n', app_id + '/com.tntlikely.xplayer_player_example.MainActivity')
            pid_deadline = time.monotonic() + 15
            while True:
                try:
                    pid = adb('shell', 'pidof', app_id, capture=True).split()[0]
                    break
                except (subprocess.CalledProcessError, IndexError):
                    if time.monotonic() >= pid_deadline:
                        raise TimeoutError('Probe process did not start')
                    time.sleep(0.25)
            device_log_stream = output.with_suffix('.device.log').open('w', encoding="utf-8")
            device_logger = subprocess.Popen([args.adb, '-s', args.device, 'logcat', '--pid=' + pid, '-v', 'brief', 'flutter:I', '*:S'], stdout=device_log_stream, stderr=subprocess.STDOUT)
            def read_checkpoint():
                return json.loads(adb('shell', 'run-as', app_id, 'cat', 'files/codec_probe.json', capture=True))
        elif args.platform == 'ios':
            command([*base, '--simulator'], timeout=1200)
            app = example / 'build/ios/iphonesimulator/Runner.app'
            app_id = plistlib.loads((app / 'Info.plist').read_bytes())['CFBundleIdentifier']
            command(['xcrun', 'simctl', 'install', args.device, str(app)])
            container = Path(command(['xcrun', 'simctl', 'get_app_container', args.device, app_id, 'data'], capture=True))
            for file in (container / 'Library').rglob('codec_probe.json'): file.unlink()
            device_log_stream = log.open('a', encoding='utf-8')
            device_logger = subprocess.Popen(
                ['xcrun', 'simctl', 'launch', '--console', args.device, app_id],
                stdout=device_log_stream, stderr=subprocess.STDOUT)
            def read_checkpoint():
                return json.loads(next((container / 'Library').rglob('codec_probe.json')).read_text(encoding="utf-8"))
        else:
            command(base, timeout=1200)
            app = next((example / 'build/macos/Build/Products/Debug').glob('*.app'))
            info = plistlib.loads((app / 'Contents/Info.plist').read_bytes()); app_id = info['CFBundleIdentifier']
            container = Path.home() / 'Library/Containers' / app_id / 'Data/Library/Application Support'
            if container.exists():
                for file in container.rglob('codec_probe.json'): file.unlink()
            with log.open('a', encoding="utf-8") as stream:
                desktop = subprocess.Popen([str(app / 'Contents/MacOS' / info['CFBundleExecutable'])], stdout=stream, stderr=subprocess.STDOUT)
            # A visible foreground window and an awake display are prerequisites
            # for measuring rendered playback, rather than App Nap/occlusion.
            time.sleep(1)
            for attempt in range(3):
                activated = subprocess.run(['open', '-a', str(app)], capture_output=True, timeout=20)
                if activated.returncode == 0:
                    break
                if desktop.poll() is not None:
                    raise RuntimeError('Probe process exited during activation')
                time.sleep(1)
            else:
                # LaunchServices may not know a directly started debug app yet.
                # Actual process, texture and clock checks below remain required.
                report['activationWarning'] = activated.stderr.decode('utf-8', errors='replace').strip()
            awake = subprocess.Popen(['caffeinate', '-di', '-w', str(desktop.pid)])
            def read_checkpoint():
                return json.loads(next(container.rglob('codec_probe.json')).read_text(encoding="utf-8"))
        last = -1; deadline = time.monotonic() + args.timeout
        last_active = None; last_metric = 0
        metrics = []
        progress_deadline = time.monotonic() + 90
        while time.monotonic() < deadline:
            if desktop and desktop.poll() is not None:
                raise RuntimeError(f'Native probe exited before completing the matrix ({desktop.returncode}); see .log')
            if args.platform == 'ios' and device_logger and device_logger.poll() is not None:
                raise RuntimeError(f'Simulator probe exited before completing the matrix ({device_logger.returncode}); see .log')
            if time.monotonic() >= progress_deadline:
                if desktop and desktop.poll() is None:
                    with output.with_suffix('.sample.log').open('w', encoding='utf-8') as stream:
                        try:
                            subprocess.run(['sample', str(desktop.pid), '3', '-file', str(output.with_suffix('.sample.txt'))],
                                           stdout=stream, stderr=subprocess.STDOUT, timeout=15)
                        except subprocess.SubprocessError:
                            report.setdefault('cleanupWarnings', []).append('Native stack sampling failed')
                raise TimeoutError('No completed fixture for 90s; native startup or teardown stalled; see .log')
            try:
                current = read_checkpoint()
                report.update(current)
            except (OSError, ValueError, StopIteration, subprocess.CalledProcessError):
                time.sleep(2); continue
            active = current.get('activeCase')
            active_key = (current['total'], active.get('sample')) if active else None
            if active_key != last_active:
                last_active = active_key
                if active:
                    progress_deadline = time.monotonic() + 90
                    output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
            if desktop and time.monotonic() - last_metric >= 10:
                last_metric = time.monotonic()
                try:
                    values = subprocess.check_output(['ps', '-o', 'rss=,%cpu=', '-p', str(desktop.pid)], text=True, timeout=5).split()
                    metric = {'time': time.time(), 'rssKiB': int(values[0]), 'cpuPercent': float(values[1]),
                              'completed': current['total'], 'active': active}
                    metrics.append(metric)
                    with output.with_suffix('.metrics.jsonl').open('a', encoding='utf-8') as stream:
                        stream.write(json.dumps(metric, ensure_ascii=False) + '\n')
                except (subprocess.SubprocessError, ValueError, IndexError) as error:
                    report.setdefault('metricWarnings', []).append(type(error).__name__)
            if current['total'] != last:
                last = current['total']; print(f"{args.platform}: {current['passed']}/{last}, expected {expected}", flush=True)
                progress_deadline = time.monotonic() + 90
                output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding="utf-8")
            if current.get('complete'):
                if current['total'] != expected: raise RuntimeError('Incomplete fixture/mode coverage')
                break
            time.sleep(2)
        else: raise TimeoutError('Device matrix did not complete within its budget')
        if metrics:
            report['processMetrics'] = {'samples': len(metrics), 'firstRssKiB': metrics[0]['rssKiB'],
                'lastRssKiB': metrics[-1]['rssKiB'], 'peakRssKiB': max(m['rssKiB'] for m in metrics)}
    except Exception as error:
        report['error'] = str(error); report['complete'] = False
        print(str(error), flush=True)
    finally:
        if app_id:
            if args.platform == 'android':
                try: adb('shell', 'am', 'force-stop', app_id)
                except subprocess.SubprocessError: pass
            elif args.platform == 'ios':
                try:
                    subprocess.run(['xcrun', 'simctl', 'terminate', args.device, app_id], capture_output=True, timeout=20)
                except subprocess.TimeoutExpired:
                    report.setdefault('cleanupWarnings', []).append('simctl terminate timed out')
        if device_logger:
            device_logger.terminate()
            try: device_logger.wait(timeout=10)
            except subprocess.TimeoutExpired:
                device_logger.kill(); device_logger.wait(timeout=5)
            device_log_stream.close()
        if desktop:
            desktop.terminate()
            try: desktop.wait(timeout=10)
            except subprocess.TimeoutExpired: desktop.kill()
        if awake:
            awake.terminate()
            try: awake.wait(timeout=5)
            except subprocess.TimeoutExpired: awake.kill()
        if reverse:
            try:
                subprocess.run([args.adb, '-s', args.device, 'reverse', '--remove', f'tcp:{server.server_port}'], capture_output=True, timeout=20)
            except subprocess.TimeoutExpired:
                report.setdefault('cleanupWarnings', []).append('adb reverse cleanup timed out')
        if server:
            server.shutdown(); server.server_close(); server_thread.join(timeout=5)
        if previous is None: target.unlink(missing_ok=True)
        else: target.write_bytes(previous)
        output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding="utf-8")
        render(report, output.with_suffix('.html'))
    return 0 if report.get('complete') and report.get('total') == expected and report.get('passed') == expected else 1


if __name__ == '__main__':
    raise SystemExit(main())
