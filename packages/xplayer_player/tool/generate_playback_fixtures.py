"""Generate small, deterministic decoder fixtures; requires an FFmpeg CLI."""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import subprocess


def generate(output, ffmpeg):
    output = Path(output)
    output.mkdir(parents=True, exist_ok=True)
    fixtures = [
        ("h264-aac.flv", "libx264", "aac", []),
        ("h264-aac.mp4", "libx264", "aac", ["-s", "640x360", "-profile:v", "baseline", "-movflags", "+faststart"]),
        ("h264-high-aac-1080p.mp4", "libx264", "aac", ["-s", "1920x1080", "-r", "30", "-profile:v", "high", "-preset", "veryfast", "-movflags", "+faststart"]),
        ("hevc-aac.mp4", "libx265", "aac", ["-s", "1280x720", "-tag:v", "hvc1", "-x265-params", "log-level=error:pools=1"]),
        ("h264-mp3.flv", "libx264", "libmp3lame", []),
        ("h264-aac-latm.ts", "libx264", "aac", ["-mpegts_flags", "latm"]),
        ("h264-ac3.ts", "libx264", "ac3", []),
        ("hevc-eac3.mkv", "libx265", "eac3", ["-x265-params", "log-level=error:pools=1"]),
        ("hevc-main10-eac3.mkv", "libx265", "eac3", ["-pix_fmt", "yuv420p10le", "-profile:v", "main10", "-x265-params", "log-level=error:pools=1"]),
        ("vp9-opus.webm", "libvpx-vp9", "libopus", []),
        ("vp8-vorbis.webm", "libvpx", "libvorbis", []),
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
        encoded = subprocess.run(args, capture_output=True, text=True, encoding="utf-8")
        if encoded.returncode:
            raise RuntimeError(f"Cannot generate {name}: {encoded.stderr[-1200:]}")
        result.append({"name": name, "file": name, "expectVideo": True, "expectAudio": True})
    for name, audio in [
        ("audio-aac.aac", "aac"),
        ("audio-mp3.mp3", "libmp3lame"),
        ("audio-flac.flac", "flac"),
        ("audio-alac.m4a", "alac"),
        ("audio-opus.ogg", "libopus"),
        ("audio-vorbis.ogg", "libvorbis"),
        ("audio-pcm.wav", "pcm_s16le"),
    ]:
        subprocess.run([ffmpeg, "-hide_banner", "-loglevel", "error", "-y",
                        "-f", "lavfi", "-i", "sine=frequency=1000:sample_rate=48000",
                        "-t", "4", "-ac", "2", "-c:a", audio, str(output / name)],
                       check=True, capture_output=True)
        result.append({"name": name, "file": name, "expectVideo": False, "expectAudio": True})
    # Self-generated HE-AAC tones are bundled because the redistributable
    # FFmpeg CLI used in CI cannot encode the SBR / parametric stereo profiles.
    for version, expected_hash in [
        ("v1", "2ea6b7e580d02e317f426268d9b5a88d7bf8b591a8643055763977b92f04a697"),
        ("v2", "83ff236f3c6b22bc72d67fcd72fa2f16863747c4b5df1f73abe1c9f85f288118"),
    ]:
        name = f"aac-he-{version}.m4a"
        bundled = Path(__file__).resolve().parent.parent / "test/fixtures" / name
        if hashlib.sha256(bundled.read_bytes()).hexdigest() != expected_hash:
            raise RuntimeError(f"Fixture SHA-256 mismatch: {name}")
        shutil.copyfile(bundled, output / name)
        result.append({"name": name, "file": name, "expectVideo": False, "expectAudio": True})
        name = f"h264-aac-he-{version}.ts"
        subprocess.run([ffmpeg, "-hide_banner", "-loglevel", "error", "-y",
                        "-i", str(output / "h264-aac.flv"), "-i", str(bundled),
                        "-map", "0:v:0", "-map", "1:a:0", "-c", "copy",
                        "-shortest", str(output / name)], check=True, capture_output=True)
        result.append({"name": name, "file": name, "expectVideo": True, "expectAudio": True})
    for fmt, name in [("hls", "hls/index.m3u8"), ("dash", "dash/index.mpd")]:
        path = output / name
        path.parent.mkdir(exist_ok=True)
        subprocess.run([ffmpeg, "-hide_banner", "-loglevel", "error", "-y",
                        "-i", str(output / "h264-aac.flv"), "-c", "copy", "-f", fmt, str(path)],
                       check=True, capture_output=True)
        result.append({"name": fmt, "file": name, "expectVideo": True, "expectAudio": True})
    path = output / "hls-fmp4/index.m3u8"
    path.parent.mkdir(exist_ok=True)
    subprocess.run([ffmpeg, "-hide_banner", "-loglevel", "error", "-y",
                    "-i", str(output / "h264-aac.mp4"), "-c", "copy", "-f", "hls",
                    "-hls_segment_type", "fmp4", str(path)], check=True, capture_output=True)
    result.append({"name": "hls-fmp4", "file": "hls-fmp4/index.m3u8",
                   "expectVideo": True, "expectAudio": True})
    (output / "manifest.json").write_text(json.dumps(result, indent=2) + "\n", encoding="utf-8")
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
