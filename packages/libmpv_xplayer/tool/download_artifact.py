"""Fetch pinned build inputs atomically; retry transport failures, never bad hashes."""
import hashlib
from http.client import IncompleteRead
from pathlib import Path
import tempfile
import time
import urllib.error
import urllib.request


def sha256(path):
    digest = hashlib.sha256()
    with Path(path).open('rb') as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b''):
            digest.update(block)
    return digest.hexdigest()


def download_artifact(url, expected, target, *, attempts=3, timeout=120):
    target = Path(target)
    if target.is_file() and sha256(target) == expected:
        return target
    target.parent.mkdir(parents=True, exist_ok=True)
    for attempt in range(attempts):
        temporary = None
        try:
            request = urllib.request.Request(url, headers={'User-Agent': 'XPlayer-native-build'})
            with tempfile.NamedTemporaryFile(dir=target.parent, prefix=target.name + '.',
                                             suffix='.part', delete=False) as output:
                temporary = Path(output.name)
                with urllib.request.urlopen(request, timeout=timeout) as response:
                    length = response.headers.get('Content-Length', '')
                    received = 0
                    while block := response.read(1024 * 1024):
                        output.write(block)
                        received += len(block)
                    if length.isdigit() and received != int(length):
                        raise IncompleteRead(b'', int(length) - received)
            actual = sha256(temporary)
            if actual != expected:
                raise RuntimeError(f'Native artifact SHA-256 mismatch for {target.name}: '
                                   f'expected {expected}, received {actual}. '
                                   'Upstream may have replaced the asset; verify its provenance before updating the pin.')
            temporary.replace(target)
            return target
        except (urllib.error.URLError, TimeoutError, ConnectionError, IncompleteRead) as error:
            transient = not isinstance(error, urllib.error.HTTPError) or error.code == 429 or 500 <= error.code < 600
            if not transient or attempt + 1 == attempts:
                raise
            print(f'Native input {target.name}: transport failure; retry {attempt + 1}/{attempts - 1}', flush=True)
            time.sleep(2 ** attempt)
        finally:
            if temporary is not None:
                temporary.unlink(missing_ok=True)
    raise ValueError('attempts must be positive')
