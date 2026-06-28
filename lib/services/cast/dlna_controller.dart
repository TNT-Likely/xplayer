import 'dart:async';

import 'package:http/http.dart' as http;

import 'package:xplayer/services/cast/dlna_device.dart';
import 'package:xplayer/services/cast/dlna_xml.dart';

/// 面向单台 DLNA 设备的 AVTransport 控制(SetURI/Play/Pause/Stop/状态/进度)。
class DlnaController {
  final DlnaDevice device;
  DlnaController(this.device);

  Future<http.Response> _post(String action, String body) {
    return http
        .post(
          device.controlUrl,
          headers: {
            'Content-Type': 'text/xml; charset="utf-8"',
            'SOAPACTION': soapAction(action),
          },
          body: body,
        )
        .timeout(const Duration(seconds: 5));
  }

  /// 设置媒体地址并开始播放。成功返回 true。
  Future<bool> setUriAndPlay(String url, {required String title}) async {
    try {
      final didl = buildDidlLite(title: title, url: url);
      final r1 = await _post(
          'SetAVTransportURI', buildSetAvTransportUri(url, didl));
      if (r1.statusCode != 200) return false;
      final r2 = await _post('Play', buildPlay());
      return r2.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> play() => _ok('Play', buildPlay());
  Future<bool> pause() => _ok('Pause', buildPause());
  Future<bool> stop() => _ok('Stop', buildStop());

  Future<bool> _ok(String action, String body) async {
    try {
      final r = await _post(action, body);
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// 当前传输状态(PLAYING/PAUSED_PLAYBACK/STOPPED/...),失败返回 null。
  Future<String?> transportState() async {
    try {
      final r = await _post('GetTransportInfo', buildGetTransportInfo());
      if (r.statusCode != 200) return null;
      return parseTransportState(r.body);
    } catch (_) {
      return null;
    }
  }

  /// 当前播放进度,失败返回 null。
  Future<Duration?> position() async {
    try {
      final r = await _post('GetPositionInfo', buildGetPositionInfo());
      if (r.statusCode != 200) return null;
      return parsePositionRelTime(r.body);
    } catch (_) {
      return null;
    }
  }
}
