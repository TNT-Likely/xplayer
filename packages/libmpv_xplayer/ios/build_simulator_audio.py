#!/usr/bin/env python3
"""Rebuild only simulator libmpv: upstream v0.6.0 omits its AudioUnit sink.

The pinned full FFmpeg/frameworks and the device slice stay unchanged. Build
products, sources and the isolated Meson/Ninja environment live in .cache/.
"""
import os
from pathlib import Path
import shutil
import subprocess
import sys
import venv

ROOT = Path(__file__).resolve().parent
sys.path.insert(0, str(ROOT.parent / 'tool'))
from download_artifact import download_artifact

CACHE = ROOT / '.cache' / 'simulator-audio'
FRAMEWORKS = ROOT / 'Frameworks'
INPUTS = {
    'mpv.tar.gz': (
        'https://github.com/mpv-player/mpv/archive/refs/tags/v0.36.0.tar.gz',
        '29abc44f8ebee013bb2f9fe14d80b30db19b534c679056e4851ceadf5a5e8bf6'),
    'ffmpeg.tar.xz': (
        'https://ffmpeg.org/releases/ffmpeg-6.0.tar.xz',
        '57be87c22d9b49c112b6d24bc67d42508660e6b718b3db89c44e47e289137082'),
    'ass.h': (
        'https://raw.githubusercontent.com/libass/libass/0.17.1/libass/ass.h',
        'd2261a035c0e7bb1cb149f817174c0e6fa6e27c76840e8c8e19f0ec262090be6'),
    'ass_types.h': (
        'https://raw.githubusercontent.com/libass/libass/0.17.1/libass/ass_types.h',
        '3e5375855868ea46a4ff567d02430839f998391b6c02268de07f23387b630062'),
    'uchardet.h': (
        'https://raw.githubusercontent.com/BYVoid/uchardet/4e685757780cb3c652fc6c9ec759f62888969ec9/src/uchardet.h',
        '9b2ae3c06dd5e638fe15ca8a39c8378d9e801cafe2ae15166f2784b4139beede'),
    'audio-session.patch': (
        'https://raw.githubusercontent.com/media-kit/libmpv-darwin-build/v0.7.3/patches/mpv-audiounit-shared-session.patch',
        'ff4774adeeff4ac8525b09cfc3fa1a3b1c214654676e22fdec3aa639aec9fdea'),
    'missing-objc.patch': (
        'https://raw.githubusercontent.com/media-kit/libmpv-darwin-build/v0.7.3/patches/mpv-fix-missing-objc.patch',
        '9affd0b9bf9a36ac57ba1ce211e2292ad7cda2050abb560909bafc585c908851'),
}


def run(*args, **kwargs):
    return subprocess.run(args, check=True, **kwargs)


def meson_command(environment, *args):
    # Console scripts retain an absolute shebang when a checkout is moved.
    # The interpreter resolves the current venv and works with relocated caches.
    return [str(environment / 'bin/python'), '-m', 'mesonbuild.mesonmain', *args]


