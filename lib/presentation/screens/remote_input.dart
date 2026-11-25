import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:xplayer/localization/app_localizations.dart';
import 'package:xplayer/providers/remote_provider.dart';
import 'package:xplayer/services/remote/remote_protocol.dart';
import 'package:xplayer_ui/xplayer_ui.dart';

class RemoteInputScreen extends StatefulWidget {
  const RemoteInputScreen({super.key});
  @override
  State<RemoteInputScreen> createState() => _RemoteInputScreenState();
}

class _RemoteInputScreenState extends State<RemoteInputScreen> {
  final _text = TextEditingController();
  final _address = TextEditingController();
  late final RemoteProvider _provider;
  Timer? _debounce;
  bool _live = false;
  String? _error;
  String? _sent;
  @override
  void initState() {
    super.initState();
    _provider = context.read<RemoteProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<RemoteProvider>().startDiscovery();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _provider.stopDiscovery();
    _text.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _connect(RemoteDeviceInfo device) async {
    setState(() {
      _live = false;
      _error = null;
      _sent = null;
    });
    await context.read<RemoteProvider>().connect(device);
  }

  void _manual() {
    final l = AppLocalizations.of(context)!;
    final uri = Uri.tryParse('ws://${_address.text.trim()}');
    if (uri == null ||
        uri.host.isEmpty ||
        !uri.hasPort ||
        uri.port < 1 ||
        uri.port > 65535) {
      setState(() => _error = l.remoteManualAddressInvalid);
      return;
    }
    _connect(
      RemoteDeviceInfo(
        id: 'manual-${uri.host}:${uri.port}',
        name: l.remoteManualTv,
        host: uri.host,
        port: uri.port,
      ),
    );
  }

  void _change(String _) {
    _debounce?.cancel();
    if (!_live || !context.read<RemoteProvider>().isConnected) return;
    _debounce = Timer(const Duration(milliseconds: 120), () {
      if (mounted) context.read<RemoteProvider>().sendText(_text.text);
    });
  }

  Future<void> _send() async {
    final provider = context.read<RemoteProvider>();
    final sent = await provider.sendText(_text.text);
    if (mounted) {
      final l = AppLocalizations.of(context)!;
      setState(() {
        _live = sent;
        _sent = sent ? l.remoteTextSent : l.remoteNotConnected;
      });
    }
  }

  Future<void> _command(XpRemoteCommand command) async {
    final key = switch (command) {
      XpRemoteCommand.select => 'enter',
      XpRemoteCommand.playPause => 'playpause',
      _ => command.name,
    };
    final sent = await context.read<RemoteProvider>().sendKey(key);
    if (mounted) {
      final l = AppLocalizations.of(context)!;
      setState(
        () => _sent = sent ? l.remoteCommandSent(key) : l.remoteReconnectHint,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final provider = context.watch<RemoteProvider>();
    final connectionError = switch (provider.connectionError) {
      RemoteConnectionError.discoveryFailed => l.remoteDiscoveryFailed,
      RemoteConnectionError.connectionLost => l.remoteConnectionLost,
      RemoteConnectionError.connectionFailed => l.remoteConnectionFailed,
      RemoteConnectionError.sendFailed => l.remoteReconnectHint,
      null => null,
    };
    final status = provider.permissionDenied
        ? XpRemoteStatus.permissionDenied
        : provider.isConnected
        ? XpRemoteStatus.connected
        : provider.isDiscovering
        ? XpRemoteStatus.searching
        : connectionError != null
        ? XpRemoteStatus.disconnected
        : XpRemoteStatus.notFound;
    return Scaffold(
      appBar: AppBar(title: Text(l.televisionRemote)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                XpRemoteStatusView(
                  status: status,
                  deviceName: provider.current?.name,
                  onPermissionHelp: openAppSettings,
                  onRetry: provider.startDiscovery,
                ),
                if (connectionError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: XpNotice(
                      title: l.remoteConnectionNotice,
                      description: connectionError,
                      tone: XpTone.warning,
                    ),
                  ),
                const SizedBox(height: 20),
                XpSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      XpSectionHeading(
                        title: l.nearbyDevices,
                        actionLabel: l.searchNearbyAgain,
                        onAction: provider.isDiscovering
                            ? null
                            : provider.startDiscovery,
                      ),
                      for (final device in provider.devices)
                        XpNavigationItem(
                          label: '${device.name} · ${device.host}',
                          icon: XpSymbol.remote,
                          selected: provider.current?.id == device.id,
                          onPressed: provider.isConnecting
                              ? null
                              : () => _connect(device),
                        ),
                      if (provider.isConnecting)
                        XpNotice(
                          title: l.connectingToTv,
                          description: l.connectingToTvHint,
                          loading: true,
                        ),
                      if (provider.isConnected)
                        XpButton(
                          label: l.remoteDisconnect,
                          onPressed: provider.disconnect,
                          variant: XpButtonVariant.secondary,
                        ),
                      const SizedBox(height: 18),
                      XpTextField(
                        controller: _address,
                        label: l.remoteTvAddress,
                        hint: '192.168.1.8:8080',
                        error: _error,
                      ),
                      const SizedBox(height: 12),
                      XpButton(
                        label: l.remoteConnectByAddress,
                        onPressed: provider.isConnecting ? null : _manual,
                        variant: XpButtonVariant.secondary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                XpSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      XpTextField(
                        controller: _text,
                        label: l.remoteTextLabel,
                        hint: l.remoteTextHint,
                        onChanged: _change,
                        enabled: provider.isConnected,
                      ),
                      const SizedBox(height: 16),
                      XpButton(
                        label: l.remoteSendText,
                        icon: XpSymbol.keyboard,
                        onPressed: provider.isConnected ? _send : null,
                      ),
                      const SizedBox(height: 24),
                      XpRemotePad(
                        connected: provider.isConnected,
                        onCommand: _command,
                      ),
                      if (_sent != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: Text(_sent!),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
