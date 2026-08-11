import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:xplayer/services/cast/dlna_device.dart';
import 'package:xplayer/services/cast/dlna_xml.dart';
import 'package:xplayer/services/log_store.dart';

const _ssdpAddr = '239.255.255.250';
const _ssdpPort = 1900;

/// 构造 M-SEARCH 报文。
/// UPnP 1.1:多播请求带 MX,设备在 0~MX 秒内随机回包以防回包风暴;
/// 单播请求则必须省略 MX,部分渲染器见到 MX 会直接不应答。
String buildMSearch(String st, {required String host, required bool unicast}) {
  final b = StringBuffer()
    ..write('M-SEARCH * HTTP/1.1\r\n')
    ..write('HOST: $host:$_ssdpPort\r\n')
    ..write('MAN: "ssdp:discover"\r\n');
  if (!unicast) b.write('MX: 2\r\n');
  b.write('ST: $st\r\n\r\n');
  return b.toString();
}

/// 由本机 IPv4 推出同 /24 网段内待探测的地址(排除自身、网络号 .0、广播号 .255)。
/// Dart 的 NetworkInterface 不暴露子网掩码,家用/办公 WiFi 绝大多数是 /24,按此假设;
/// 猜窄了只是少发现几台设备,不会把探测包发到别人的网段。
List<String> subnetHostsFor(String ip) {
  final octets = _octets(ip);
  if (octets == null) return const [];
  final prefix = '${octets[0]}.${octets[1]}.${octets[2]}';
  final self = octets[3];
  return [
    for (var i = 1; i <= 254; i++)
      if (i != self) '$prefix.$i',
  ];
}

/// 只在 RFC1918 私有段做逐 IP 探测。对蜂窝/公网地址段扫 254 个端口既发现不了
/// 客厅电视,又会让 app 的出网流量长得像端口扫描,必须挡住。
bool isPrivateIPv4(String ip) {
  final o = _octets(ip);
  if (o == null) return false;
  if (o[0] == 10) return true;
  if (o[0] == 172 && o[1] >= 16 && o[1] <= 31) return true;
  if (o[0] == 192 && o[1] == 168) return true;
  return false;
}

List<int>? _octets(String ip) {
  final parts = ip.split('.');
  if (parts.length != 4) return null;
  final out = <int>[];
  for (final p in parts) {
    final v = int.tryParse(p);
    if (v == null || v < 0 || v > 255) return null;
    out.add(v);
  }
  return out;
}

/// SSDP 发现局域网内的 DLNA MediaRenderer(自写最小实现,无三方依赖)。
///
/// 走两条腿:
///  - 多播 M-SEARCH:最快,一个包问全网段。但 iOS 14+ 要求
///    `com.apple.developer.networking.multicast` entitlement(需向 Apple 单独申请),
///    没有它系统直接拒发 —— 这就是「安卓能搜到设备、iOS 搜不到」的根因。
///  - 单播 M-SEARCH:逐个 IP 探 1900 端口,不需要任何 multicast 权限,
///    因此是 iOS 上目前唯一可用的路径;顺带还能捞到被路由器 IGMP snooping
///    挡掉多播的设备。
class DlnaDiscovery {
  /// 同时问「渲染器设备」和「AVTransport 服务」,兼容只应答其一的渲染器。
  static const _sts = [
    'urn:schemas-upnp-org:device:MediaRenderer:1',
    'urn:schemas-upnp-org:service:AVTransport:1',
  ];

  /// 单播扫描节流:每发这么多个包歇一下。253 个地址 × 2 个 ST ≈ 506 包,
  /// 按此约 250ms 发完 —— 不至于把自己的发送缓冲冲爆导致丢包。
  static const _batchSize = 24;
  static const _batchGap = Duration(milliseconds: 12);

  /// 搜索 [timeout] 时长(含发包耗时),返回去重后的设备列表。
  Future<List<DlnaDevice>> search(
      {Duration timeout = const Duration(seconds: 4)}) async {
    final deadline = DateTime.now().add(timeout);
    final seenLocations = <String>{};
    final pending = <Future<DlnaDevice?>>[];

    final socket = await _bind();
    if (socket == null) return const [];

    try {
      socket.listen((event) {
        if (event != RawSocketEvent.read) return;
        final dg = socket.receive();
        if (dg == null) return;
        final loc = parseSsdpLocation(String.fromCharCodes(dg.data));
        if (loc == null || !seenLocations.add(loc)) return;
        pending.add(_resolve(loc));
      });

      // 两条腿分开 try:多播被系统拒绝时,单播扫描必须照常进行。
      final multicastOk = await _sendMulticast(socket);
      final unicastSent = await _sendUnicastSweep(socket);
      if (!multicastOk) {
        LogStore.instance.w('cast',
            'SSDP 多播不可用(iOS 需 multicast entitlement),本轮仅靠单播扫描');
      }
      if (!multicastOk && unicastSent == 0) {
        LogStore.instance
            .e('cast', '多播与单播都没发出去,无法发现设备:检查本地网络权限与 WiFi 连接');
      }

      final rest = deadline.difference(DateTime.now());
      if (rest > Duration.zero) await Future<void>.delayed(rest);
    } finally {
      socket.close();
    }

    final resolved = await Future.wait(pending);
    final byUdn = <String, DlnaDevice>{};
    for (final d in resolved) {
      if (d != null) byUdn[d.udn] = d;
    }
    LogStore.instance.i('cast',
        '发现结束:收到 ${seenLocations.length} 个 SSDP 应答,解析出 ${byUdn.length} 台可投设备');
    return byUdn.values.toList();
  }

