import 'package:flutter/material.dart';

/// 统一的 IPv6 角标。
///
/// 两处复用:源选择列表(右上角浮标,[corner]=true)、
/// 播放器信息栏(贴在分辨率角标后面,[corner]=false)。
class Ipv6Badge extends StatelessWidget {
  /// corner=true 时为右上角浮标样式(更小、带描边);false 为行内标签样式。
  final bool corner;

  const Ipv6Badge({super.key, this.corner = false});

  @override
  Widget build(BuildContext context) {
    final badge = Container(
      padding: EdgeInsets.symmetric(
        horizontal: corner ? 4 : 6,
        vertical: corner ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32), // 绿色,区别于分辨率角标
        borderRadius: BorderRadius.circular(4),
        border:
            corner ? Border.all(color: Colors.white, width: 1) : null,
      ),
      child: Text(
        'IPv6',
        style: TextStyle(
          color: Colors.white,
          fontSize: corner ? 9 : 11,
          fontWeight: FontWeight.w700,
          height: 1.0,
          decoration: TextDecoration.none,
        ),
      ),
    );
    return badge;
  }
}
