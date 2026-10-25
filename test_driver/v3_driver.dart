import 'dart:convert';
import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final directory = Directory('.dart_tool/v3-qa/screenshots');
  await directory.create(recursive: true);
  await integrationDriver(
    onScreenshot: (name, bytes, [args]) async {
      await File('${directory.path}/$name.png').writeAsBytes(bytes);
      return true;
    },
    responseDataCallback: (data) async {
      final device = data?['device'] ?? 'unknown';
      data = Map<String, dynamic>.from(data ?? {})..remove('screenshots');
      await File(
        '.dart_tool/v3-qa/$device.json',
      ).writeAsString(const JsonEncoder.withIndent('  ').convert(data));
    },
  );
}