  Future<RawDatagramSocket?> _bind() async {
    try {
      return await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    } catch (e) {
      LogStore.instance.e('cast', 'SSDP socket 绑定失败,无法发现设备:$e');
      return null;
    }
  }

  /// 发多播 M-SEARCH。返回是否至少发出去一个包。
  Future<bool> _sendMulticast(RawDatagramSocket socket) async {
    var anySent = false;
    try {
      socket.multicastHops = 4;
      final target = InternetAddress(_ssdpAddr);
      for (final st in _sts) {
        final pkt = buildMSearch(st, host: _ssdpAddr, unicast: false).codeUnits;
        // 发两轮防丢包(UDP 无重传)。
        for (var i = 0; i < 2; i++) {
          if (socket.send(pkt, target, _ssdpPort) > 0) anySent = true;
          await Future<void>.delayed(const Duration(milliseconds: 150));
        }
      }
    } catch (e) {
      // iOS 无 multicast entitlement 时这里是 SocketException(errno 65)。
      LogStore.instance.w('cast', '多播 M-SEARCH 被拒:$e');
      return false;
    }
    return anySent;
  }

  /// 对本机所在私有 /24 网段逐个 IP 发单播 M-SEARCH。返回实际发出的包数。
  Future<int> _sendUnicastSweep(RawDatagramSocket socket) async {
    final targets = await _scanTargets();
    if (targets.isEmpty) {
      LogStore.instance.w('cast', '未找到可扫描的私有网段(没连 WiFi?),跳过单播发现');
      return 0;
    }

    var sent = 0;
    var inBatch = 0;
    for (final ip in targets) {
      final addr = InternetAddress(ip);
      for (final st in _sts) {
        try {
          final pkt = buildMSearch(st, host: ip, unicast: true).codeUnits;
          if (socket.send(pkt, addr, _ssdpPort) > 0) sent++;
        } catch (_) {
          // 个别地址不可达(ENETUNREACH)属正常,不影响整轮扫描。
        }
      }
      if (++inBatch >= _batchSize) {
        inBatch = 0;
        await Future<void>.delayed(_batchGap);
      }
    }
    LogStore.instance
        .d('cast', '单播扫描:${targets.length} 个地址,发出 $sent 个探测包');
    return sent;
  }

  /// 本机所有私有网段 /24 内的待探测地址(多网卡合并去重)。
  Future<List<String>> _scanTargets() async {
    final List<NetworkInterface> ifaces;
    try {
      ifaces = await NetworkInterface.list(
          includeLoopback: false, type: InternetAddressType.IPv4);
    } catch (e) {
      LogStore.instance.w('cast', '枚举网卡失败:$e');
      return const [];
    }

    final out = <String>{};
    for (final iface in ifaces) {
      for (final addr in iface.addresses) {
        if (!isPrivateIPv4(addr.address)) continue;
        LogStore.instance
            .d('cast', '扫描网段 ${addr.address}/24 (${iface.name})');
        out.addAll(subnetHostsFor(addr.address));
      }
    }
    return out.toList();
  }

  /// 拉取设备描述文档并解析为 DlnaDevice;失败/非 AVTransport 设备返回 null。
  Future<DlnaDevice?> _resolve(String location) async {
    try {
      final uri = Uri.parse(location);
      final res = await http.get(uri).timeout(const Duration(seconds: 3));
      if (res.statusCode != 200) return null;
      final desc = parseDeviceDescription(res.body, uri);
      if (desc == null) return null;
      return DlnaDevice(
        udn: desc.udn,
        friendlyName: desc.friendlyName,
        location: uri,
        controlUrl: desc.controlUrl,
      );
    } catch (e) {
      LogStore.instance.d('cast', '设备描述拉取失败 $location:$e');
      return null;
    }
  }
}
