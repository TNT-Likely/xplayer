import 'package:flutter/material.dart';
import 'package:xplayer/shared/theme/app_tokens.dart';

/// 空状态。
///
/// 商店包不内置任何源，所以新用户第一眼看到的**就是空状态** ——
/// 它不是边缘情况，是每个人的第一印象，值得当主界面设计。
///
/// 三条写作原则：
/// - 标题是一句祈使，直接说下一步做什么，不写「暂无数据」
/// - 说明交代**为什么是空的**，免得用户以为加载失败
/// - 动作按真实使用频率排序，主操作只有一个
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  /// 动作按钮，第一个为主操作。
  final List<Widget> actions;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.s32, vertical: AppDimens.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                color: AppTokens.surfaceDefault,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTokens.line),
              ),
              child: Icon(icon, size: 32, color: AppTokens.brand),
            ),
            const SizedBox(height: AppDimens.s16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTokens.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppDimens.s8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTokens.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
            if (actions.isNotEmpty) ...[
              const SizedBox(height: AppDimens.s24),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 240),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < actions.length; i++) ...[
                      if (i > 0) const SizedBox(height: AppDimens.s8),
                      actions[i],
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
