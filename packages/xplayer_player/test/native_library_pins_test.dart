import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final root = Directory('packages/native').existsSync()
      ? Directory('packages/native')
      : Directory('../native');
  final builds =
      jsonDecode(File('${root.path}/native_builds.json').readAsStringSync())
          as Map;
  for (final platform in ['ios', 'macos']) {
    test(
      '$platform shipping adapter uses the same full artifact as decoder CI',
      () {
        final expected = builds['darwin'][platform] as Map;
        final make = File(
          '${root.path}/media_kit_libs_${platform}_video/$platform/Makefile',
        ).readAsStringSync();
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
      '${root.path}/media_kit_libs_windows_video/windows/CMakeLists.txt',
    ).readAsStringSync();
    final expected = builds['windows'] as Map;
    expect(cmake, contains('set(LIBMPV_URL "${expected['url']}")'));
    expect(cmake, contains('set(LIBMPV_SHA256 "${expected['sha256']}")'));
    expect(
      cmake,
      contains('set(ANGLE_SHA256 "${expected['angle']['sha256']}")'),
    );
  });
}
