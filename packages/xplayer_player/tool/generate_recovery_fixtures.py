"""Generate reproducible packet-corruption cases, separate from the codec matrix."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess


def generate(output, ffmpeg):
    output = Path(output).resolve()
    output.mkdir(parents=True, exist_ok=True)

    def encode(*args):
        subprocess.run([ffmpeg, '-hide_banner', '-loglevel', 'error', '-y', *args], check=True)

    encode('-f', 'lavfi', '-i', 'testsrc2=size=320x180:rate=25',
           '-f', 'lavfi', '-i', 'sine=frequency=880:sample_rate=48000',
           '-t', '14', '-c:v', 'libx264', '-preset', 'ultrafast', '-g', '25',
           '-c:a', 'mp2', '-b:a', '128k', str(output / 'clean.mkv'))
    cases = [
        ('clean', None, None, {}),
        ('isolated', 'if(between(n,160,161),1,0)', None, {'minAudioRecoveries': 1}),
        ('continuous', 'if(gte(n,160),1,0)', None,
         {'expectFailure': True, 'expectedErrorContains': 'Audio packet error budget exceeded'}),
        # Relax only the count limit to independently test the time deadline.
        ('audio-stops', 'if(gte(n,160),1,0)', None,
         {'audioPacketErrorLimit': 1000, 'expectFailure': True,
          'expectedErrorContains': 'Audio did not recover'}),
    ]
    manifest = []
    for name, amount, drop, expected in cases:
        target = output / (name + '.mkv')
        if amount:
            noise = "noise=amount='" + amount + "'"
            if drop:
                noise += ":drop='" + drop + "'"
            encode('-i', str(output / 'clean.mkv'), '-c', 'copy', '-bsf:a', noise, str(target))
        manifest.append({'name': name, 'file': target.name, 'holdSeconds': 10,
                         'expectAudio': True, 'expectVideo': True,
                         'sha256': hashlib.sha256(target.read_bytes()).hexdigest(), **expected})
    (output / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
    return manifest


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', required=True)
    parser.add_argument('--ffmpeg', required=True)
    args = parser.parse_args()
    print(json.dumps({'fixtures': len(generate(args.output, args.ffmpeg))}))
