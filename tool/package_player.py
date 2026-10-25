"""Build and verify portable player source packages without publishing them."""
import argparse
import fnmatch
import gzip
import hashlib
import html
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tarfile
import tempfile
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parent.parent
PACKAGES = {'libmpv_xplayer': 'engines/complete_codec', 'xplayer_player': 'sdk/player_api'}


def field(path, key):
    match = re.search(r'^' + re.escape(key) + r':\s*([^\n]+)', path.read_text(), re.M)
    if not match:
        raise ValueError(f'Missing {key}: {path}')
    return match.group(1).strip().strip('\"\'')


def ignored(relative, patterns):
    name = relative.as_posix()
    for pattern in patterns:
        pattern = pattern.lstrip('/')
        if pattern.endswith('/'):
            prefixes = ['/'.join(relative.parts[:i]) + '/' for i in range(1, len(relative.parts))]
            if any(fnmatch.fnmatchcase(prefix, pattern) for prefix in prefixes):
                return True
        elif fnmatch.fnmatchcase(name, pattern):
            return True
    return False


def source_files(package):
    prefix = package.relative_to(ROOT).as_posix()
    names = subprocess.check_output(
        ['git', 'ls-files', '--cached', '--others', '--exclude-standard', '--', prefix],
        cwd=ROOT, text=True).splitlines()
    patterns = [line.strip() for line in (package / '.pubignore').read_text().splitlines()
                if line.strip() and not line.startswith('#')]
    for name in sorted(set(names)):
        file = ROOT / name
        if not file.is_file() or file.is_symlink():
            continue
        relative = file.relative_to(package)
        if ignored(relative, patterns):
            continue
        yield file, relative


def write_archive(source, destination):
    with destination.open('wb') as output, gzip.GzipFile(fileobj=output, mode='wb', mtime=0, filename='') as zipped:
        with tarfile.open(fileobj=zipped, mode='w') as archive:
            for file in sorted(source.rglob('*')):
                if file.is_file():
                    info = archive.gettarinfo(str(file), file.relative_to(source).as_posix())
                    info.mtime = info.uid = info.gid = 0
                    info.uname = info.gname = ''
                    info.mode = 0o755 if file.suffix == '.sh' or file.name == 'gradlew' else 0o644
                    with file.open('rb') as stream:
                        archive.addfile(info, stream)


def validate_documentation_links(package):
    """Check local Markdown links against the actual published file set."""
    for document in package.rglob('*.md'):
        for ref in re.findall(r'\]\(([^\s)]+)\)', document.read_text()):
            parsed = urlsplit(ref.strip('<>'))
            if parsed.scheme or parsed.netloc or not parsed.path:
                continue
            target = (document.parent / unquote(parsed.path)).resolve()
            if not target.is_relative_to(package.resolve()) or not target.exists():
                raise ValueError(f'Broken shipped link: {document.relative_to(package)} -> {ref}')


