import 'package:flutter/material.dart';

import 'package:xplayer/shared/theme/app_tokens.dart';

/// 正在播的节目。
class NowPlaying {
  final String title;
  final DateTime start;
  final DateTime end;

  const NowPlaying({
    required this.title,
    required this.start,
    required this.end,
  });

  /// 已播进度 0..1。时长非法时返回 0，不产出 NaN 把布局搞崩。
  double progressAt(DateTime now) {
    final total = end.difference(start).inSeconds;
    if (total <= 0) return 0;
    final done = now.difference(start).inSeconds;
    return (done / total).clamp(0.0, 1.0);
  }

  Duration remainingAt(DateTime now) {
    final left = end.difference(now);
    return left.isNegative ? Duration.zero : left;
  }
}

/// 当前节目 + 进度条。
///
/// **直播不能拖拽，但「这档节目播到哪了」是能算的** —— EPG 有起止时间。
/// 所以这条进度条**不可交互**，纯粹告诉你还剩多久。
///
/// 没有 EPG 的频道传 null：整块隐藏，而不是显示一条空进度条或
/// 「未知节目」——那是 IPTV 里的多数情况，不该让多数情况看起来像出错。
class ProgrammeProgress extends StatelessWidget {
  final NowPlaying? programme;

  /// 注入当前时间，便于测试。
  final DateTime now;

  const ProgrammeProgress({
    super.key,
    required this.programme,
    required this.now,
  });

  static String _hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  static String formatRemaining(Duration d) {
    if (d.inMinutes < 1) return '即将结束';
    if (d.inMinutes < 60) return '还剩 ${d.inMinutes} 分钟';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return m == 0 ? '还剩 $h 小时' : '还剩 $h 小时 $m 分';
  }

  @override
  Widget build(BuildContext context) {
    final p = programme;
    if (p == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Flexible(
              child: Text(
                p.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTokens.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: AppDimens.s8),
            Text(
              '${_hhmm(p.start)} – ${_hhmm(p.end)}',
              style: const TextStyle(
                color: AppTokens.textSecondary,
                fontSize: 10.5,
                fontFamily: 'monospace',
              ),
            ),
            const Spacer(),
            Text(
              formatRemaining(p.remainingAt(now)),
              style: const TextStyle(
                color: AppTokens.textSecondary,
                fontSize: 10.5,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        // 不可交互:直播拖不了,这条只是告知。做成可拖会让用户以为能回看。
        IgnorePointer(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: p.progressAt(now),
              minHeight: 2.5,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: AlwaysStoppedAnimation(AppTokens.brand),
            ),
          ),
        ),
      ],
    );
  }
}
