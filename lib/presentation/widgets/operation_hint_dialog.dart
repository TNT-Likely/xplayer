import 'package:flutter/material.dart';
import 'package:xplayer/localization/app_localizations.dart';
import 'package:xplayer/shared/components/x_text_button.dart';
import 'package:xplayer/shared/theme/app_tokens.dart';

/// 播放页操作引导:首次进入弹一次,之后可从控制条「帮助」再次打开。
/// 每行文案同时覆盖遥控按键与触屏手势,一套适配 TV 与手机。
class OperationHintDialog extends StatelessWidget {
  const OperationHintDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const OperationHintDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AlertDialog(
      backgroundColor: AppTokens.surfacePanel,
      title: Text(l.operationHints,
          style: const TextStyle(color: AppTokens.textPrimary)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _row(Icons.swap_vert, l.hintSwitchChannel),
          _row(Icons.format_list_bulleted, l.hintChannelList),
          _row(Icons.swap_horiz, l.hintSwitchSource),
          _row(Icons.menu, l.hintMenu),
        ],
      ),
      actions: [
        XTextButton(
          text: l.hintGotIt,
          type: XTextButtonType.primary,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _row(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTokens.brand, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppTokens.textSecondary, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
