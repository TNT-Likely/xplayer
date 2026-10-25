import 'dart:async';

import 'package:flutter/material.dart';
import 'package:xplayer_player/xplayer_player.dart';

void main() => runApp(const PlayerExample());

class PlayerExample extends StatelessWidget {
  const PlayerExample({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'XPlayer 独立接入示例',
    theme: ThemeData(colorSchemeSeed: const Color(0xff187259)),
    home: const PlayerExamplePage(),
  );
}

class PlayerExamplePage extends StatefulWidget {
  const PlayerExamplePage({super.key});

  @override
  State<PlayerExamplePage> createState() => _PlayerExamplePageState();
}

class _PlayerExamplePageState extends State<PlayerExamplePage> {
  final _source = TextEditingController(
    text: const String.fromEnvironment('EXAMPLE_SOURCE'),
  );
  MediaKitBackend? _backend;
  bool _loading = false;
  bool _software = false;
  String? _error;

  Future<void> _open() async {
    final input = _source.text.trim();
    final uri = Uri.tryParse(input.split('|').first);
    if (uri == null || !uri.hasScheme) {
      setState(() => _error = '请输入完整播放地址，例如 https://example.test/live.m3u8');
      return;
    }
    final previous = _backend;
    setState(() {
      _backend = null;
      _loading = true;
      _error = null;
    });
    await WidgetsBinding.instance.endOfFrame;
    await previous?.dispose();
    if (!mounted) return;
    final backend = MediaKitBackend(softwareDecoding: _software);
    setState(() => _backend = backend);
    try {
      // Native output creation requires a mounted view and a scheduled frame.
      await WidgetsBinding.instance.endOfFrame;
      await backend.initialize(input);
      if (mounted && identical(_backend, backend)) await backend.play();
    } catch (error) {
      if (mounted && identical(_backend, backend)) {
        setState(() => _error = redactPlaybackLog('$error'));
      }
    } finally {
      if (mounted && identical(_backend, backend)) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _source.dispose();
    unawaited(_backend?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backend = _backend;
    return Scaffold(
      appBar: AppBar(title: const Text('XPlayer 独立接入示例')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _source,
                    decoration: const InputDecoration(
                      labelText: '播放地址',
                      hintText: 'HLS / FLV / TS / MP4 / MKV / 音频地址',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: _loading ? null : (_) => unawaited(_open()),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      FilledButton(
                        onPressed: _loading ? null : _open,
                        child: Text(_loading ? '准备中…' : '加载 / 重试'),
                      ),
                      if (backend != null)
                        ValueListenableBuilder<XPlayerValue>(
                          valueListenable: backend.notifier,
                          builder: (_, value, _) => TextButton(
                            onPressed: value.isInitialized
                                ? () => value.isPlaying
                                      ? backend.pause()
                                      : backend.play()
                                : null,
                            child: Text(value.isPlaying ? '暂停' : '播放'),
                          ),
                        ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Checkbox(
                            value: _software,
                            onChanged: _loading
                                ? null
                                : (value) => setState(
                                    () => _software = value ?? false,
                                  ),
                          ),
                          const Text('下次加载使用软解'),
                        ],
                      ),
                    ],
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ColoredBox(
                color: Colors.black,
                child: SizedBox.expand(
                  child:
                      backend?.buildView() ??
                      const Center(
                        child: Text(
                          '输入地址后加载播放',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
