import 'package:xml/xml.dart';

/// DLNA/UPnP AVTransport 的纯函数层:设备描述解析 + SOAP 报文构造 + 响应解析。
/// 不碰网络,便于单测。

const String kAvTransport = 'urn:schemas-upnp-org:service:AVTransport:1';

/// 设备描述解析结果(从 SSDP LOCATION 文档抽取)。
class DlnaDescription {
  final String udn;
  final String friendlyName;
  final Uri controlUrl; // AVTransport controlURL,已解析为绝对地址
  const DlnaDescription(this.udn, this.friendlyName, this.controlUrl);
}

/// 解析设备描述 XML;无 AVTransport 服务则返回 null。
/// [location] 为该文档的 URL,用于解析相对的 controlURL / URLBase。
DlnaDescription? parseDeviceDescription(String xmlStr, Uri location) {
  late final XmlDocument doc;
  try {
    doc = XmlDocument.parse(xmlStr);
  } catch (_) {
    return null;
  }

  String? firstText(String name) {
    final it = doc.findAllElements(name);
    return it.isEmpty ? null : it.first.innerText.trim();
  }

  // 找 AVTransport 服务节点,取其 controlURL
  String? controlPath;
  for (final svc in doc.findAllElements('service')) {
    final type = svc.getElement('serviceType')?.innerText ?? '';
    if (type.contains('AVTransport')) {
      controlPath = svc.getElement('controlURL')?.innerText.trim();
      break;
    }
  }
  if (controlPath == null || controlPath.isEmpty) return null;

  // 基准地址:优先 <URLBase>,否则用 location
  final urlBase = firstText('URLBase');
  final base = (urlBase != null && urlBase.isNotEmpty)
      ? Uri.tryParse(urlBase) ?? location
      : location;
  final controlUrl = base.resolve(controlPath);

  final friendly = firstText('friendlyName') ?? 'DLNA 设备';
  final udn = firstText('UDN') ?? location.toString();
  return DlnaDescription(udn, friendly, controlUrl);
}

/// 从 SSDP 响应原文里取 LOCATION 头(大小写不敏感)。
String? parseSsdpLocation(String response) {
  for (final line in response.split(RegExp(r'\r?\n'))) {
    final idx = line.indexOf(':');
    if (idx <= 0) continue;
    final key = line.substring(0, idx).trim().toLowerCase();
    if (key == 'location') return line.substring(idx + 1).trim();
  }
  return null;
}

String _esc(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');

/// DIDL-Lite 媒体元数据(嵌进 CurrentURIMetaData,需再次转义)。
/// protocolInfo 用通配,兼容直播/HLS/直链尽量多的渲染器。
String buildDidlLite({required String title, required String url}) {
  return '<DIDL-Lite xmlns="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/" '
      'xmlns:dc="http://purl.org/dc/elements/1.1/" '
      'xmlns:upnp="urn:schemas-upnp-org:metadata-1-0/upnp/">'
      '<item id="0" parentID="-1" restricted="1">'
      '<dc:title>${_esc(title)}</dc:title>'
      '<upnp:class>object.item.videoItem</upnp:class>'
      '<res protocolInfo="http-get:*:*:*">${_esc(url)}</res>'
      '</item></DIDL-Lite>';
}

String _envelope(String action, String inner) {
  return '<?xml version="1.0" encoding="utf-8"?>'
      '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" '
      's:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">'
      '<s:Body><u:$action xmlns:u="$kAvTransport">'
      '<InstanceID>0</InstanceID>$inner'
      '</u:$action></s:Body></s:Envelope>';
}

/// SOAPACTION 头值。
String soapAction(String action) => '"$kAvTransport#$action"';

String buildSetAvTransportUri(String url, String didlMetadata) => _envelope(
    'SetAVTransportURI',
    '<CurrentURI>${_esc(url)}</CurrentURI>'
        '<CurrentURIMetaData>${_esc(didlMetadata)}</CurrentURIMetaData>');

String buildPlay() => _envelope('Play', '<Speed>1</Speed>');
String buildPause() => _envelope('Pause', '');
String buildStop() => _envelope('Stop', '');
String buildGetTransportInfo() => _envelope('GetTransportInfo', '');
String buildGetPositionInfo() => _envelope('GetPositionInfo', '');

/// 从 GetTransportInfo 响应里取 CurrentTransportState
/// (PLAYING/PAUSED_PLAYBACK/STOPPED/TRANSITIONING/NO_MEDIA_PRESENT)。
String? parseTransportState(String soapXml) {
  try {
    final doc = XmlDocument.parse(soapXml);
    final e = doc.findAllElements('CurrentTransportState');
    return e.isEmpty ? null : e.first.innerText.trim();
  } catch (_) {
    return null;
  }
}

/// 从 GetPositionInfo 响应里取 RelTime(当前进度);解析失败返回 null。
Duration? parsePositionRelTime(String soapXml) {
  try {
    final doc = XmlDocument.parse(soapXml);
    final e = doc.findAllElements('RelTime');
    if (e.isEmpty) return null;
    return _parseHms(e.first.innerText.trim());
  } catch (_) {
    return null;
  }
}

/// 解析 "H:MM:SS" / "HH:MM:SS.fff" 形式的时间。
Duration? _parseHms(String s) {
  final parts = s.split(':');
  if (parts.length != 3) return null;
  final h = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final sec = double.tryParse(parts[2]);
  if (h == null || m == null || sec == null) return null;
  return Duration(
      hours: h, minutes: m, milliseconds: (sec * 1000).round());
}
