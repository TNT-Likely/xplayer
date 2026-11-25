"""Generate a sliding HLS source with repeatable late and expired segments."""

import argparse
import json
from pathlib import Path
import re
import shutil
import subprocess
import threading
import time


SEGMENT_SECONDS = 2
INITIAL_LAST = 4
FIRST_AFTER_EXPIRY = 7
LATE_SEGMENTS = range(5, 11)


class LiveHlsFixture:
    """One media playlist per run, with its clock starting at the first TS read."""

    def __init__(self, scenario, segments):
        if scenario not in ('late-segments', 'expired-segments'):
            raise ValueError(f'Unknown live HLS fixture: {scenario}')
        if len(segments) < 40:
            raise ValueError('Live HLS fixtures require at least 40 TS segments')
        self.scenario = scenario
        self.segments = segments
        self._lock = threading.Lock()
        self._first_read = None
        self._expiry_at = None
        self._first_segment = None
        self._late_segments = set()
        self._advanced = False
        self._resumed = False

    def payload(self, resource):
        if resource == 'index.m3u8':
            with self._lock:
                now = time.monotonic()
                if self.scenario == 'expired-segments':
                    if self._expiry_at is None or now < self._expiry_at:
                        first, last = 0, INITIAL_LAST
                    else:
                        # The client has read 4 and expects 5. The next window
                        # starts at 7, leaving ~4s missing on the real TS clock.
                        last = min(
                            FIRST_AFTER_EXPIRY + INITIAL_LAST + int((now - self._expiry_at) / SEGMENT_SECONDS),
                            len(self.segments) - 1,
                        )
                        first = last - INITIAL_LAST
                        self._advanced = True
                else:
                    elapsed = 0 if self._first_read is None else now - self._first_read
                    last = min(INITIAL_LAST + int(elapsed / SEGMENT_SECONDS), len(self.segments) - 1)
                    # Keep the slow segments reachable in the late-data scenario.
                    first = max(0, last - 10)
            rows = [
                '#EXTM3U', '#EXT-X-VERSION:3', '#EXT-X-INDEPENDENT-SEGMENTS',
                f'#EXT-X-TARGETDURATION:{SEGMENT_SECONDS}', f'#EXT-X-MEDIA-SEQUENCE:{first}',
            ]
            for sequence in range(first, last + 1):
                rows.extend((f'#EXTINF:{SEGMENT_SECONDS}.0,', f'segment-{sequence:03d}.ts'))
            return ('\n'.join(rows) + '\n').encode(), 'application/vnd.apple.mpegurl'

        match = re.fullmatch(r'segment-(\d{3})\.ts', resource)
        if match is None or (sequence := int(match[1])) >= len(self.segments):
            return None
        with self._lock:
            now = time.monotonic()
            if self._first_read is None:
                self._first_read = now
                self._first_segment = sequence
            if self.scenario == 'expired-segments':
                if sequence == INITIAL_LAST and self._expiry_at is None:
                    # Freeze publishing for eight seconds after the last old
                    # segment request, then advance the media sequence by two.
                    self._expiry_at = now + 8
                if FIRST_AFTER_EXPIRY <= sequence and self._advanced:
                    self._resumed = True
        if self.scenario == 'late-segments' and sequence in LATE_SEGMENTS:
            time.sleep(3.4)
            with self._lock:
                self._late_segments.add(sequence)
        return self.segments[sequence].read_bytes(), 'video/mp2t'

    def evidence(self, live_start_segments):
        with self._lock:
            all_delayed = self._late_segments == set(LATE_SEGMENTS)
            return {
                'scenario': self.scenario,
                'firstSegment': self._first_segment,
                'initialWindowSegments': INITIAL_LAST + 1,
                'segmentSeconds': SEGMENT_SECONDS,
                'startObserved': self._first_segment == max(0, INITIAL_LAST + 1 - (live_start_segments or 3)),
                'faultObserved': all_delayed if self.scenario == 'late-segments' else self._advanced and self._resumed,
                'delayedSegments': sorted(self._late_segments),
                'mediaSequenceAdvanced': self._advanced,
                'postExpirySegmentRequested': self._resumed,
            }


def generate(output, ffmpeg):
    output = Path(output).resolve()
    output.mkdir(parents=True, exist_ok=True)
    folder = output / 'live-hls-segments'
    folder.mkdir(exist_ok=True)
    subprocess.run([
        ffmpeg, '-hide_banner', '-loglevel', 'error', '-y',
        '-f', 'lavfi', '-i', 'testsrc2=size=320x180:rate=25',
        '-f', 'lavfi', '-i', 'sine=frequency=880:sample_rate=48000',
        '-t', '100', '-c:v', 'libx264', '-preset', 'fast', '-tune', 'zerolatency',
        '-g', '50', '-sc_threshold', '0', '-threads', '2', '-c:a', 'mp2', '-b:a', '192k',
        '-f', 'hls', '-hls_time', str(SEGMENT_SECONDS), '-hls_list_size', '0',
        '-hls_flags', 'independent_segments', '-hls_segment_filename', 'segment-%03d.ts',
        'source.m3u8',
    ], cwd=folder, check=True)
    for sequence in range(50):
        if (folder / f'segment-{sequence:03d}.ts').stat().st_size == 0:
            raise RuntimeError(f'Empty HLS segment {sequence}')
    entries = []
    for scenario in ('late-segments', 'expired-segments'):
        for offset in (None, 5):
            continuity = {'minSyncedAudioMs': 2000, 'maxAvSyncMs': 150}
            if scenario == 'expired-segments':
                continuity.update(minClockDiscontinuities=1, maxResyncMs=8000)
            entries.append({
                'name': f'{scenario} / {offset or "native-default"}',
                'liveHlsScenario': scenario,
                'hlsLiveStartSegments': offset,
                'holdSeconds': 27,
                'expectAudio': True,
                'expectVideo': True,
                'continuity': continuity,
            })
    (output / 'manifest.json').write_text(json.dumps(entries, indent=2) + '\n', encoding='utf-8')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', required=True)
    parser.add_argument('--ffmpeg', default=shutil.which('ffmpeg'))
    args = parser.parse_args()
    if not args.ffmpeg:
        parser.error('Supply --ffmpeg=/path/to/ffmpeg')
    generate(args.output, args.ffmpeg)
