import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:xplayer/data/models/channel_model.dart';
import 'package:xplayer/data/models/channel_test_result.dart';
import 'package:xplayer/shared/theme/app_tokens.dart';

/// 源的可达性。
///
/// ⚠️ 注意这里**没有**「正在直播」这一档 —— IPTV 里几乎所有频道都在直播,
/// 一个恒为真的状态出现在每张卡片上等于什么都没区分,不值得占用像素。
/// 真正会变化、也真正会坑到用户的是「这条源还活着吗」。
///
/// 约定:**只标注例外**。[ok] 与 [unknown] 一律不着一墨,没有「绿点＝正常」。
enum SourceHealth {
  /// 尚未探测过。与 [ok] 一样不显示任何标记。
  unknown,

  /// 探测通过。
  ok,

  /// 可用但响应慢。
  slow,

  /// 上次拉流失败或超时。
  dead;

  /// 从既有的延时测试结果推导健康度。
  ///
  /// 复用 [ChannelTestResult] 而不是新造一套探测 —— 这套机制本来就在跑，
  /// 它测的正是「这条源现在还连得上吗」。
  static SourceHealth fromTestResult(ChannelTestResult? r) {
    if (r == null) return SourceHealth.unknown;
    switch (r.status) {
      case TestStatus.success:
        return r.latencyLevel == LatencyLevel.poor
            ? SourceHealth.slow
            : SourceHealth.ok;
      case TestStatus.timeout:
      case TestStatus.failed:
        return SourceHealth.dead;
      case TestStatus.testing:
      case TestStatus.idle:
        return SourceHealth.unknown;
    }
  }
}

/// 统一频道牌 —— 整套界面重构的地基组件。
///
/// 原始台标尺寸不一、底色各异,透明的在深色底上直接隐形,几千个频道摆在一起
/// 像一盘散沙。解法是不再直接贴图,而是一律合成进同一规格的牌子:
/// 固定 16:10、统一内边距、中性衬底([AppTokens.surfacePlate] 是表面阶梯里
/// 最亮的一档,正是为了让透明台标也看得见)。
///
/// 本组件内部**没有任何平台判断**,尺寸差异一律由 [width] 参数表达:
/// 手机轨道 104、TV 浮层 118、iPad 竖屏 148。
class ChannelPlate extends StatelessWidget {
  final Channel channel;

  /// 牌面宽度。高度按 16:10 自动推导。
  final double width;

  /// 焦点态（遥控器 / 键盘）。
  final bool focused;

  final SourceHealth health;

  /// 叠在牌面上的额外内容，例如聚焦时的播放图标。
  final Widget? overlay;

  const ChannelPlate({
    super.key,
    required this.channel,
    required this.width,
    this.focused = false,
    this.health = SourceHealth.unknown,
    this.overlay,
  });

  bool get _isDead => health == SourceHealth.dead;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppDimens.radiusLg);

    final plate = Container(
      width: width,
      decoration: BoxDecoration(
        color: AppTokens.surfacePlate,
        borderRadius: radius,
        border: Border.all(color: AppTokens.line),
      ),
      // 焦点环用 foregroundDecoration 画在内容之上,不进入布局计算 ——
      // 因此不会把轨道里相邻的卡片挤开。刻意不用缩放:在电视上,
      // 相邻卡片跟着位移看着会晃。
      foregroundDecoration: focused
          ? BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: AppTokens.focusRing, width: 2.5),
            )
          : null,
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: EdgeInsets.all(width * 0.11),
              child: _Mark(channel: channel, width: width),
            ),
            if (channel.quality != null)
              Positioned(
                right: width * 0.05,
                bottom: width * 0.05,
                child: _Badge(text: channel.quality!, width: width),
              ),
            if (health == SourceHealth.slow || health == SourceHealth.dead)
              Positioned(
                left: width * 0.06,
                top: width * 0.06,
                child: _HealthDot(health: health, width: width),
              ),
            if (overlay != null) Positioned.fill(child: overlay!),
          ],
        ),
      ),
    );

    // 失效的源整体压暗 —— 红点太小,单靠它在一屏几十张卡里扫不出来。
    return _isDead ? Opacity(opacity: 0.45, child: plate) : plate;
  }
}

/// 牌面主体:有台标用台标，没有或加载失败则退回文字牌面。
class _Mark extends StatelessWidget {
  final Channel channel;
  final double width;

  const _Mark({required this.channel, required this.width});

  @override
  Widget build(BuildContext context) {
    final logo = channel.logo;
    if (logo == null || logo.trim().isEmpty) {
      return _WordMark(channel: channel, width: width);
    }
    // 走缓存而非 Image.network —— 播放列表动辄几千个台标,
    // 每次滚动重新下载既慢又费流量。
    return CachedNetworkImage(
      imageUrl: logo,
      fit: BoxFit.contain,
      // 加载中与失败都退回文字牌面,牌面始终有内容,不留白。
      placeholder: (_, __) => _WordMark(channel: channel, width: width),
      errorWidget: (_, __, ___) => _WordMark(channel: channel, width: width),
    );
  }
}

/// 文字牌面。取频道名前若干字符，撑满可用空间。
class _WordMark extends StatelessWidget {
  final Channel channel;
  final double width;

  const _WordMark({required this.channel, required this.width});

  @override
  Widget build(BuildContext context) {
    final name = channel.name.trim();
    final text = name.isEmpty ? '—' : name;
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: AppTokens.textSecondary,
          fontSize: width * 0.16,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          height: 1.05,
        ),
      ),
    );
  }
}

/// 清晰度角标。压在台标上，故用半透明黑底而非跟随表面阶梯 ——
/// 它需要在任何底色上都可读。
class _Badge extends StatelessWidget {
  final String text;
  final double width;

  const _Badge({required this.text, required this.width});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: width * 0.04,
        vertical: width * 0.014,
      ),
      decoration: BoxDecoration(
        color: AppTokens.surfaceBadge,
        borderRadius: BorderRadius.circular(AppDimens.radiusSm),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: AppTokens.textPrimary,
          fontSize: width * 0.085,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          // 等宽:清晰度是数据,与时间码、频道号同属一类,排在一起要能对齐。
          fontFamily: 'monospace',
          height: 1.1,
        ),
      ),
    );
  }
}

class _HealthDot extends StatelessWidget {
  final SourceHealth health;
  final double width;

  const _HealthDot({required this.health, required this.width});

  @override
  Widget build(BuildContext context) {
    final color = health == SourceHealth.dead
        ? AppTokens.sourceDead
        : AppTokens.sourceSlow;
    final size = width * 0.07;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 0, spreadRadius: size * 0.34),
        ],
      ),
    );
  }
}
