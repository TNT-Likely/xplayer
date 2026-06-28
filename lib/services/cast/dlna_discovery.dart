import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:xplayer/services/cast/dlna_device.dart';
import 'package:xplayer/services/cast/dlna_xml.dart';

/// SSDP 发现局域网内的 DLNA MediaRenderer(自写最小实现,无三方依赖)。
class DlnaDiscovery {
  static const _ssdpAddr = '239.255.255.250';
  static const _ssdpPort = 1900;

  String _mSearch(String st) => 'M-SEARCH * HTTP/1.1\r\n'
      'HOST: $_ssdpAddr:$_ssdpPort\r\n'
      'MAN: "ssdp:discover"\r\n'
      'MX: 2\r\n'
      'ST: $st\r\n\r\n';

  /// 搜索 [timeout] 时长,返回去重后的设备列表。
  Future<List<DlnaDevice>> search(
      {Duration timeout = const Duration(seconds: 4)}) async {
    RawDatagramSocket? socket;
    final seenLocations = <String>{};
    final pending = <Future<DlnaDevice?>>[];
    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.multicastHops = 4;

      socket.listen((event) {
        if (event != RawSocketEvent.read) return;
        final dg = socket!.receive();
        if (dg == null) return;
        final resp = String.fromCharCodes(dg.data);
        final loc = parseSsdpLocation(resp);
        if (loc == null || !seenLocations.add(loc)) return;
        pending.add(_resolve(loc));
      });

      final target = InternetAddress(_ssdpAddr);
      // 同时搜 MediaRenderer 设备与 AVTransport 服务,兼容只回其一的渲染器;发两轮防丢包。
      for (final st in const [
        'urn:schemas-upnp-org:device:MediaRenderer:1',
        'urn:schemas-upnp-org:service:AVTransport:1',
      ]) {
        final pkt = _mSearch(st).codeUnits;
        socket.send(pkt, target, _ssdpPort);
        await Future<void>.delayed(const Duration(milliseconds: 150));
        socket.send(pkt, target, _ssdpPort);
      }

      await Future<void>.delayed(timeout);
    } catch (_) {
      // 多播失败(权限/网络)→ 返回已收集到的
    } finally {
      socket?.close();
    }

    final resolved = await Future.wait(pending);
    final byUdn = <String, DlnaDevice>{};
    for (final d in resolved) {
      if (d != null) byUdn[d.udn] = d;
    }
    return byUdn.values.toList();
  }

  /// 拉取设备描述文档并解析为 DlnaDevice;失败/非 AVTransport 设备返回 null。
  Future<DlnaDevice?> _resolve(String location) async {
    try {
      final uri = Uri.parse(location);
      final res = await http
          .get(uri)
          .timeout(const Duration(seconds: 3));
      if (res.statusCode != 200) return null;
      final desc = parseDeviceDescription(res.body, uri);
      if (desc == null) return null;
      return DlnaDevice(
        udn: desc.udn,
        friendlyName: desc.friendlyName,
        location: uri,
        controlUrl: desc.controlUrl,
      );
    } catch (_) {
      return null;
    }
  }
}
