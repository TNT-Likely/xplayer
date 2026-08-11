import 'package:flutter/material.dart';
import 'package:xplayer/localization/app_localizations.dart';
import 'package:xplayer/shared/components/x_text_button.dart';
import 'package:xplayer/shared/theme/app_tokens.dart';

/// 各设置类弹窗共享的外壳:统一背景/标题/确定按钮。
class XDialogShell extends StatelessWidget {
  final String title;
  final Widget child;
  const XDialogShell({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AlertDialog(
      backgroundColor: AppTokens.surfacePanel,
      title: Text(title, style: const TextStyle(color: AppTokens.textPrimary)),
      content: SizedBox(width: 360, child: child),
      actions: [
        XTextButton(
          text: l.ok,
          type: XTextButtonType.primary,
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
