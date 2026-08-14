/// 弹窗分三类,不是一个外壳打天下。
///
/// 原来的 [XDialogShell] 硬编码单个「确定」按钮和 360px 固定宽,撑不住实际用法:
/// 确认删除需要取消键和危险色,选择类根本不该有确定按钮 —— 点一下就是选中,
/// 再要求确认是多余一步。
///
/// | 类型 | 用在哪 | 按钮 | 关闭方式 |
/// |---|---|---|---|
/// | [XFormDialog] | 添加播放列表、更新代理 | 取消 + 动词 | 只能按钮关,防误触丢输入 |
/// | [XPickerDialog] | 画质、音轨、预置源 | 无 | 点选项 / 点遮罩 |
/// | [XConfirmDialog] | 移除源、清空收藏 | 取消 + 危险色 | 点遮罩＝取消 |
///
/// **按钮文案一律用动词**,不用「确定」——「确定」不告诉用户会发生什么。
/// 用「保存」「移除」「添加」,而且操作完成后的提示要复用同一个词
/// (按「移除」,提示说「已移除」),界面的词汇表才是一致、可学习的。
library;

import 'package:flutter/material.dart';
import 'package:xplayer/localization/app_localizations.dart';
import 'package:xplayer/shared/components/x_text_button.dart';
import 'package:xplayer/shared/theme/app_tokens.dart';

const double _kDialogWidth = 380;

/// 表单类弹窗:有输入,主操作是个动词。
///
/// 刻意**不允许点遮罩关闭**(见 [show] 的 `barrierDismissible: false`)——
/// 用户填了半天,手滑点到外面就全没了。
class XFormDialog extends StatelessWidget {
  final String title;

  /// 可选的一句话说明,置于标题下方。
  final String? description;

  final Widget child;

  /// 主操作文案。用动词,例如「保存」「添加」。
  final String actionLabel;

  /// 主操作。返回 null 表示按钮置灰(例如表单校验未通过)。
  final VoidCallback? onAction;

  /// 左下角的次要路径,例如「从预置源选择」。它是另一条路,不是次要操作,
  /// 故与右侧的取消/主操作分开摆,避免三个按钮挤成一排分不出主次。
  final Widget? leading;

  const XFormDialog({
    super.key,
    required this.title,
    required this.child,
    required this.actionLabel,
    this.onAction,
    this.description,
    this.leading,
  });

  static Future<T?> show<T>(BuildContext context, Widget dialog) {
    return showDialog<T>(
      context: context,
      barrierDismissible: false,
      builder: (_) => dialog,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AlertDialog(
      backgroundColor: AppTokens.surfaceRaised,
      title: _Title(title: title, description: description),
      content: SizedBox(width: _kDialogWidth, child: child),
      actionsPadding: const EdgeInsets.fromLTRB(
          AppDimens.s16, 0, AppDimens.s16, AppDimens.s12),
      actions: [
        Row(
          children: [
            if (leading != null) leading!,
            const Spacer(),
            XTextButton(
              text: l.cancel,
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: AppDimens.s8),
            XTextButton(
              text: actionLabel,
              type: XTextButtonType.primary,
              // 置灰而非隐藏:让用户看得见有这个操作,只是现在还不能按。
              onPressed: onAction,
            ),
          ],
        ),
      ],
    );
  }
}

/// 选择类弹窗:一列选项,点一下即选中并关闭。
///
/// **没有确定按钮。** 点选项本身就是提交 —— 再要求确认是多余一步。
/// 选项内部应当用打勾表示当前项,而不是单选圆点:勾号表示「已经是这个」,
/// 圆点暗示「待提交」。
class XPickerDialog extends StatelessWidget {
  final String title;
  final String? description;
  final Widget child;

  /// 极少数需要即时预览、用户会连点几个比较的场景(如主题色)可给一个
  /// 「完成」按钮,避免点一下就关。默认不给。
  final String? doneLabel;

  const XPickerDialog({
    super.key,
    required this.title,
    required this.child,
    this.description,
    this.doneLabel,
  });

  static Future<T?> show<T>(BuildContext context, Widget dialog) {
    return showDialog<T>(context: context, builder: (_) => dialog);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTokens.surfaceRaised,
      title: _Title(title: title, description: description),
      contentPadding: const EdgeInsets.symmetric(vertical: AppDimens.s8),
      content: SizedBox(width: _kDialogWidth, child: child),
      actions: doneLabel == null
          ? null
          : [
              XTextButton(
                text: doneLabel!,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
    );
  }
}

/// 确认类弹窗:破坏性操作的最后一道闸。
///
/// [description] 要写清**具体后果**,别写「此操作不可撤销」这种空话 ——
/// 「会少 96 个频道,其中 4 个在你的收藏里」才是用户据以判断的信息。
class XConfirmDialog extends StatelessWidget {
  final String title;
  final String description;

  /// 危险操作文案。用动词,例如「移除」「清空」。
  final String actionLabel;

  final VoidCallback onAction;

  /// 是否用危险色。移除、清空这类不可逆操作应当为 true。
  final bool destructive;

  const XConfirmDialog({
    super.key,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onAction,
    this.destructive = true,
  });

  /// 返回 true 表示用户确认执行。点遮罩、按取消都返回 null。
  static Future<bool?> show(BuildContext context, Widget dialog) {
    return showDialog<bool>(context: context, builder: (_) => dialog);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AlertDialog(
      backgroundColor: AppTokens.surfaceRaised,
      title: Text(title,
          style: TextStyle(
              color: AppTokens.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600)),
      content: SizedBox(
        width: _kDialogWidth,
        child: Text(description,
            style: TextStyle(
                color: AppTokens.textSecondary, fontSize: 14, height: 1.5)),
      ),
      actions: [
        XTextButton(
          text: l.cancel,
          onPressed: () => Navigator.of(context).pop(),
        ),
        XTextButton(
          text: actionLabel,
          type: destructive
              ? XTextButtonType.danger
              : XTextButtonType.primary,
          onPressed: () {
            Navigator.of(context).pop(true);
            onAction();
          },
        ),
      ],
    );
  }
}

class _Title extends StatelessWidget {
  final String title;
  final String? description;

  const _Title({required this.title, this.description});

  @override
  Widget build(BuildContext context) {
    if (description == null) {
      return Text(title,
          style: TextStyle(
              color: AppTokens.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w600));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title,
            style: TextStyle(
                color: AppTokens.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: AppDimens.s4),
        Text(description!,
            style: TextStyle(
                color: AppTokens.textSecondary, fontSize: 13, height: 1.45)),
      ],
    );
  }
}

/// 各设置类弹窗共享的外壳:统一背景/标题/确定按钮。
///
/// 保留以兼容既有调用点。**新代码请按用途选** [XFormDialog] /
/// [XPickerDialog] / [XConfirmDialog] —— 单个「确定」按钮撑不住三类用法。
class XDialogShell extends StatelessWidget {
  final String title;
  final Widget child;
  const XDialogShell({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AlertDialog(
      backgroundColor: AppTokens.surfaceRaised,
      title: Text(title, style: TextStyle(color: AppTokens.textPrimary)),
      content: SizedBox(width: _kDialogWidth, child: child),
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
