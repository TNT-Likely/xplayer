import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xplayer/localization/app_localizations.dart';
import 'package:xplayer/providers/media_provider.dart';
import 'package:xplayer/shared/theme/app_tokens.dart';

/// 半模态「频道分组」抽屉(方向 A):底部升起的分组列表,左缘选中条 + 频道数,
/// 主按钮直说结果(「查看 N 个频道」)。
///
/// 替代原 ChannelGroupDialog 的手机端入口;TV 端仍可用(焦点可进入列表行)。
Future<void> showGroupSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const GroupSheet(),
  );
}

class GroupSheet extends StatefulWidget {
  const GroupSheet({super.key});

  @override
  State<GroupSheet> createState() => _GroupSheetState();
}

class _GroupSheetState extends State<GroupSheet> {
  /// 关闭前生效的临时选中项;「重置」回到全部,「完成」时写回 provider。
  String? _draft;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final mp = context.read<MediaProvider>();
    final groups = mp.availableGroups;
    // 首帧以当前筛选为草稿
    _draft ??= mp.selectedGroup;
    // 草稿对应的频道数(按钮直说结果)
    final count = (_draft == null || _draft!.isEmpty)
        ? mp.channels.length
        : mp.channels
            .where((c) =>
                c.source.isNotEmpty &&
                c.source.first.groupTitle == _draft)
            .length;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(top: 90),
        decoration: const BoxDecoration(
          color: AppTokens.surfacePanel,
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          border: Border(top: BorderSide(color: Colors.white12)),
        ),
        child: Column(
          children: [
            // 拖拽柄
            Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(top: 10, bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(l.groups,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(width: 8),
                  Text(l.groupsTotal(groups.length),
                      style: const TextStyle(
                          color: AppTokens.textTertiary, fontSize: 11)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _draft = null),
                    child: Text(l.reset,
                        style: const TextStyle(
                            color: AppTokens.textSecondary, fontSize: 12)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  _row(l.allChannels, mp.channels.length, _draft == null,
                      () => setState(() => _draft = null)),
                  for (final g in groups)
                    _row(
                        g,
                        mp.channels
                            .where((c) =>
                                c.source.isNotEmpty &&
                                c.source.first.groupTitle == g)
                            .length,
                        _draft == g, () => setState(() => _draft = g)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTokens.brand,
                    foregroundColor: AppTokens.accInk,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppDimens.radiusLg),
                    ),
                  ),
                  onPressed: () {
                    mp.setSelectedGroup(_draft);
                    Navigator.of(context).pop();
                  },
                  child: Text(l.viewGroupChannels(count),
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String name, int count, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimens.radius),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 13, 10, 13),
        decoration: selected
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(AppDimens.radius),
                gradient: LinearGradient(
                  colors: [
                    AppTokens.brand.withOpacity(0.10),
                    Colors.transparent,
                  ],
                ),
              )
            : null,
        child: IntrinsicHeight(
          child: Row(
            children: [
              // 左缘选中条
              Container(
                width: 3,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: selected ? AppTokens.brand : Colors.transparent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? Colors.white : AppTokens.textSecondary,
                    fontSize: 14.5,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              Text(
                '$count',
                style: TextStyle(
                  color: selected ? AppTokens.brand : AppTokens.textTertiary,
                  fontSize: 12.5,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
