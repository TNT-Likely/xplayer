import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:xplayer/data/models/programme_model.dart';
import 'package:xplayer/shared/components/x_base_button.dart';

/// 时间轴上的单个节目块。live=正在播,高亮。点击/OK 触发 onTap。
class EpgProgrammeBlock extends StatelessWidget {
  final Programme programme;
  final bool live;
  final VoidCallback onTap;

  const EpgProgrammeBlock({
    super.key,
    required this.programme,
    required this.live,
    required this.onTap,
  });

  String _t(DateTime d) => DateFormat('HH:mm').format(d.toLocal());

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return XBaseButton(
      onPressed: onTap,
      child: (isFocus) => Container(
        margin: const EdgeInsets.all(2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: live
              ? primary.withOpacity(0.30)
              : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isFocus
                ? Colors.white
                : (live ? primary : Colors.white.withOpacity(0.12)),
            width: isFocus ? 2 : 1,
          ),
        ),
        alignment: Alignment.centerLeft,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              programme.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              '${_t(programme.start)}–${_t(programme.stop)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.7), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
