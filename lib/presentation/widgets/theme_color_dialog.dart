import 'package:flutter/material.dart';
import 'package:xplayer/localization/app_localizations.dart';
import 'package:xplayer/shared/components/x_base_button.dart';
import 'package:xplayer/shared/components/x_dialog_shell.dart';
import 'package:xplayer/shared/theme/app_palette.dart';
import 'package:xplayer/shared/theme/app_tokens.dart';
import 'package:xplayer/shared/theme/theme_settings.dart';

/// 主题色选择弹窗:4x2 色块网格,选中即时生效。
/// 用 XBaseButton 承载每个色块,以保证 TV 遥控下有可见焦点框。
class ThemeColorDialog extends StatelessWidget {
  const ThemeColorDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return XDialogShell(
      title: l.themeColor,
      child: ValueListenableBuilder<Color>(
        valueListenable: themeColor,
        builder: (context, current, __) => GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          mainAxisSpacing: AppDimens.s12,
          crossAxisSpacing: AppDimens.s12,
          padding: const EdgeInsets.symmetric(vertical: AppDimens.s8),
          children: [
            for (final c in AppPalette.all)
              _ColorCell(
                color: c,
                selected: c.toARGB32() == current.toARGB32(),
                onTap: () => setThemeColor(c),
              ),
          ],
        ),
      ),
    );
  }
}

class _ColorCell extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorCell({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return XBaseButton(
      onPressed: onTap,
      child: (focused) => Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: focused
              ? Border.all(color: AppTokens.textPrimary, width: 3)
              : null,
        ),
        child: selected
            ? const Icon(Icons.check, color: AppPalette.onPalette, size: 22)
            : null,
      ),
    );
  }
}
