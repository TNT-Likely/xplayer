import 'package:epg_xmltv/epg_xmltv.dart';
import 'package:flutter/material.dart';

import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer/shared/theme/app_tokens.dart';

/// 首页主视觉大卡：承接「上次在看」。
///
/// 设计意图是**一眼决定要不要继续**：频道名之外还要给出「现在在播什么、
/// 还剩多久」。原来的首页做不到这一点——必须点进去才知道。
///
/// 没有 EPG 时降级为只显示频道名与分组，而不是留一行空的节目位。
class HomeHero extends StatelessWidget {
  final Channel channel;

  /// 当前正在播的节目。没有 EPG 时传 null。
  final Programme? programme;

  /// 注入当前时间，便于测试剩余时长。
  final DateTime now;

  final VoidCallback? onWatch;
  final VoidCallback? onGuide;

  const HomeHero({
    super.key,
    required this.channel,
    required this.now,
    this.programme,
    this.onWatch,
    this.onGuide,
  });

  static String remainingText(Programme p, DateTime now) {
    final left = p.stop.difference(now);
    if (left.isNegative) return '';
    if (left.inMinutes < 1) return '即将结束';
    if (left.inMinutes < 60) return '还剩 ${left.inMinutes} 分钟';
    return '还剩 ${left.inHours} 小时';
  }

  static String _hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  /// 副行：节目名 · 起止 · 剩余。没有 EPG 时退回分组。
  String get _subtitle {
    final p = programme;
    if (p == null) {
      final g = channel.groups;
      return g.isEmpty ? '' : g.first;
    }
    final parts = [
      p.title,
      '${_hhmm(p.start)}–${_hhmm(p.stop)}',
      remainingText(p, now),
    ].where((s) => s.isNotEmpty);
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppDimens.s16, AppDimens.s8, AppDimens.s16, AppDimens.s8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.radiusLg),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 画面占位。真实实现里这里是最近一帧或频道艺术图；
              // 取不到时用中性渐变，而不是留一块纯色。
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0.45, -0.55),
                    radius: 1.2,
                    colors: [Color(0xFF2C4B63), Color(0xFF0D141B)],
                  ),
                ),
              ),
              // 底部压暗，保证文字在任何画面上都可读。
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Color(0xE6060A0E)],
                    stops: [0.38, 1],
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Padding(
                  padding: const EdgeInsets.all(AppDimens.s12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '上次在看',
                        style: TextStyle(
                          color: AppTokens.brand,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.4,
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        channel.name.isEmpty ? channel.id : channel.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (_subtitle.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            _subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFC8D2DC),
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(height: AppDimens.s8),
                      Row(
                        children: [
                          _Btn(
                            label: '观看',
                            icon: Icons.play_arrow_rounded,
                            primary: true,
                            onTap: onWatch,
                          ),
                          if (onGuide != null) ...[
                            const SizedBox(width: AppDimens.s8),
                            _Btn(
                              label: '节目单',
                              icon: Icons.calendar_month_outlined,
                              onTap: onGuide,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool primary;
  final VoidCallback? onTap;

  const _Btn({
    required this.label,
    required this.icon,
    this.primary = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: primary
              ? AppTokens.brand
              : Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 15, color: primary ? Colors.black : Colors.white),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: primary ? Colors.black : Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 环境光。
///
/// 取代原来那张随机模糊大图：同样的视觉分量，但它跟你正在看的东西有关。
/// 挂在主视觉后面，用主色渲染一层大范围柔光。
class AmbientGlow extends StatelessWidget {
  final double height;

  const AmbientGlow({super.key, this.height = 300});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SizedBox(
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -1),
              radius: 1.1,
              colors: [
                AppTokens.brand.withValues(alpha: 0.16),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
