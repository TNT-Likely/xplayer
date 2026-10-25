"""Regression checks for player source artifact boundaries and reproducibility."""
import hashlib
import os
from pathlib import Path
import tarfile
import tempfile
import unittest
from types import SimpleNamespace
from unittest.mock import patch
import json
import sys
import subprocess
import runpy

from package_player import ROOT, ignored, validate_documentation_links, write_archive
import verify_darwin_distribution as darwin

validate_assets = runpy.run_path(str(ROOT / 'packages/xplayer_player/tool/generate_playback_fixtures.py'))['validate_segment_assets']


class FixtureAssetsTest(unittest.TestCase):
    def test_hls_requires_both_initialization_and_media_segments(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'index.m3u8').write_text('#EXTM3U\n#EXT-X-MAP:URI="init.mp4"\nsegment.m4s\n', encoding='utf-8')
            with self.assertRaisesRegex(ValueError, 'init.mp4'): validate_assets(root)
            (root / 'init.mp4').write_bytes(b'init')
            with self.assertRaisesRegex(ValueError, 'segment.m4s'): validate_assets(root)
            (root / 'segment.m4s').write_bytes(b'media')
            validate_assets(root)

    def test_dash_requires_representation_init_and_numbered_media_files(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'index.mpd').write_text('<MPD xmlns="urn:mpeg:dash:schema:mpd:2011"><Period><AdaptationSet><Representation id="0"><SegmentTemplate initialization="init-$RepresentationID$.m4s" media="chunk-$RepresentationID$-$Number%05d$.m4s"/></Representation></AdaptationSet></Period></MPD>', encoding='utf-8')
            with self.assertRaisesRegex(ValueError, 'init-0.m4s'): validate_assets(root)
            (root / 'init-0.m4s').write_bytes(b'init')
            with self.assertRaisesRegex(ValueError, 'media segment'): validate_assets(root)
            (root / 'chunk-0-00001.m4s').write_bytes(b'media')
            validate_assets(root)


class PackageArtifactTest(unittest.TestCase):
    def test_packaging_chinese_docs_works_without_a_utf8_locale(self):
        with tempfile.TemporaryDirectory() as directory:
            env = dict(os.environ, LC_ALL='C', PYTHONUTF8='0',
                       PYTHONCOERCECLOCALE='0', PYTHONIOENCODING='ascii')
            result = subprocess.run([sys.executable,
                str(Path(__file__).with_name('package_player.py')),
                '--output', directory], env=env, capture_output=True,
                text=True, encoding='utf-8', timeout=60)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            report = Path(directory) / 'packaging-report.html'
            self.assertIn('播放器独立包分发验证', report.read_text(encoding='utf-8'))
            with tarfile.open(next(Path(directory).glob('libmpv_xplayer-*.tar.gz'))) as archive:
                self.assertIn('自包含', archive.extractfile('README.md').read().decode('utf-8'))

    def test_documentation_cannot_link_to_excluded_or_neighbor_files(self):
        with tempfile.TemporaryDirectory() as directory:
            package = Path(directory) / 'package'; package.mkdir()
            readme = package / 'README.md'
            readme.write_text('[guide](guide.md#setup) [web](https://example.test)')
            with self.assertRaisesRegex(ValueError, 'Broken shipped link'):
                validate_documentation_links(package)
            (package / 'guide.md').write_text('Guide')
            validate_documentation_links(package)
            (package.parent / 'private.md').write_text('outside package')
            readme.write_text('[leak](../private.md)')
            with self.assertRaises(ValueError): validate_documentation_links(package)

    def test_excludes_downloaded_native_assets_without_hiding_sources(self):
        patterns = ['**/Frameworks/', '**/.cache/', '**/build/', 'validation/']
        for path in ['ios/Frameworks/Mpv.xcframework/Mpv', 'ios/.cache/source.tar.gz',
                     'android/build/full-output/libmpv.jar', 'validation/report.json']:
            self.assertTrue(ignored(Path(path), patterns), path)
        for path in ['ios/Makefile', 'ios/build_simulator_audio.py', 'lib/libmpv_xplayer.dart']:
            self.assertFalse(ignored(Path(path), patterns), path)

    def test_archives_are_independent_of_source_mtime_and_preserve_payload(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory); source = root / 'source'; source.mkdir()
            file = source / 'pubspec.yaml'; file.write_text('name: portable_player\n')
            first = root / 'first.tar.gz'; second = root / 'second.tar.gz'
            write_archive(source, first)
            os.utime(file, (1_000_000_000, 1_000_000_000))
            write_archive(source, second)
            self.assertEqual(hashlib.sha256(first.read_bytes()).digest(),
                             hashlib.sha256(second.read_bytes()).digest())
            with tarfile.open(first) as archive:
                entry = archive.getmember('pubspec.yaml')
                self.assertEqual((entry.uid, entry.gid, entry.mtime), (0, 0, 0))
                self.assertEqual(archive.extractfile(entry).read(), file.read_bytes())


class AppleDistributionTest(unittest.TestCase):
    def test_ios_failure_propagates_and_cleans_only_its_created_device(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            runner = root / 'stage/sdk/player_api/tool/run_device_validation.py'
            runner.parent.mkdir(parents=True); runner.touch()
            (root / 'packaging-report.json').write_text(json.dumps({'stagingPath': str(root / 'stage')}))
            available = {'devices': {'test-runtime': [
                {'name': 'iPhone QA', 'deviceTypeIdentifier': 'test-type', 'udid': 'existing-user-device'}]}}
            argv = ['verify', '--packages', str(root), '--fixtures', str(root), '--platform', 'ios']
            with patch.object(sys, 'argv', argv), patch.object(darwin.subprocess, 'check_output',
                    side_effect=[json.dumps(available), 'new-owned-device\n']), patch.object(
                    darwin.subprocess, 'run', return_value=SimpleNamespace(returncode=7)) as run:
                self.assertEqual(darwin.main(), 7)
            commands = [call.args[0] for call in run.call_args_list]
            self.assertIn(['xcrun', 'simctl', 'shutdown', 'new-owned-device'], commands)
            self.assertIn(['xcrun', 'simctl', 'delete', 'new-owned-device'], commands)
            self.assertTrue(all('existing-user-device' not in command for command in commands))

    def test_missing_staging_copy_fails_before_device_operations(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'packaging-report.json').write_text(json.dumps({'stagingPath': str(root / 'missing')}))
            argv = ['verify', '--packages', str(root), '--fixtures', str(root), '--platform', 'ios']
            with patch.object(sys, 'argv', argv), patch.object(darwin.subprocess, 'run') as run:
                with self.assertRaisesRegex(RuntimeError, 'stage missing'): darwin.main()
            run.assert_not_called()


if __name__ == '__main__':
    unittest.main()
