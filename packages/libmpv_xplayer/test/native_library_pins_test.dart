import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  var directory = Directory.current;
  while (!File(
    '${directory.path}/.dart_tool/package_config.json',
  ).existsSync()) {
    final parent = directory.parent;
    if (parent.path == directory.path) {
      throw StateError('Run flutter pub get before testing the native package');
    }
    directory = parent;
  }
  final config = File('${directory.path}/.dart_tool/package_config.json');
  final packages =
      (jsonDecode(config.readAsStringSync()) as Map)['packages'] as List;
  final entry = packages.cast<Map>().firstWhere(
    (p) => p['name'] == 'libmpv_xplayer',
  );
  final root = Directory.fromUri(
    config.absolute.uri.resolve(entry['rootUri'] as String),
  );
  final builds =
      jsonDecode(File('${root.path}/native_builds.json').readAsStringSync())
          as Map;
  for (final platform in ['ios', 'macos']) {
    test(
      '$platform registers its own video bridge without legacy package names',
      () {
        final registration = File(
          '${root.path}/$platform/Classes/LibmpvXplayerPlugin.swift',
        ).readAsStringSync();
        expect(registration, contains('LibmpvXplayerVideoPlugin.register'));
        final podspec = File(
          '${root.path}/$platform/libmpv_xplayer.podspec',
        ).readAsStringSync();
        expect(podspec, contains("'Classes/**/*.swift', 'Headers/**/*.h'"));
        expect(podspec, isNot(contains('MediaKitUtils')));
      },
    );
    test(
      '$platform shipping adapter uses the same full artifact as decoder CI',
      () {
        final expected = builds['darwin'][platform] as Map;
        final make = File('${root.path}/$platform/Makefile').readAsStringSync();
        expect(
          make,
          contains('MPV_XCFRAMEWORKS_VERSION=${expected['version']}'),
        );
        expect(
          make,
          contains('MPV_XCFRAMEWORKS_SHA256SUM=${expected['sha256']}'),
        );
        expect(make, contains('video-full.tar.gz'));
        expect(make, isNot(contains('video-default')));
      },
    );
  }
  test('Windows shipping DLL/ANGLE pins agree with decoder CI', () {
    final cmake = File(
      '${root.path}/windows/CMakeLists.txt',
    ).readAsStringSync();
    final expected = builds['windows'] as Map;
    expect(cmake, contains('set(LIBMPV_URL "${expected['url']}")'));
    expect(cmake, contains('set(LIBMPV_SHA256 "${expected['sha256']}")'));
    expect(
      cmake,
      contains('set(ANGLE_SHA256 "${expected['angle']['sha256']}")'),
    );
  });

  test('native package configures before the Windows video plugin', () {
    final spec = File('${root.path}/pubspec.yaml').readAsStringSync();
    final name = RegExp(r'^name: (\S+)', multiLine: true).firstMatch(spec)![1]!;
    final cmake = File(
      '${root.path}/windows/CMakeLists.txt',
    ).readAsStringSync();
    expect(name.compareTo('media_kit_video'), lessThan(0));
    expect(cmake, contains('set(PROJECT_NAME "$name")'));
    expect(cmake, contains('${name}_bundled_libraries'));
    expect(cmake, contains('if(TARGET media_kit_video_plugin)'));
  });

  test(
    'Android reads the packaged manifest and retains the helper JNI ABI',
    () {
      final gradle = File(
        '${root.path}/android/build.gradle',
      ).readAsStringSync();
      expect(gradle, contains('file("../native_builds.json")'));
      expect(gradle, contains('sha256(temporary) != artifact.sha256'));
      final helper = File(
        '${root.path}/android/src/main/java/com/alexmercerind/'
        'mediakitandroidhelper/MediaKitAndroidHelper.java',
      ).readAsStringSync();
      expect(
        helper,
        contains('package com.alexmercerind.mediakitandroidhelper;'),
      );
      expect(helper, contains('System.loadLibrary("mediakitandroidhelper")'));
    },
  );
}
