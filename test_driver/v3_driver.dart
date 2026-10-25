import 'dart:convert';
import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';
import 'package:flutter_driver/flutter_driver.dart';

Future<void> main() async {
  final directory = Directory('.dart_tool/v3-qa/screenshots');
  await directory.create(recursive: true);
  await integrationDriver(
    // 截图已经单独保存，避免通信日志再次记录整份 base64 像素数据。
    driver: await FlutterDriver.connect(logCommunicationToFile: false),
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
