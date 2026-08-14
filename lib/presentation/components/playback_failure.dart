import 'package:flutter/material.dart';

import 'package:xplayer/shared/theme/app_tokens.dart';

/// 重连中。
///
/// **把「第几次尝试」摆出来** —— 用户据此判断该等还是该走。
/// 一个转圈图标什么都不说，等三十秒和等三秒看起来一模一样。
///
/// 两个出口都给：源失效是 IPTV 的常态，不该只能干等。
class ReconnectingView extends StatelessWidget {
  final String channelName;
  final int attempt;
  final int maxAttempts;

  /// 同一频道有多条备用地址时给这个出口。
  final VoidCallback? onTryAnotherSource;
  final VoidCallback? onBack;

  const ReconnectingView({
    super.key,
    required this.channelName,
    required this.attempt,
    required this.maxAttempts,
    this.onTryAnotherSource,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return _Centered(
      children: [
        const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation(AppTokens.textSecondary),
          ),
        ),
        const SizedBox(height: AppDimens.s12),
        Text(
          '正在重连 $channelName',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppTokens.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '第 $attempt 次尝试 · 共 $maxAttempts 次',
          style: const TextStyle(
            color: AppTokens.textSecondary,
            fontSize: 11,
            fontFamily: 'monospace',
          ),
        ),
        const SizedBox(height: AppDimens.s16),
        _Actions(actions: [
          if (onTryAnotherSource != null)
            _Action('换个源', onTryAnotherSource!),
          if (onBack != null) _Action('返回列表', onBack!),
        ]),
      ],
    );
  }
}

/// 最终失败。
///
/// 写清**发生了什么、可能是什么原因、能做什么** —— 不道歉、不含糊。
/// 「播放失败，请重试」这种文案等于没说。
class PlaybackFailedView extends StatelessWidget {
  final int attempts;

  /// 具体原因。为 null 时用通用说法，但仍然点明「可能已失效或需要代理」。
  final String? reason;

  final VoidCallback? onRetry;

  /// 把这条源喂回健康度系统，下次它在卡片上就带红点了。
  final VoidCallback? onMarkDead;

  final VoidCallback? onDiagnostics;

  const PlaybackFailedView({
    super.key,
    required this.attempts,
    this.reason,
    this.onRetry,
    this.onMarkDead,
    this.onDiagnostics,
  });

  @override
  Widget build(BuildContext context) {
    return _Centered(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppTokens.sourceDead.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: AppTokens.sourceDead.withValues(alpha: 0.36)),
          ),
          child: const Icon(Icons.error_outline,
              color: Color(0xFFFF8C85), size: 22),
        ),
        const SizedBox(height: AppDimens.s12),
        const Text(
          '这条源连不上',
          style: TextStyle(
            color: AppTokens.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Text(
            reason ?? '重试 $attempts 次均超时。源地址可能已失效，或需要代理才能访问。',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTokens.textSecondary,
              fontSize: 11.5,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: AppDimens.s16),
        _Actions(actions: [
          if (onRetry != null) _Action('再试一次', onRetry!, primary: true),
          if (onMarkDead != null) _Action('标记为失效', onMarkDead!),
          if (onDiagnostics != null) _Action('查看诊断', onDiagnostics!),
        ]),
      ],
    );
  }
}

class _Centered extends StatelessWidget {
  final List<Widget> children;
  const _Centered({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withValues(alpha: 0.72),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.s24, vertical: AppDimens.s16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        ),
      ),
    );
  }
}

class _Action {
  final String label;
  final VoidCallback onTap;
  final bool primary;
  const _Action(this.label, this.onTap, {this.primary = false});
}

class _Actions extends StatelessWidget {
  final List<_Action> actions;
  const _Actions({required this.actions});

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: AppDimens.s8,
      runSpacing: AppDimens.s8,
      alignment: WrapAlignment.center,
      children: [
        for (final a in actions)
          GestureDetector(
            onTap: a.onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: a.primary
                    ? AppTokens.brand
                    : Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                a.label,
                style: TextStyle(
                  color: a.primary ? Colors.black : AppTokens.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
