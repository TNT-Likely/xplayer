import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xplayer/localization/app_localizations.dart';
import 'package:xplayer/providers/media_provider.dart';
import 'package:xplayer/shared/theme/app_tokens.dart';

/// 首页「分组 chips 行」(方向 A):横向滚动的一键筛选。
///
/// 与顶栏的分组入口并存:chips 服务高频筛选,抽屉([showGroupSheet])
/// 服务「先看数量再选」的低频场景;两者都写 [MediaProvider.setSelectedGroup]。
class GroupChipsRow extends StatelessWidget {
  final VoidCallback? onOpenSheet;

  const GroupChipsRow({super.key, this.onOpenSheet});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Consumer<MediaProvider>(
      builder: (context, mp, _) {
        final groups = mp.availableGroups;
        if (groups.isEmpty) return const SizedBox.shrink();
        final selected = mp.selectedGroup;
        // 全部 + 各分组;「全部」即 selectedGroup 为空
        final chips = <String>[l.allChannels, ...groups];
        return SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: chips.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final name = chips[i];
              final isAll = i == 0;
              final active = isAll
                  ? (selected == null || selected.isEmpty)
                  : selected == name;
              return _Chip(
                label: name,
                active: active,
                onTap: () => mp.setSelectedGroup(isAll ? null : name),
              );
            },
          ),
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _Chip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppTokens.brand : AppTokens.surfacePanel,
      borderRadius: BorderRadius.circular(AppDimens.radiusPill),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimens.radiusPill),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimens.radiusPill),
            border: Border.all(
              color: active ? AppTokens.brand : Colors.white12,
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active ? AppTokens.accInk : AppTokens.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
