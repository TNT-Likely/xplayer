import 'package:flutter/material.dart';
import '../../foundation.dart';
import '../localization/ui_strings.dart';
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
    final l = context.xpStrings;
    final theme = XpTheme.of(context), p = theme.palette;
    final busy = status == XpPlaylistStatus.updating;
    final countLabel = channelCount == null
        ? l.loadingChannelCount
        : l.channelCount(channelCount!);
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
              updatedLabel == null ? countLabel : '$countLabel · $updatedLabel',
              style: TextStyle(fontSize: theme.smallSize, color: p.muted)),
        ])),
        if (onEdit != null)
          XpIconButton(
              icon: XpSymbol.dots,
              label: l.editPlaylist(name),
              onPressed: busy ? null : onEdit),
      ]),
      if (status == XpPlaylistStatus.error ||
          status == XpPlaylistStatus.empty) ...[
        const SizedBox(height: 18),
        XpNotice(
            title: status == XpPlaylistStatus.error
                ? l.playlistUpdateFailed
                : l.playlistEmpty,
            description: l.playlistReadHint,
            tone: XpTone.warning,
            actionLabel: onRetry == null ? null : l.retryUpdate,
            onAction: onRetry),
      ],
      const SizedBox(height: 20),
      Wrap(spacing: 12, runSpacing: 10, children: [
        XpButton(
            label: selected ? l.selectedPlaylist : l.switchPlaylist,
            onPressed: selected || busy ? null : onSelect,
            loading: busy,
            icon: selected ? XpSymbol.check : null,
            variant: XpButtonVariant.secondary),
        if (onRefresh != null)
          XpButton(
              label: l.refreshChannels,
              icon: XpSymbol.sync,
              onPressed: busy ? null : onRefresh,
              variant: XpButtonVariant.secondary),
        if (onRemove != null)
          XpButton(
              label: l.remove,
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
    final l = context.xpStrings;
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
        cell(direction(XpRemoteCommand.up, l.remoteUp, 3)),
        cell(const SizedBox())
      ]),
      Row(mainAxisSize: MainAxisSize.min, children: [
        cell(direction(XpRemoteCommand.left, l.remoteLeft, 2)),
        cell(Container(
            decoration: BoxDecoration(
                color: connected ? p.accentWash : p.raised,
                borderRadius: BorderRadius.circular(16)),
            child: XpIconButton(
                icon: XpSymbol.check,
                label: l.remoteOK,
                onPressed: connected
                    ? () => onCommand(XpRemoteCommand.select)
                    : null))),
        cell(direction(XpRemoteCommand.right, l.remoteRight, 0))
      ]),
      Row(mainAxisSize: MainAxisSize.min, children: [
        cell(const SizedBox()),
        cell(direction(XpRemoteCommand.down, l.remoteDown, 1)),
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
                label: l.remoteBack,
                onPressed:
                    connected ? () => onCommand(XpRemoteCommand.back) : null),
            XpIconButton(
                icon: XpSymbol.play,
                label: l.remotePlayPause,
                onPressed: connected
                    ? () => onCommand(XpRemoteCommand.playPause)
                    : null),
            XpIconButton(
                icon: XpSymbol.home,
                label: l.remoteHome,
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
  Widget build(BuildContext context) {
    final l = context.xpStrings;
    return switch (status) {
      XpRemoteStatus.connected => XpNotice(
          title: l.remoteConnected(deviceName ?? l.television),
          description: l.remoteConnectedHint,
          tone: XpTone.success),
      XpRemoteStatus.searching => XpNotice(
          title: l.remoteDiscovering,
          description: l.remoteDiscoveringHint,
          loading: true),
      XpRemoteStatus.permissionDenied => XpEmptyState(
          title: l.remotePermissionRequired,
          description: l.remotePermissionRequiredHint,
          icon: XpSymbol.wifi,
          tone: XpTone.warning,
          actionLabel: l.remoteSettingsHelp,
          onAction: onPermissionHelp,
          secondaryLabel: l.remoteSearchAgain,
          onSecondary: onRetry),
      XpRemoteStatus.notFound => XpEmptyState(
          title: l.remoteNoDevice,
          description: l.remoteNoDeviceHint,
          icon: XpSymbol.cast,
          actionLabel: l.remoteSearchAgain,
          onAction: onRetry,
          secondaryLabel: l.remoteConnectManually,
          onSecondary: onManualConnect),
      XpRemoteStatus.disconnected => XpEmptyState(
          title: l.remoteDisconnected,
          description: l.remoteDisconnectedHint,
          icon: XpSymbol.cast,
          tone: XpTone.warning,
          actionLabel: l.remoteReconnect,
          onAction: onRetry),
    };
  }
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
    final l = context.xpStrings;
    final theme = XpTheme.of(context), p = theme.palette;
    final validSelection =
        selectedIds.intersection(fields.map((f) => f.id).toSet());
    return XpSurface(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(l.syncReview,
          style: TextStyle(
              fontSize: theme.titleSize, fontWeight: FontWeight.w500)),
      const SizedBox(height: 10),
      Text(l.syncReviewHint,
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
              child: Text(l.syncComparison(field.local, field.remote),
                  style: TextStyle(
                      fontSize: theme.smallSize, color: p.muted, height: 1.8))),
        ),
      const SizedBox(height: 20),
      Wrap(spacing: 12, runSpacing: 10, children: [
        XpButton(
            label: l.syncApplySelected,
            loading: loading,
            onPressed: validSelection.isEmpty
                ? null
                : () => onApply(Set.unmodifiable(validSelection))),
        XpButton(
            label: l.syncCancel,
            onPressed: loading ? null : onCancel,
            variant: XpButtonVariant.secondary),
      ]),
    ]));
  }
}
