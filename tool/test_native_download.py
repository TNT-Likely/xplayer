"""Offline regression tests for the native dependency supply path."""
import hashlib
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import importlib.util
from pathlib import Path
import tempfile
import threading
import unittest
import shutil
import subprocess
import os
import runpy
import venv
import json
from unittest.mock import patch

ROOT = Path(__file__).resolve().parent.parent
SPEC = importlib.util.spec_from_file_location('native_download', ROOT / 'packages/libmpv_xplayer/tool/download_artifact.py')
native = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(native)


class NativeDownloadTest(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.target = Path(self.directory.name) / 'native.tar.gz'
        self.payload = b'verified native input'
        self.digest = hashlib.sha256(self.payload).hexdigest()
        self.responses = [(200, self.payload)]
        self.requests = 0
        self.declared_length = None
        case = self

        class Handler(BaseHTTPRequestHandler):
            def log_message(self, *_args):
                pass

            def do_GET(self):
                case.requests += 1
                status, data = case.responses[min(case.requests - 1, len(case.responses) - 1)]
                self.send_response(status)
                if case.declared_length is not None:
                    self.send_header('Content-Length', str(case.declared_length))
                self.end_headers()
                self.wfile.write(data)

        self.server = ThreadingHTTPServer(('127.0.0.1', 0), Handler)
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.thread.start()
        self.url = f'http://127.0.0.1:{self.server.server_port}/native.tar.gz'

    def tearDown(self):
        self.server.shutdown()
        self.server.server_close()
        self.thread.join(timeout=5)
        self.directory.cleanup()

    def fetch(self):
        with patch.object(native.time, 'sleep'):
            return native.download_artifact(self.url, self.digest, self.target)

    def test_verified_cache_does_not_contact_network(self):
        self.target.write_bytes(self.payload)
        self.assertEqual(self.fetch(), self.target)
        self.assertEqual(self.requests, 0)

    def test_transient_server_error_retries_then_atomically_replaces_bad_cache(self):
        self.target.write_bytes(b'incomplete old input')
        self.responses = [(503, b'temporary'), (200, self.payload)]
        self.fetch()
        self.assertEqual(self.requests, 2)
        self.assertEqual(self.target.read_bytes(), self.payload)
        self.assertEqual(list(self.target.parent.glob('*.part')), [])

    def test_changed_upstream_hash_fails_without_retry_or_install(self):
        self.responses = [(200, b'replaced upstream asset')]
        with self.assertRaisesRegex(RuntimeError, f'expected {self.digest}, received'):
            self.fetch()
        self.assertEqual(self.requests, 1)
        self.assertFalse(self.target.exists())
        self.assertEqual(list(self.target.parent.glob('*.part')), [])

    def test_missing_asset_does_not_spend_a_retry_budget(self):
        self.responses = [(404, b'not found')]
        with self.assertRaises(native.urllib.error.HTTPError):
            self.fetch()
        self.assertEqual(self.requests, 1)
        self.assertEqual(list(self.target.parent.glob('*.part')), [])

    def test_network_failures_are_bounded_and_leave_no_partial_asset(self):
        self.responses = [(503, b'unavailable')]
        with self.assertRaises(native.urllib.error.HTTPError):
            self.fetch()
        self.assertEqual(self.requests, 3)
        self.assertFalse(self.target.exists())
        self.assertEqual(list(self.target.parent.glob('*.part')), [])

    def test_truncated_http_body_retries_without_installing_a_partial_archive(self):
        self.declared_length = len(self.payload) + 20
        with self.assertRaises(native.IncompleteRead):
            self.fetch()
        self.assertEqual(self.requests, 3)
        self.assertFalse(self.target.exists())
        self.assertEqual(list(self.target.parent.glob('*.part')), [])

    def cmake_fetch(self):
        if not shutil.which('cmake'):
            self.skipTest('CMake is required for native build download checks')
        script = self.target.parent / 'download.cmake'
        script.write_text(f'include("{(ROOT / "packages/libmpv_xplayer/windows/download_and_verify.cmake").as_posix()}")\n'
                          f'download_and_verify("{self.url}" "{self.digest}" "{self.target.as_posix()}")\n', encoding='utf-8')
        return subprocess.run(['cmake', '-P', str(script)], capture_output=True, text=True, timeout=20)

    def test_cmake_retries_transient_http_then_verifies(self):
        self.responses = [(503, b'temporary'), (200, self.payload)]
        result = self.cmake_fetch()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(self.requests, 2)
        self.assertEqual(self.target.read_bytes(), self.payload)

    def test_cmake_rejects_changed_asset_and_removes_temporary_file(self):
        self.responses = [(200, b'changed asset')]
        result = self.cmake_fetch()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Received:', result.stderr)
        self.assertEqual(self.requests, 1)
        self.assertFalse(self.target.exists())
        self.assertFalse(Path(str(self.target) + '.part').exists())

    def test_cmake_does_not_retry_a_missing_asset(self):
        self.responses = [(404, b'not found')]
        self.assertNotEqual(self.cmake_fetch().returncode, 0)
        self.assertEqual(self.requests, 1)


class AppleBuildEnvironmentTest(unittest.TestCase):
    @unittest.skipUnless(os.name == 'posix', 'Apple build tools use a POSIX venv')
    def test_meson_starts_after_a_cached_venv_is_moved_with_the_checkout(self):
        command = runpy.run_path(str(ROOT / 'packages/libmpv_xplayer/ios/build_simulator_audio.py'))['meson_command']
        with tempfile.TemporaryDirectory() as directory:
            before = Path(directory) / 'original'; after = Path(directory) / 'moved'
            venv.create(before, with_pip=False)
            site = Path(subprocess.check_output([str(before / 'bin/python'), '-c',
                        'import site; print(site.getsitepackages()[0])'], text=True).strip())
            module = site / 'mesonbuild'; module.mkdir()
            (module / '__init__.py').touch()
            (module / 'mesonmain.py').write_text('import json,sys; print(json.dumps(sys.argv[1:]))', encoding='utf-8')
            (before / 'bin/meson').write_text(f'#!{before}/bin/python\nraise SystemExit(99)\n', encoding='utf-8')
            before.rename(after)
            result = subprocess.run(command(after, '--version'), text=True, capture_output=True)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(json.loads(result.stdout), ['--version'])


if __name__ == '__main__':
    unittest.main()
