import 'package:flutter/material.dart';
import 'package:xplayer/shared/components/x_base_button.dart';
import 'package:xplayer/shared/components/x_text_button.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DialogUtils {
  static Future<void> showConfirmDialog(
      BuildContext context, Function onConfirm) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromRGBO(34, 34, 34, 1),
          title: Text(
            AppLocalizations.of(context)!.confirmDelete,
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(AppLocalizations.of(context)!.areYouSureToDelete,
              style: const TextStyle(color: Colors.white)),
          actions: <Widget>[
            XTextButton(
                text: AppLocalizations.of(context)!.cancel,
                width: 120,
                onPressed: () => Navigator.of(context).pop()),
            XTextButton(
              text: AppLocalizations.of(context)!.confirm,
              width: 120,
              type: XTextButtonType.danger,
              onPressed: () async {
                await onConfirm();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  /// 显示带有自定义内容的对话框
  static Future<T?> showCustomDialog<T extends Object?>(
    BuildContext context, {
    String? title,
    Widget? content,
    String? confirmButtonText = '确定',
    VoidCallback? onConfirmPressed,
    String? cancelButtonText = '取消',
    VoidCallback? onCancelPressed,
    bool barrierDismissible = true,
  }) async {
    return await showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.transparent,
      builder: (BuildContext context) {
        return AlertDialog(
          title: title != null
              ? Text(
                  title,
                  style: const TextStyle(color: Colors.white),
                )
              : null,
          content: content,
          backgroundColor: const Color.fromRGBO(0, 0, 0, 0.85),
          actions: <Widget>[
            if (cancelButtonText != null)
              XTextButton(
                onPressed: () {
                  if (onCancelPressed != null) {
                    onCancelPressed();
                  }
                  Navigator.of(context).pop();
                },
                text: cancelButtonText,
              ),
            if (confirmButtonText != null)
              XTextButton(
                onPressed: () {
                  if (onConfirmPressed != null) {
                    onConfirmPressed();
                  }
                  Navigator.of(context).pop();
                },
                text: confirmButtonText,
              ),
          ],
        );
      },
    );
  }

  /// 展示选项的弹窗，只包含取消按钮
  static Future<Map<String, dynamic>?> showOptionsDialog<T>(
    BuildContext context, {
    required List<Map<String, dynamic>> options,
    required ValueChanged<Map<String, dynamic>> onOptionSelected,
    String? currentId,
    String? title = '请选择',
    String cancelButtonText = '取消',
  }) async {
    final theme = Theme.of(context);

    showCustomDialog<Map<String, dynamic>>(
      context,
      title: title,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: options.map((option) {
          final isSelected = option['value'] == currentId;
          return XBaseButton(
              onPressed: () {
                if (option['value'] != null && !isSelected) {
                  onOptionSelected(option);
                }

                Navigator.of(context).pop();
              },
              child: (isFocused) => ListTile(
                    tileColor: isFocused || isSelected
                        ? theme.primaryColor
                        : Colors.transparent,
                    title: Text(
                      option['label'] ??
                          AppLocalizations.of(context)!.unknownOption,
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                          )
                        : null,
                  ));
        }).toList(),
      ),
      cancelButtonText: null,
      confirmButtonText: null,
      onCancelPressed: () {
        // 取消按钮点击事件处理
      },
    );
    return null;
  }

  /// 展示带有自定义子部件和操作的弹窗
  static Future<void> showActionsDialog(
    BuildContext context, {
    required List<Widget> children,
    String? title = '请选择',
    String cancelButtonText = '取消',
  }) async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          title: title != null ? Text(title) : null,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [...children],
          ),
          actions: const [],
        );
      },
    );
  }
}
