"""Generate small, deterministic decoder fixtures; requires an FFmpeg CLI."""
import argparse
import json
from pathlib import Path
import shutil
import subprocess


def generate(output, ffmpeg):
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    fixtures = [
        ("h264-aac.flv", "libx264", "aac", []),
        ("h264-ac3.ts", "libx264", "ac3", []),
        ("hevc-eac3.mkv", "libx265", "eac3", ["-x265-params", "log-level=error:pools=1"]),
        ("hevc-main10-eac3.mkv", "libx265", "eac3", ["-pix_fmt", "yuv420p10le", "-profile:v", "main10", "-x265-params", "log-level=error:pools=1"]),
        ("vp9-opus.webm", "libvpx-vp9", "libopus", []),
        ("av1-aac.mp4", "libaom-av1", "aac", ["-cpu-used", "8"]),
        ("h264-mp2.ts", "libx264", "mp2", []),
        ("h264-dts.mkv", "libx264", "dca", ["-strict", "-2"]),
        ("h264-truehd.mkv", "libx264", "truehd", ["-strict", "-2"]),
        ("h264-truehd-5.1.mkv", "libx264", "truehd", ["-ac", "6", "-strict", "-2"]),
        ("h264-mlp.mkv", "libx264", "mlp", ["-strict", "-2"]),
        ("h264-flac.mkv", "libx264", "flac", []),
        ("h264-alac.mov", "libx264", "alac", []),
        ("mpeg2-mp2.ts", "mpeg2video", "mp2", []),
        ("mpeg4-pcm.avi", "mpeg4", "pcm_s16le", []),
        ("wmv2-wma2.asf", "wmv2", "wmav2", []),
    ]
    result = []
    for name, video, audio, extra in fixtures:
        args = [ffmpeg, "-hide_banner", "-loglevel", "error", "-y",
                "-f", "lavfi", "-i", "testsrc=size=160x96:rate=12",
                "-f", "lavfi", "-i", "sine=frequency=1000:sample_rate=48000",
                "-t", "4", "-pix_fmt", "yuv420p", "-c:v", video, "-c:a", audio,
                *extra, str(output / name)]
        encoded = subprocess.run(args, capture_output=True, text=True)
        if encoded.returncode:
            raise RuntimeError(f"Cannot generate {name}: {encoded.stderr[-1200:]}")
        result.append({"name": name, "file": name, "expectVideo": True, "expectAudio": True})
    for fmt, name in [("hls", "hls/index.m3u8"), ("dash", "dash/index.mpd")]:
        path = output / name
        path.parent.mkdir(exist_ok=True)
        subprocess.run([ffmpeg, "-hide_banner", "-loglevel", "error", "-y",
                        "-i", str(output / "h264-aac.flv"), "-c", "copy", "-f", fmt, str(path)],
                       check=True, capture_output=True)
        result.append({"name": fmt, "file": name, "expectVideo": True, "expectAudio": True})
    (output / "manifest.json").write_text(json.dumps(result, indent=2) + "\n")
    return result


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", required=True)
    parser.add_argument("--ffmpeg", default=shutil.which("ffmpeg"))
    args = parser.parse_args()
    if not args.ffmpeg:
        parser.error("Supply --ffmpeg=/path/to/ffmpeg")
    generated = generate(args.output, args.ffmpeg)
    print(json.dumps({"fixtures": len(generated), "output": args.output}))
