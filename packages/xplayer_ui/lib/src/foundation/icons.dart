import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'theme.dart';

enum XpSymbol {
  home,
  channels,
  guide,
  heart,
  sources,
  settings,
  remote,
  search,
  arrow,
  back,
  play,
  pause,
  plus,
  close,
  check,
  sync,
  cast,
  volume,
  full,
  clock,
  info,
  wifi,
  sun,
  globe,
  folder,
  link,
  keyboard,
  dots,
}

/// 直接消费已确认设计稿中的 28 个 SVG，图标不替换为另一套字形。
class XpIcon extends StatelessWidget {
  const XpIcon(this.symbol, {super.key, this.size, this.color});
  final XpSymbol symbol;
  final double? size;
  final Color? color;
  @override
  Widget build(BuildContext context) {
    final theme = XpTheme.of(context);
    final resolved =
        color ?? IconTheme.of(context).color ?? theme.palette.muted;
    return SvgPicture.asset(
      'assets/icons/${symbol.name}.svg',
      package: 'xplayer_ui',
      width: size ?? theme.iconSize,
      height: size ?? theme.iconSize,
      colorFilter: ColorFilter.mode(resolved, BlendMode.srcIn),
      excludeFromSemantics: true,
    );
  }
}
