"""打包独立组件源代码，排除工具环境与构建缓存。"""
from pathlib import Path
import sys
import zipfile

root = Path(__file__).resolve().parents[1]
if len(sys.argv) != 2:
    raise SystemExit('用法：python3 tool/package_source.py /absolute/path/xplayer-ui-0.1.0.zip')
target = Path(sys.argv[1]).resolve()
target.parent.mkdir(parents=True, exist_ok=True)
excluded = {'.tooling', '.dart_tool', 'build', 'coverage', '__pycache__', '.git'}
count = 0
with zipfile.ZipFile(target, 'w', zipfile.ZIP_DEFLATED, compresslevel=7) as archive:
    for path in sorted(root.rglob('*')):
        relative = path.relative_to(root)
        if not path.is_file() or set(relative.parts) & excluded:
            continue
        if path.name.startswith('.flutter-plugins') or path.name == '.DS_Store':
            continue
        if relative.as_posix() == 'pubspec.lock' or path == target:
            continue
        archive.write(path, 'xplayer_ui/' + relative.as_posix())
        count += 1
with zipfile.ZipFile(target) as archive:
    assert archive.testzip() is None
print(f'{target}\n{count} 个文件，{target.stat().st_size} 字节')
