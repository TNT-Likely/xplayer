"""Run actual playback from an externally staged Apple package build."""
import argparse
import json
from pathlib import Path
import subprocess
import sys
import uuid


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--packages', required=True)
    parser.add_argument('--fixtures', required=True)
    parser.add_argument('--platform', required=True, choices=['ios', 'macos'])
    args = parser.parse_args()
    output = Path(args.packages).resolve()
    stage = Path(json.loads((output / 'packaging-report.json').read_text())['stagingPath'])
    runner = stage / 'sdk/player_api/tool/run_device_validation.py'
    if not runner.is_file():
        raise RuntimeError('External package stage missing; package with --keep-staging')
    device = 'macos'
    owned = None
    try:
        if args.platform == 'ios':
            devices = json.loads(subprocess.check_output(
                ['xcrun', 'simctl', 'list', 'devices', 'available', '--json'], text=True))['devices']
            template = next((runtime, device) for runtime, entries in devices.items()
                            for device in entries if 'iPhone' in device['name'])
            owned = subprocess.check_output([
                'xcrun', 'simctl', 'create', 'XPlayer-Package-' + uuid.uuid4().hex[:8],
                template[1]['deviceTypeIdentifier'], template[0]], text=True).strip()
            device = owned
            subprocess.run(['xcrun', 'simctl', 'boot', device], check=True, timeout=60)
            subprocess.run(['xcrun', 'simctl', 'bootstatus', device, '-b'], check=True, timeout=240)
        return subprocess.run([
            sys.executable, str(runner), '--platform', args.platform, '--device', device,
            '--fixtures', str(Path(args.fixtures).resolve()), '--report',
            str(output / ('device-' + args.platform + '.json'))], timeout=1800).returncode
    finally:
        if owned:
            subprocess.run(['xcrun', 'simctl', 'shutdown', owned], capture_output=True, timeout=60)
            subprocess.run(['xcrun', 'simctl', 'delete', owned], capture_output=True, timeout=60)


if __name__ == '__main__':
    raise SystemExit(main())