def render_report(report, destination):
    rows = ''.join('<tr><td>' + html.escape(c['name']) + '</td><td>' +
                   ('通过' if c['exitCode'] == 0 else '未通过') + '</td><td><a href="' +
                   html.escape(c['log']) + '">查看日志</a></td></tr>' for c in report['checks'])
    packages = ''.join('<li><a href="' + html.escape(p['archive']) + '">' +
                       html.escape(p['name'] + ' ' + p['version']) + '</a></li>' for p in report['packages'])
    status = '通过' if report['passed'] else '未通过 / 仅打包，尚未验证'
    destination.write_text('''<!doctype html><html lang="zh-CN"><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1"><title>播放器包分发验证</title>
<style>body{font:15px/1.8 -apple-system,BlinkMacSystemFont,"PingFang SC",sans-serif;color:#182334;background:#f5f6f8;margin:0;padding:32px}main{max-width:960px;margin:auto;background:white;border:1px solid #e3e7ec;border-radius:16px;padding:32px}h1{font-size:30px}table{width:100%;border-collapse:collapse}td,th{padding:12px;text-align:left;border-bottom:1px solid #e3e7ec}a{color:#187259}code{overflow-wrap:anywhere}p{overflow-wrap:anywhere}</style><main>
<h1>播放器独立包分发验证</h1><p><b>结果：''' + status + '</b></p><p>候选包已复制到仓库外，原生依赖使用不同目录，验证过程中不引用应用源码。此流程只打包和预检，不上传 pub.dev。</p><p>源码提交：<code>' + html.escape(report['commit']) + '</code></p><ul>' + packages + '</ul><table><thead><tr><th>检查</th><th>结果</th><th>证据</th></tr></thead><tbody>' + rows + '</tbody></table><p>压缩包校验值见 <a href="SHA256SUMS">SHA256SUMS</a>。本报告不替代设备格式、真机、长稳和多声道验收。</p></main></html>')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', required=True)
    parser.add_argument('--flutter', default=shutil.which('flutter'))
    parser.add_argument('--verify', action='store_true')
    parser.add_argument('--resolution', choices=['latest', 'lowest'], default='latest')
    parser.add_argument('--build', choices=['android', 'ios', 'macos', 'windows', 'linux'])
    parser.add_argument('--keep-staging', action='store_true')
    args = parser.parse_args()
    if (args.verify or args.build) and not args.flutter:
        parser.error('Supply --flutter=/path/to/flutter')
    output = Path(args.output).resolve(); output.mkdir(parents=True, exist_ok=True)
    stage = Path(tempfile.mkdtemp(prefix='xplayer-package-stage-')).resolve()
    report = {'commit': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip(),
              'verificationRequested': args.verify, 'buildPlatform': args.build,
              'sourceDirty': bool(subprocess.check_output(['git', 'status', '--porcelain'], cwd=ROOT)),
              'stagingPath': str(stage), 'resolution': args.resolution, 'packages': [], 'checks': [], 'passed': False}
    try:
        for name, folder in PACKAGES.items():
            source = ROOT / 'packages' / name; target = stage / folder
            for file, relative in source_files(source):
                dest = target / relative; dest.parent.mkdir(parents=True, exist_ok=True); shutil.copy2(file, dest)
            version = field(target / 'pubspec.yaml', 'version')
            if re.search(r'^\s+path:', (target / 'pubspec.yaml').read_text(), re.M):
                raise ValueError(f'{name} still has a path dependency')
            validate_documentation_links(target)
            archive = output / f'{name}-{version}.tar.gz'; write_archive(target, archive)
            report['packages'].append({'name': name, 'version': version, 'archive': archive.name,
                                       'sha256': hashlib.sha256(archive.read_bytes()).hexdigest()})
        (output / 'SHA256SUMS').write_text(''.join(p['sha256'] + '  ' + p['archive'] + '\n' for p in report['packages']))
        (stage / 'pubspec.yaml').write_text("name: player_package_validation\npublish_to: none\nenvironment:\n  sdk: '>=3.11.0 <4.0.0'\nworkspace:\n" + ''.join('  - ' + f + '\n' for f in PACKAGES.values()) + '  - sdk/player_api/example\n')
        def check(name, command, cwd, timeout=900):
            log = output / (name + '.log')
            with log.open('w') as stream:
                try:
                    result = subprocess.run(command, cwd=cwd, stdout=stream, stderr=subprocess.STDOUT, timeout=timeout)
                    code = result.returncode
                except subprocess.TimeoutExpired:
                    code = 124
            report['checks'].append({'name': name, 'exitCode': code, 'log': log.name})
            print(name, '通过' if code == 0 else f'失败 ({code})', flush=True)
            if code:
                raise RuntimeError(f'{name}: see {log}')
        if args.verify or args.build:
            check('resolve-external-workspace', [args.flutter, 'pub', 'downgrade' if args.resolution == 'lowest' else 'get'], stage)
            lowest_lock = (stage / 'pubspec.lock').read_bytes() if args.resolution == 'lowest' else None
            check('resolve-standalone-example', [args.flutter, 'pub', 'get'], stage / 'sdk/player_api/example')
            if lowest_lock is not None and (stage / 'pubspec.lock').read_bytes() != lowest_lock:
                raise RuntimeError('Example resolution changed the minimum dependency lock')
            shutil.copy2(stage / 'pubspec.lock', output / 'resolved-pubspec.lock')
        if args.verify:
            for name, folder in PACKAGES.items():
                check(name + '-publish-dry-run', [args.flutter, 'pub', 'publish', '--dry-run'], stage / folder)
                check(name + '-analyze', [args.flutter, 'analyze', '--no-pub'], stage / folder)
                check(name + '-tests', [args.flutter, 'test', '--no-pub'], stage / folder)
            check('standalone-example-analyze', [args.flutter, 'analyze', '--no-pub'], stage / 'sdk/player_api/example')
            check('standalone-example-test', [args.flutter, 'test', '--no-pub'], stage / 'sdk/player_api/example')
        if args.build:
            command = [args.flutter, 'build', 'apk' if args.build == 'android' else args.build, '--debug', '--no-pub']
            if args.build == 'ios': command.append('--simulator')
            check('standalone-example-build-' + args.build, command, stage / 'sdk/player_api/example', timeout=1800)
        report['passed'] = bool(report['checks']) and all(c['exitCode'] == 0 for c in report['checks'])
    except Exception as error:
        report['error'] = str(error)
        print(str(error), flush=True)
    finally:
        (output / 'packaging-report.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
        render_report(report, output / 'packaging-report.html')
        if not args.keep_staging: shutil.rmtree(stage)
    if report.get('error'):
        return 1
    return 0 if report['passed'] or not (args.verify or args.build) else 1


if __name__ == '__main__':
    raise SystemExit(main())
