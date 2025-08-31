import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:xplayer/presentation/widgets/bg_wrapper.dart';
import 'package:xplayer/shared/components/x_text_button.dart';

import '../../providers/remote_provider.dart';
// ...

class RemoteInputScreen extends StatefulWidget {
  const RemoteInputScreen({super.key});

  @override
  State<RemoteInputScreen> createState() => _RemoteInputScreenState();
}

class _RemoteInputScreenState extends State<RemoteInputScreen> {
  final TextEditingController _controller = TextEditingController();
  VoidCallback? _controllerListener;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<RemoteProvider>().startDiscovery());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    if (_controllerListener != null) {
      _controller.removeListener(_controllerListener!);
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return BgWrapper(
      child: Scaffold(
        backgroundColor: const Color.fromRGBO(0, 0, 0, 0.5),
        appBar: AppBar(
          title: Text(l10n.remoteInput,
              style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 12,
                right: 12,
                top: 12,
                bottom: 12 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 设备选择 + 刷新
                  Consumer<RemoteProvider>(
                    builder: (context, rp, _) {
                      return Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField(
                              value: rp.current,
                              items: rp.devices
                                  .map((d) => DropdownMenuItem(
                                        value: d,
                                        child: Text(
                                          '${d.name} (${d.host})',
                                          style: const TextStyle(
                                              color: Colors.white),
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (v) async {
                                if (v != null) await rp.connect(v);
                              },
                              dropdownColor:
                                  const Color.fromRGBO(34, 34, 34, 1),
                              decoration: InputDecoration(
                                labelText: l10n.selectTv,
                                labelStyle:
                                    const TextStyle(color: Colors.white),
                                enabledBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white54),
                                ),
                                focusedBorder: const OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => rp.startDiscovery(),
                            icon:
                                const Icon(Icons.refresh, color: Colors.white),
                          )
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // 文本输入
                  TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      labelText: l10n.inputPlaceholder,
                      border: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white54),
                      ),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white54),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                      labelStyle: const TextStyle(color: Colors.white),
                    ),
                    style: const TextStyle(color: Colors.white),
                    minLines: 1,
                    maxLines: 4,
                  ),

                  const SizedBox(height: 12),

                  // 发送按钮 + 连接状态（首次发送后开启“实时同步”）
                  Consumer<RemoteProvider>(
                    builder: (context, rp, _) {
                      return Row(
                        children: [
                          XTextButton(
                            type: XTextButtonType.primary,
                            onPressed: rp.isConnected
                                ? () async {
                                    final text = _controller.text.trim();
                                    if (text.isEmpty) return;
                                    final ok = await rp.sendText(text);
                                    if (ok && _controllerListener == null) {
                                      _controllerListener = () {
                                        _debounce?.cancel();
                                        _debounce = Timer(
                                            const Duration(milliseconds: 120),
                                            () {
                                          if (mounted &&
                                              context
                                                  .read<RemoteProvider>()
                                                  .isConnected) {
                                            context
                                                .read<RemoteProvider>()
                                                .sendText(_controller.text);
                                          }
                                        });
                                      };
                                      _controller
                                          .addListener(_controllerListener!);
                                    }
                                  }
                                : null,
                            text: l10n.send,
                          ),
                          const SizedBox(width: 12),
                          if (rp.isConnected)
                            Text(
                              l10n.connectedTo(
                                  rp.current!.name, rp.current!.host),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white),
                            ),
                        ],
                      );
                    },
                  ),

                  // 移除：手动连接与方向键区域
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
