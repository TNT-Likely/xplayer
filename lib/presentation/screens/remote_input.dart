import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
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
    final uri = Uri.tryParse('ws://${_address.text.trim()}');
    if (uri == null ||
        uri.host.isEmpty ||
        !uri.hasPort ||
        uri.port < 1 ||
        uri.port > 65535) {
      setState(() => _error = '请输入电视显示的 IP 和端口，例如 192.168.1.8:8080。');
      return;
    }
    _connect(
      RemoteDeviceInfo(
        id: 'manual-${uri.host}:${uri.port}',
        name: '手动连接的电视',
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
      setState(() {
        _live = sent;
        _sent = sent ? '文字已发送，后续修改实时同步。' : '尚未连接电视。';
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
    if (mounted) setState(() => _sent = sent ? '已发送：$key' : '连接已断开，请重新连接。');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RemoteProvider>();
    final status = provider.permissionDenied
        ? XpRemoteStatus.permissionDenied
        : provider.isConnected
        ? XpRemoteStatus.connected
        : provider.isDiscovering
        ? XpRemoteStatus.searching
        : provider.connectionError != null
        ? XpRemoteStatus.disconnected
        : XpRemoteStatus.notFound;
    return Scaffold(
      appBar: AppBar(title: const Text('电视遥控')),
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
                if (provider.connectionError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: XpNotice(
                      title: '连接提示',
                      description: provider.connectionError!,
                      tone: XpTone.warning,
                    ),
                  ),
                const SizedBox(height: 20),
                XpSurface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      XpSectionHeading(
                        title: '附近设备',
                        actionLabel: '重新搜索',
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
                        const XpNotice(
                          title: '正在连接电视',
                          description: '正在确认连接，请稍候。',
                          loading: true,
                        ),
                      if (provider.isConnected)
                        XpButton(
                          label: '断开连接',
                          onPressed: provider.disconnect,
                          variant: XpButtonVariant.secondary,
                        ),
                      const SizedBox(height: 18),
                      XpTextField(
                        controller: _address,
                        label: '电视地址（IP:端口）',
                        hint: '192.168.1.8:8080',
                        error: _error,
                      ),
                      const SizedBox(height: 12),
                      XpButton(
                        label: '通过地址连接',
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
                        label: '发送文字到电视',
                        hint: '列表地址、搜索关键词…',
                        onChanged: _change,
                        enabled: provider.isConnected,
                      ),
                      const SizedBox(height: 16),
                      XpButton(
                        label: '发送文字',
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