def main():
    CACHE.mkdir(parents=True, exist_ok=True)
    pkg_config = shutil.which('pkg-config')
    if not pkg_config:
        raise SystemExit('Simulator audio build requires pkg-config on PATH')
    for name, (url, digest) in INPUTS.items():
        download_artifact(url, digest, CACHE / name)
    source = CACHE / 'mpv-0.36.0'
    if source.exists():
        shutil.rmtree(source)
    run('tar', '-xzf', str(CACHE / 'mpv.tar.gz'), '-C', str(CACHE))
    run('tar', '-xJf', str(CACHE / 'ffmpeg.tar.xz'), '-C', str(CACHE))
    for name in ['missing-objc.patch', 'audio-session.patch']:
        run('patch', '-p1', '-i', str(CACHE / name), cwd=source)

    ffmpeg = CACHE / 'ffmpeg-6.0'
    # These public-header constants apply to both supported 64-bit little
    # endian simulator targets. This does not rebuild or configure FFmpeg.
    (ffmpeg / 'libavutil/avconfig.h').write_text(
        '#define AV_HAVE_BIGENDIAN 0\n#define AV_HAVE_FAST_UNALIGNED 1\n')
    (ffmpeg / 'libavutil/ffversion.h').write_text('#define FFMPEG_VERSION "6.0"\n')
    includes = CACHE / 'include' / 'ass'
    includes.mkdir(parents=True, exist_ok=True)
    for name in ['ass.h', 'ass_types.h']:
        shutil.copy2(CACHE / name, includes / name)
    uchardet_includes = CACHE / 'include' / 'uchardet'
    uchardet_includes.mkdir(exist_ok=True)
    shutil.copy2(CACHE / 'uchardet.h', uchardet_includes / 'uchardet.h')
    pkgconfig = CACHE / 'pkgconfig'
    pkgconfig.mkdir(exist_ok=True)
    for name, framework, version in [
        ('libavcodec', 'Avcodec', '60.3.100'),
        ('libavfilter', 'Avfilter', '9.3.100'),
        ('libavformat', 'Avformat', '60.3.100'),
        ('libavutil', 'Avutil', '58.2.100'),
        ('libswresample', 'Swresample', '4.10.100'),
        ('libswscale', 'Swscale', '7.1.100'),
        ('libass', 'Ass', '0.17.1'),
        ('uchardet', 'Uchardet', '0.0.8'),
    ]:
        parent = FRAMEWORKS / f'{framework}.xcframework/ios-arm64_x86_64-simulator'
        (pkgconfig / f'{name}.pc').write_text(
            f'Name: {name}\nDescription: pinned simulator dependency\n'
            f'Version: {version}\nLibs: -F"{parent}" -framework {framework}\n'
            f'Cflags: -I"{ffmpeg}" -I"{CACHE}/include" -I"{uchardet_includes}"\n')

    environment = CACHE / 'venv'
    if not (environment / 'bin/meson').exists():
        venv.create(environment, with_pip=True)
        run(str(environment / 'bin/python'), '-m', 'pip', 'install', 'meson==1.12.1', 'ninja==1.13.2')
    env = dict(os.environ, PKG_CONFIG_LIBDIR=str(pkgconfig),
               PATH=f'{environment}/bin:' + os.environ.get('PATH', ''))
    env.pop('PKG_CONFIG_PATH', None)
    sdk = subprocess.check_output(
        ['xcrun', '--sdk', 'iphonesimulator', '--show-sdk-path'], text=True).strip()
    outputs = []
    for arch, family in [('arm64', 'aarch64'), ('x86_64', 'x86_64')]:
        flags = ['-target', f'{arch}-apple-ios13.0-simulator', '-isysroot', sdk]
        cross = CACHE / f'{arch}.ini'
        cross.write_text(
            "[binaries]\nc = '/usr/bin/clang'\nobjc = '/usr/bin/clang'\n"
            "ar = '/usr/bin/ar'\nstrip = '/usr/bin/strip'\n"
            f"pkg-config = {pkg_config!r}\n[host_machine]\nsystem = 'darwin'\n"
            f"cpu_family = {family!r}\ncpu = {arch!r}\nendian = 'little'\n"
            "[properties]\nneeds_exe_wrapper = true\n[built-in options]\n"
            + ''.join(f'{key} = {flags!r}\n' for key in ['c_args', 'objc_args'])
            + ''.join(f'{key} = {flags + ["-framework", "AVFoundation"]!r}\n'
                      for key in ['c_link_args', 'objc_link_args']))
        build = CACHE / f'build-{arch}'
        if build.exists():
            shutil.rmtree(build)
        run(*meson_command(environment, 'setup', str(build), str(source),
            '--cross-file', str(cross), '--auto-features=disabled',
            '-Dgpl=false', '-Dlibmpv=true', '-Dcplayer=false',
            '-Daudiounit=enabled', '-Dgl=enabled', '-Dplain-gl=enabled',
            '-Diconv=enabled', '-Dzlib=enabled', '-Duchardet=enabled'), env=env)
        run(*meson_command(environment, 'compile', '-C', str(build), '-j', '6'), env=env)
        outputs.append(str(build / 'libmpv.2.dylib'))
    target = FRAMEWORKS / 'Mpv.xcframework/ios-arm64_x86_64-simulator/Mpv.framework/Mpv'
    staged = CACHE / 'Mpv'
    run('lipo', '-create', *outputs, '-output', str(staged))
    run('install_name_tool', '-id', '@rpath/Mpv.framework/Mpv', str(staged))
    run('codesign', '--force', '--sign', '-', str(staged))
    # Only replace the framework after both architectures linked successfully.
    shutil.copy2(staged, target)
    print('Simulator AudioUnit output enabled: arm64 + x86_64')


if __name__ == '__main__':
    main()
