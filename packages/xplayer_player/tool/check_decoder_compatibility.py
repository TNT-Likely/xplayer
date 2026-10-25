"""Run the pinned native decoder against generated media on macOS/Windows/Linux."""
import argparse
import ctypes.util
import hashlib
import json
import os
from pathlib import Path
import platform
import shutil
import subprocess
import sys
import tarfile
import tempfile
import urllib.request
from urllib.parse import urljoin, urlparse

ROOT = Path(__file__).resolve().parent.parent


def download(artifact, cache):
    archive = cache / artifact["url"].rsplit("/", 1)[-1]
    if not archive.exists() or hashlib.sha256(archive.read_bytes()).hexdigest() != artifact["sha256"]:
        temporary = archive.with_suffix(archive.suffix + ".part")
        request = urllib.request.Request(artifact["url"], headers={"User-Agent": "XPlayer decoder check"})
        with urllib.request.urlopen(request, timeout=90) as response, temporary.open("wb") as output:
            shutil.copyfileobj(response, output)
        if hashlib.sha256(temporary.read_bytes()).hexdigest() != artifact["sha256"]:
            temporary.unlink()
            raise RuntimeError("Native artifact SHA-256 mismatch")
        temporary.replace(archive)
    return archive


def native_library(manifest, cache, env):
    system = platform.system()
    if system == "Linux":
        library = ctypes.util.find_library("mpv")
        if not library:
            raise RuntimeError("Install libmpv-dev / libmpv2 before running decoder checks")
        return library
    if system == "Windows":
        if platform.machine().lower() not in ["amd64", "x86_64"]:
            raise RuntimeError("The Windows application currently targets x86_64")
        artifact = manifest["windows"]
        archive = download(artifact, cache)
        directory = cache / artifact["sha256"]
        if not (directory / "libmpv-2.dll").exists():
            directory.mkdir(exist_ok=True)
            subprocess.run(["cmake", "-E", "tar", "xvf", str(archive)],
                           cwd=directory, check=True, capture_output=True)
        return str(directory / "libmpv-2.dll")
    if system != "Darwin":
        raise RuntimeError(f"Unsupported probe host: {system}")
    artifact = manifest["darwin"]["macos"]
    archive = download(artifact, cache)
    directory = cache / artifact["sha256"]
    if not (directory / ".probe-ready").exists():
        if directory.exists():
            shutil.rmtree(directory)
        extraction = cache / "darwin-extract"
        extraction.mkdir(exist_ok=True)
        with tarfile.open(archive) as source:
            source.extractall(extraction, filter="data")
        directory.mkdir(exist_ok=True)
        for framework in extraction.glob("*/*.xcframework/macos-arm64_x86_64/*.framework"):
            target = directory / framework.name
            shutil.copytree(framework, target, symlinks=True, dirs_exist_ok=True)
            # Ad-hoc sign only test copies. Never edit the pub cache or SDK.
            subprocess.run(["codesign", "--force", "--sign", "-", str(target)],
                           check=True, capture_output=True)
        (directory / ".probe-ready").write_text(artifact["sha256"])
    env["DYLD_FRAMEWORK_PATH"] = str(directory)
    return str(directory / "Mpv.framework/Mpv")


def dart_binary():
    flutter = shutil.which("flutter")
    if flutter:
        sdk = Path(flutter).resolve().parent / "cache/dart-sdk/bin"
        candidate = sdk / ("dart.exe" if os.name == "nt" else "dart")
        if candidate.exists():
            return str(candidate)
    raise RuntimeError("Supply --dart with the actual Dart SDK executable")


def package_configuration():
    # Resolve from the invoking host first, then from this source package.
    # This works in workspaces, standalone checkouts and installed packages.
    for directory in [Path.cwd(), *Path.cwd().parents, ROOT, *ROOT.parents]:
        candidate = directory / '.dart_tool/package_config.json'
        if candidate.is_file():
            return str(candidate)
    raise RuntimeError('Run flutter pub get in the host or package first')


def native_package_root():
    """Resolve the installed plugin, including hosted caches and staged releases."""
    config = Path(package_configuration()).resolve()
    packages = json.loads(config.read_text())["packages"]
    entry = next(p for p in packages if p["name"] == "libmpv_xplayer")
    uri = urlparse(urljoin(config.as_uri(), entry["rootUri"]))
    if uri.scheme != "file":
        raise RuntimeError("Native plugin must resolve to a local package")
    return Path(urllib.request.url2pathname(uri.path))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--fixtures", required=True)
    parser.add_argument("--report", required=True)
    parser.add_argument("--dart")
    parser.add_argument("--libmpv")
    parser.add_argument("--cache", default=str(Path(tempfile.gettempdir()) / "xplayer-native-probe"))
    args = parser.parse_args()
    fixtures = Path(args.fixtures).resolve()
    cache = Path(args.cache).resolve()
    cache.mkdir(parents=True, exist_ok=True)
    env = dict(os.environ)
    manifest = json.loads((native_package_root() / "native_builds.json").read_text())
    library = args.libmpv or native_library(manifest, cache, env)
    entries = json.loads((fixtures / "manifest.json").read_text())
    results = []
    dart = args.dart or dart_binary()
    for entry in entries:
        command = [dart, f"--packages={package_configuration()}",
                   "tool/probe_decoder.dart", f"--libmpv={library}"]
        if entry.get("expectAudio", True):
            command.append("--require-audio")
        if entry.get("expectVideo", True):
            command.append("--require-video")
        command.append(str(fixtures / entry["file"]))
        try:
            completed = subprocess.run(command, cwd=ROOT, env=env, capture_output=True,
                                       text=True, timeout=45)
            records = [json.loads(line) for line in completed.stdout.splitlines() if line.startswith('{"source":')]
            result = records[-1] if records else {"decoded": False, "error": "No decoder result"}
            result["name"] = entry["name"]
            result["passed"] = completed.returncode == 0 and result.get("decoded") is True
        except subprocess.TimeoutExpired:
            result = {"name": entry["name"], "passed": False, "error": "ProcessTimeout"}
        results.append(result)
        print(json.dumps(result), flush=True)
    report = {"platform": platform.system(), "architecture": platform.machine(),
              "passed": sum(row["passed"] for row in results), "total": len(results), "results": results}
    Path(args.report).write_text(json.dumps(report, indent=2) + "\n")
    return 0 if report["passed"] == report["total"] else 1


if __name__ == "__main__":
    sys.exit(main())
