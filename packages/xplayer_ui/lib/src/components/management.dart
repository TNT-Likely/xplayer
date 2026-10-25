import 'package:flutter/material.dart';
import '../../foundation.dart';
import 'models.dart';

class XpPlaylistCard extends StatelessWidget {
  const XpPlaylistCard(
      {super.key,
      required this.name,
      required this.channelCount,
      required this.onSelect,
      this.selected = false,
      this.status = XpPlaylistStatus.ready,
      this.updatedLabel,
      this.onRetry,
      this.onRefresh,
      this.onEdit,
      this.onRemove});
  final String name;
  final int? channelCount;
  final String? updatedLabel;
  final bool selected;
  final XpPlaylistStatus status;
  final VoidCallback? onSelect, onRetry, onRefresh, onEdit, onRemove;
  @override
  Widget build(BuildContext context) {
    final theme = XpTheme.of(context), p = theme.palette;
    final busy = status == XpPlaylistStatus.updating;
    return XpSurface(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        XpIcon(XpSymbol.sources, color: p.accent, size: 28),
        const SizedBox(width: 14),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name,
              style: TextStyle(fontSize: theme.titleSize, color: p.foreground)),
          const SizedBox(height: 8),
          Text(
              '${channelCount == null ? '正在读取频道数量' : '$channelCount 个频道'}${updatedLabel == null ? '' : ' · $updatedLabel'}',
              style: TextStyle(fontSize: theme.smallSize, color: p.muted)),
        ])),
        if (onEdit != null)
          XpIconButton(
              icon: XpSymbol.dots,
              label: '编辑播放列表 $name',
              onPressed: busy ? null : onEdit),
      ]),
      if (status == XpPlaylistStatus.error ||
          status == XpPlaylistStatus.empty) ...[
        const SizedBox(height: 18),
        XpNotice(
            title:
                status == XpPlaylistStatus.error ? '更新失败，原有频道已保留' : '没有读取到有效频道',
            description: '请检查列表地址和文件格式。',
            tone: XpTone.warning,
            actionLabel: onRetry == null ? null : '重试更新',
            onAction: onRetry),
      ],
      const SizedBox(height: 20),
      Wrap(spacing: 12, runSpacing: 10, children: [
        XpButton(
            label: selected ? '正在使用' : '切换到此列表',
            onPressed: selected || busy ? null : onSelect,
            loading: busy,
            icon: selected ? XpSymbol.check : null,
            variant: XpButtonVariant.secondary),
        if (onRefresh != null)
          XpButton(
              label: '刷新频道',
              icon: XpSymbol.sync,
              onPressed: busy ? null : onRefresh,
              variant: XpButtonVariant.secondary),
        if (onRemove != null)
          XpButton(
              label: '移除',
              onPressed: busy ? null : onRemove,
              variant: XpButtonVariant.danger),
      ]),
    ]));
  }
}

class XpRemotePad extends StatelessWidget {
  const XpRemotePad(
      {super.key, required this.connected, required this.onCommand});
  final bool connected;
  final ValueChanged<XpRemoteCommand> onCommand;
  @override
  Widget build(BuildContext context) {
    final theme = XpTheme.of(context), p = theme.palette;
    final unit = theme.isTv ? 80.0 : 64.0;
    Widget direction(XpRemoteCommand command, String label, int turns) =>
        RotatedBox(
            quarterTurns: turns,
            child: XpIconButton(
                icon: XpSymbol.arrow,
                label: label,
                onPressed: connected ? () => onCommand(command) : null));
    Widget cell(Widget child) =>
        SizedBox(width: unit, height: unit, child: Center(child: child));
    return FocusTraversalGroup(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
      Row(mainAxisSize: MainAxisSize.min, children: [
        cell(const SizedBox()),
        cell(direction(XpRemoteCommand.up, '向上', 3)),
        cell(const SizedBox())
      ]),
      Row(mainAxisSize: MainAxisSize.min, children: [
        cell(direction(XpRemoteCommand.left, '向左', 2)),
        cell(Container(
            decoration: BoxDecoration(
                color: connected ? p.accentWash : p.raised,
                borderRadius: BorderRadius.circular(16)),
            child: XpIconButton(
                icon: XpSymbol.check,
                label: '确认选择',
                onPressed: connected
                    ? () => onCommand(XpRemoteCommand.select)
                    : null))),
        cell(direction(XpRemoteCommand.right, '向右', 0))
      ]),
      Row(mainAxisSize: MainAxisSize.min, children: [
        cell(const SizedBox()),
        cell(direction(XpRemoteCommand.down, '向下', 1)),
        cell(const SizedBox())
      ]),
      const SizedBox(height: 18),
      Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            XpIconButton(
                icon: XpSymbol.back,
                label: '返回',
                onPressed:
                    connected ? () => onCommand(XpRemoteCommand.back) : null),
            XpIconButton(
                icon: XpSymbol.play,
                label: '播放或暂停',
                onPressed: connected
                    ? () => onCommand(XpRemoteCommand.playPause)
                    : null),
            XpIconButton(
                icon: XpSymbol.home,
                label: '电视主页',
                onPressed:
                    connected ? () => onCommand(XpRemoteCommand.home) : null),
          ]),
    ]));
  }
}

