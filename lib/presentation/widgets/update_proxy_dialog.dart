import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:xplayer/services/update/update_proxy.dart';
import 'package:xplayer/shared/components/x_text_button.dart';
import 'package:xplayer/shared/theme/app_tokens.dart';

/// 在线更新代理设置对话框（`host:port`）。留空保存即清除（直连）。
class UpdateProxyDialog extends StatefulWidget {
  const UpdateProxyDialog({super.key});

  @override
  State<UpdateProxyDialog> createState() => _UpdateProxyDialogState();
}

class _UpdateProxyDialogState extends State<UpdateProxyDialog> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode(debugLabel: 'updateProxy');

  @override
  void initState() {
    super.initState();
    UpdateProxy.get().then((v) {
      if (mounted) _controller.text = v ?? '';
    });
    // TV:上/下方向键把焦点移出文本框,避免被困(同搜索框处理)
    _focus.onKeyEvent = (node, event) {
      if (event is KeyDownEvent || event is KeyRepeatEvent) {
        if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
          return node.focusInDirection(TraversalDirection.down)
              ? KeyEventResult.handled
              : KeyEventResult.ignored;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
          return node.focusInDirection(TraversalDirection.up)
              ? KeyEventResult.handled
              : KeyEventResult.ignored;
        }
      }
      return KeyEventResult.ignored;
    };
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await UpdateProxy.set(_controller.text); // 空 = 清除(直连)
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AlertDialog(
      backgroundColor: AppTokens.surfacePanel,
      title: Text(l.updateProxy,
          style: const TextStyle(color: AppTokens.textPrimary)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.updateProxyHint,
            style: const TextStyle(color: AppTokens.textTertiary, fontSize: 12),
          ),
          const SizedBox(height: AppDimens.s12),
          TextField(
            controller: _controller,
            focusNode: _focus,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.url,
            style: const TextStyle(color: AppTokens.textPrimary),
            cursorColor: AppTokens.brand,
            decoration: const InputDecoration(
              hintText: '127.0.0.1:7890',
              hintStyle: TextStyle(color: AppTokens.textTertiary),
            ),
          ),
        ],
      ),
      actions: [
        XTextButton(
          text: l.cancel,
          onPressed: () => Navigator.of(context).pop(),
        ),
        XTextButton(
          text: l.save,
          type: XTextButtonType.primary,
          onPressed: _save,
        ),
      ],
    );
  }
}
