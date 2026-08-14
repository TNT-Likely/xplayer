import 'package:flutter/material.dart';

import 'package:xplayer/shared/theme/app_tokens.dart';

/// 相对直播边缘的位置。
///
/// ⚠️ 这里**不是**「是不是直播」——IPTV 里几乎所有频道都在直播，
/// 那是个恒为真的状态，标出来等于什么都没说。
///
/// 真正会变化、也真正需要用户操作的是：**暂停之后落后了多少**。
class LiveEdge {
  /// 落后直播边缘多久。零表示贴着边缘。
  final Duration behind;

  const LiveEdge(this.behind);

  const LiveEdge.atEdge() : behind = Duration.zero;

  /// 小于这个偏移量就当作「贴边」——直播流本身有几秒缓冲，
  /// 抖动几百毫秒就显示「落后 0:01」会让人以为出问题了。
  static const Duration tolerance = Duration(seconds: 5);

  bool get isAtEdge => behind <= tolerance;
}

/// 直播边缘指示。
///
/// 两种态：贴边时安静地待着（常态，不需要操作）；落后时转琥珀色并给出
/// 「回到直播」——**只有需要操作的那一种才给按钮**。
class LiveEdgeBadge extends StatelessWidget {
  final LiveEdge edge;

  /// 回到直播边缘。落后时才会被调用。
  final VoidCallback? onSeekToLive;

  const LiveEdgeBadge({
    super.key,
    required this.edge,
    this.onSeekToLive,
  });

  static String formatBehind(Duration d) {
    final s = d.inSeconds;
    final m = s ~/ 60;
    final rem = s % 60;
    return '$m:${rem.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (edge.isAtEdge) {
      return _pill(
        bg: AppTokens.brand,
        fg: Colors.black,
        text: '直播',
        withDot: true,
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _pill(
          bg: AppTokens.sourceSlow,
          fg: const Color(0xFF3A2606),
          text: '落后 ${formatBehind(edge.behind)}',
          withDot: true,
        ),
        if (onSeekToLive != null) ...[
          const SizedBox(width: AppDimens.s8),
          GestureDetector(
            onTap: onSeekToLive,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '回到直播',
                style: TextStyle(
                    color: AppTokens.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _pill({
    required Color bg,
    required Color fg,
    required String text,
    required bool withDot,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (withDot) ...[
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            text,
            style: TextStyle(
              color: fg,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