class XpRemoteStatusView extends StatelessWidget {
  const XpRemoteStatusView(
      {super.key,
      required this.status,
      this.onRetry,
      this.onPermissionHelp,
      this.onManualConnect,
      this.deviceName});
  final XpRemoteStatus status;
  final VoidCallback? onRetry, onPermissionHelp, onManualConnect;
  final String? deviceName;
  @override
  Widget build(BuildContext context) => switch (status) {
        XpRemoteStatus.connected => XpNotice(
            title: '已连接 ${deviceName ?? '电视'}',
            description: '方向键与文字输入已就绪。',
            tone: XpTone.success),
        XpRemoteStatus.searching => const XpNotice(
            title: '正在搜索附近的大屏',
            description: '手机与电视需要连接同一个 Wi-Fi。',
            loading: true),
        XpRemoteStatus.permissionDenied => XpEmptyState(
            title: '允许访问局域网后再连接',
            description: '当前设备尚未允许局域网访问。开启系统权限后再搜索。',
            icon: XpSymbol.wifi,
            tone: XpTone.warning,
            actionLabel: '查看设置指引',
            onAction: onPermissionHelp,
            secondaryLabel: '重新搜索',
            onSecondary: onRetry),
        XpRemoteStatus.notFound => XpEmptyState(
            title: '还没有发现附近的大屏',
            description: '确认电视已打开 XPlayer，且手机与电视位于同一个 Wi-Fi。',
            icon: XpSymbol.cast,
            actionLabel: '重新搜索',
            onAction: onRetry,
            secondaryLabel: '手动连接',
            onSecondary: onManualConnect),
        XpRemoteStatus.disconnected => XpEmptyState(
            title: '电视连接已断开',
            description: '连接恢复前暂停发送按键，避免误报操作成功。',
            icon: XpSymbol.cast,
            tone: XpTone.warning,
            actionLabel: '重新连接',
            onAction: onRetry),
      };
}

class XpSyncDiffPanel extends StatelessWidget {
  const XpSyncDiffPanel(
      {super.key,
      required this.fields,
      required this.selectedIds,
      required this.onSelectionChanged,
      required this.onApply,
      required this.onCancel,
      this.loading = false});
  final List<XpSyncField> fields;
  final Set<String> selectedIds;
  final ValueChanged<Set<String>> onSelectionChanged, onApply;
  final VoidCallback onCancel;
  final bool loading;
  @override
  Widget build(BuildContext context) {
    final theme = XpTheme.of(context), p = theme.palette;
    final validSelection =
        selectedIds.intersection(fields.map((f) => f.id).toSet());
    return XpSurface(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('确认同步差异',
          style: TextStyle(
              fontSize: theme.titleSize, fontWeight: FontWeight.w500)),
      const SizedBox(height: 10),
      Text('只应用勾选的项目，其他内容保留当前配置。',
          style:
              TextStyle(color: p.muted, fontSize: theme.bodySize, height: 1.8)),
      const SizedBox(height: 16),
      for (final field in fields)
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
          value: validSelection.contains(field.id),
          onChanged: loading
              ? null
              : (checked) {
                  final next = {...validSelection};
                  if (checked == true) {
                    next.add(field.id);
                  } else {
                    next.remove(field.id);
                  }
                  onSelectionChanged(Set.unmodifiable(next));
                },
          title: Text(field.label, style: TextStyle(fontSize: theme.bodySize)),
          subtitle: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text('当前：${field.local}\n另一台设备：${field.remote}',
                  style: TextStyle(
                      fontSize: theme.smallSize, color: p.muted, height: 1.8))),
        ),
      const SizedBox(height: 20),
      Wrap(spacing: 12, runSpacing: 10, children: [
        XpButton(
            label: '应用所选项目',
            loading: loading,
            onPressed: validSelection.isEmpty
                ? null
                : () => onApply(Set.unmodifiable(validSelection))),
        XpButton(
            label: '取消，保留当前配置',
            onPressed: loading ? null : onCancel,
            variant: XpButtonVariant.secondary),
      ]),
    ]));
  }
}
