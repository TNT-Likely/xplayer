import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:xplayer/utils/epg_metrics.dart';

/// 顶部时间刻度,每 30 分钟一格。横向滚动由外部 [controller] 驱动(与主区同步)。
class EpgTimeAxis extends StatelessWidget {
  final EpgMetrics metrics;
  final ScrollController controller;

  const EpgTimeAxis(
      {super.key, required this.metrics, required this.controller});

  @override
  Widget build(BuildContext context) {
    final totalMinutes =
        metrics.windowEnd.difference(metrics.windowStart).inMinutes;
    final ticks = (totalMinutes / 30).ceil();
    final tickWidth = 30 * metrics.pxPerMinute;

    return SizedBox(
      height: metrics.timeAxisHeight,
      child: SingleChildScrollView(
        controller: controller,
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: SizedBox(
          width: metrics.contentWidth,
          child: Row(
            children: List.generate(ticks, (i) {
              final t = metrics.windowStart.add(Duration(minutes: 30 * i));
              return Container(
                width: tickWidth,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 6),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: Colors.white.withOpacity(0.10)),
                  ),
                ),
                child: Text(
                  DateFormat('HH:mm').format(t.toLocal()),
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.7), fontSize: 12),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
