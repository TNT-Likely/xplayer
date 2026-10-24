import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xplayer/localization/app_localizations.dart';
import 'package:xplayer/presentation/widgets/home/group_sheet.dart';
import 'package:xplayer/providers/media_provider.dart';
import 'package:xplayer/shared/components/x_icon_button.dart';
import 'package:xplayer/shared/theme/app_tokens.dart';
import 'package:xplayer/utils/toast.dart';

/// 首页顶栏(方向 A):菜单键打开抽屉;右侧 搜索 / 分组 / 隐藏不可播 / 测速。
///
/// 从 home.dart 抽出:原实现把筛选图标激活态(红点)内联在 AppBar actions,
/// 这里统一收敛为 [HomeAppBar] + [_FilterIcon]。
class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onOpenDrawer;
  final VoidCallback onSearch;

  const HomeAppBar({
    super.key,
    required this.onOpenDrawer,
    required this.onSearch,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;

    return AppBar(
      leading: XIconButton(
        icon: Icons.menu,
        hoverBgOnly: true,
        onPressed: onOpenDrawer,
      ),
      automaticallyImplyLeading: false,
      // 测试进行中:标题显示进度
      title: Consumer<MediaProvider>(
        builder: (context, mp, _) {
          if (!mp.isTesting) return const SizedBox.shrink();
          return Text(
            '${l.testing}: ${mp.testProgressText}',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          );
        },
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      actions: [
        Consumer<MediaProvider>(
          builder: (context, mp, _) {
            if (mp.channels.isEmpty) return const SizedBox.shrink();
            final hasGroups = mp.availableGroups.isNotEmpty;
            final groupActive =
                mp.selectedGroup != null && mp.selectedGroup!.isNotEmpty;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _FilterIcon(
                  icon: Icons.search,
                  tooltip: l.search,
                  active: mp.searchQuery.isNotEmpty,
                  onPressed: onSearch,
                ),
                if (hasGroups)
                  _FilterIcon(
                    icon: Icons.filter_list,
                    tooltip: l.groups,
                    active: groupActive,
                    onPressed: () => showGroupSheet(context),
                  ),
                // 测速后才出现:隐藏无法播放的频道(可恢复)
                if (mp.hasTestResults)
                  _FilterIcon(
                    icon: Icons.playlist_remove,
                    tooltip: l.hideUnplayable,
                    active: mp.hideUnplayable,
                    onPressed: () => mp.setHideUnplayable(!mp.hideUnplayable),
                  ),
              ],
            );
          },
        ),
        Consumer<MediaProvider>(
          builder: (context, mp, _) {
            if (mp.isTesting) {
              return XIconButton(
                icon: Icons.cancel,
                hoverBgOnly: true,
                tooltipMessage: l.cancel,
                onPressed: () {
                  mp.cancelTest();
                  showToast(l.testCancelled);
                },
              );
            }
            return XIconButton(
              icon: Icons.speed,
              hoverBgOnly: true,
              tooltipMessage: l.testChannels,
              onPressed: () async {
                try {
                  showToast(l.testingChannels);
                  await mp.testAllChannels();
                  showToast(l.testCompleted);
                } catch (e) {
                  showToast(l.testFailed(e.toString()));
                }
              },
            );
          },
        ),
      ],
    );
  }
}

/// 右上角筛选入口图标;[active] 为 true 时右上角叠加选中红点。
class _FilterIcon extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool active;
  final VoidCallback onPressed;

  const _FilterIcon({
    required this.icon,
    required this.tooltip,
    required this.active,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final button = XIconButton(
      icon: icon,
      hoverBgOnly: true,
      tooltipMessage: tooltip,
      onPressed: onPressed,
    );
    if (!active) return button;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        button,
        Positioned(
          right: 6,
          top: 6,
          child: IgnorePointer(
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: AppTokens.brand,
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.black.withOpacity(0.45), width: 1),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
