import 'package:flutter/material.dart';
import 'package:xplayer/shared/logger.dart';

class DebugLogsScreen extends StatelessWidget {
  const DebugLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final logs = AppLogger.logs.toList().reversed.toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Logs'),
        actions: [
          IconButton(
            onPressed: () {
              AppLogger.clear();
              (context as Element).markNeedsBuild();
            },
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Container(
        padding: const EdgeInsets.all(12),
        color: Colors.black,
        child: SelectableText(
          logs.join('\n'),
          style: const TextStyle(
              color: Colors.white70, fontFamily: 'monospace', fontSize: 12),
        ),
      ),
    );
  }
}
