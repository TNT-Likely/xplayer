import 'package:flutter_test/flutter_test.dart';
import 'package:xplayer/services/cast/dlna_xml.dart';

void main() {
  group('parseDeviceDescription', () {
    final location = Uri.parse('http://192.168.1.10:8200/desc.xml');

    test('解析 friendlyName + 相对 controlURL', () {
      const xml = '''
<root xmlns="urn:schemas-upnp-org:device-1-0">
  <device>
    <friendlyName>客厅电视</friendlyName>
    <UDN>uuid:abc-123</UDN>
    <serviceList>
      <service>
        <serviceType>urn:schemas-upnp-org:service:RenderingControl:1</serviceType>
        <controlURL>/rc/control</controlURL>
      </service>
      <service>
        <serviceType>urn:schemas-upnp-org:service:AVTransport:1</serviceType>
        <controlURL>/avt/control</controlURL>
      </service>
    </serviceList>
  </device>
</root>''';
      final d = parseDeviceDescription(xml, location);
      expect(d, isNotNull);
      expect(d!.friendlyName, '客厅电视');
      expect(d.udn, 'uuid:abc-123');
      expect(d.controlUrl.toString(), 'http://192.168.1.10:8200/avt/control');
    });

    test('URLBase 优先于 location 解析 controlURL', () {
      const xml = '''
<root>
  <URLBase>http://192.168.1.10:49152/</URLBase>
  <device>
    <friendlyName>盒子</friendlyName>
    <UDN>uuid:x</UDN>
    <service>
      <serviceType>urn:schemas-upnp-org:service:AVTransport:1</serviceType>
      <controlURL>AVTransport/control</controlURL>
    </service>
  </device>
</root>''';
      final d = parseDeviceDescription(xml, location);
      expect(d!.controlUrl.toString(),
          'http://192.168.1.10:49152/AVTransport/control');
    });

    test('无 AVTransport 服务返回 null', () {
      const xml = '''
<root><device><friendlyName>只读设备</friendlyName>
<service><serviceType>urn:schemas-upnp-org:service:RenderingControl:1</serviceType>
<controlURL>/rc</controlURL></service></device></root>''';
      expect(parseDeviceDescription(xml, location), isNull);
    });

    test('非法 XML 返回 null', () {
      expect(parseDeviceDescription('<not xml', location), isNull);
    });
  });

  group('parseSsdpLocation', () {
    test('大小写不敏感取 LOCATION', () {
      const resp = 'HTTP/1.1 200 OK\r\n'
          'CACHE-CONTROL: max-age=1800\r\n'
          'Location: http://192.168.1.10:8200/desc.xml\r\n'
          'ST: urn:schemas-upnp-org:device:MediaRenderer:1\r\n\r\n';
      expect(parseSsdpLocation(resp), 'http://192.168.1.10:8200/desc.xml');
    });

    test('无 LOCATION 返回 null', () {
      expect(parseSsdpLocation('HTTP/1.1 200 OK\r\nST: x\r\n'), isNull);
    });
  });

  group('SOAP 构造', () {
    test('SetAVTransportURI 含转义后的 URL 与内嵌 DIDL', () {
      final didl = buildDidlLite(title: 'CCTV1 & HD', url: 'http://h/a.m3u8?x=1&y=2');
      final soap = buildSetAvTransportUri('http://h/a.m3u8?x=1&y=2', didl);
      expect(soap, contains('<u:SetAVTransportURI'));
      expect(soap, contains('<InstanceID>0</InstanceID>'));
      // URL 里的 & 必须转义
      expect(soap, contains('x=1&amp;y=2'));
      // DIDL 作为文本内嵌,其尖括号被二次转义
      expect(soap, contains('&lt;DIDL-Lite'));
    });

    test('soapAction 头值格式', () {
      expect(soapAction('Play'),
          '"urn:schemas-upnp-org:service:AVTransport:1#Play"');
    });
  });

  group('响应解析', () {
    test('parseTransportState', () {
      const xml = '''
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"><s:Body>
<u:GetTransportInfoResponse xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">
<CurrentTransportState>PLAYING</CurrentTransportState>
<CurrentTransportStatus>OK</CurrentTransportStatus>
</u:GetTransportInfoResponse></s:Body></s:Envelope>''';
      expect(parseTransportState(xml), 'PLAYING');
    });

    test('parsePositionRelTime 解析 H:MM:SS', () {
      const xml = '''
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"><s:Body>
<u:GetPositionInfoResponse xmlns:u="urn:schemas-upnp-org:service:AVTransport:1">
<RelTime>0:01:30</RelTime></u:GetPositionInfoResponse></s:Body></s:Envelope>''';
      expect(parsePositionRelTime(xml), const Duration(minutes: 1, seconds: 30));
    });
  });
}
