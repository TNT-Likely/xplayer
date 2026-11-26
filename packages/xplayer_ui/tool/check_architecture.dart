import 'dart:convert';
import 'dart:io';

void main() {
  final root = Directory.current;
  if (!File('${root.path}/pubspec.yaml')
      .readAsStringSync()
      .startsWith('name: xplayer_ui\n')) {
    stderr.writeln('请在 packages/xplayer_ui 目录运行。');
    exitCode = 1;
    return;
  }
  final errors = <String>[];
  for (final file in Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))) {
    final imports = RegExp(r'''(?:import|export)\s+['"]([^'"]+)['"]''')
        .allMatches(file.readAsStringSync())
        .map((m) => m[1]!);
    for (final uri in imports) {
      if (uri.startsWith('package:xplayer/') ||
          uri.startsWith('package:xplayer_player/') ||
          uri.startsWith('dart:io') ||
          uri.contains('shared_preferences') ||
          uri.contains('provider/') ||
          uri.contains('sqflite')) {
        errors.add('${file.path} 耦合了应用或服务：$uri');
      }
      if (file.path.contains('src/foundation/') &&
          (uri.contains('components/') ||
              uri.endsWith('media.dart') ||
              uri.endsWith('xplayer_ui.dart'))) {
        errors.add('${file.path} 反向依赖业务层：$uri');
      }
    }
  }
  final source = File('../../design/xplayer-v1/tokens/xplayer.tokens.json');
  if (source.existsSync()) {
    final json = jsonDecode(source.readAsStringSync()) as Map<String, dynamic>;
    final colors =
        (json['themes']['nocturne']['values'] as Map<String, dynamic>);
    final code =
        File('lib/src/foundation/theme.dart').readAsStringSync().toLowerCase();
    for (final key in [
      'bg',
      'surface',
      'raised',
      'border',
      'fg',
      'muted',
      'quiet',
      'accent',
      'accent-ink',
      'accent-wash'
    ]) {
      final css = (colors[key] as String).substring(1).toLowerCase();
      final argb = css.length == 8
          ? '${css.substring(6)}${css.substring(0, 6)}'
          : 'ff$css';
      if (!code.contains('0x$argb')) errors.add('A 设计变量 $key 未保持确认值。');
    }
  }
  if (errors.isNotEmpty) {
    for (final error in errors) {
      stderr.writeln(error);
    }
    exitCode = 1;
  } else {
    stdout.writeln('通过：基础层单向依赖、UI 包独立、A 设计语义色一致。');
  }
}
