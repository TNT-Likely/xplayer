import 'package:test/test.dart';
import 'package:dlna_cast/dlna_cast.dart';

void main() {
  group('buildMSearch', () {
    test('多播报文:HOST 指向 SSDP 组播地址,带 MX 让设备错开回包', () {
      final msg =
          buildMSearch('urn:schemas-upnp-org:device:MediaRenderer:1',
              host: '239.255.255.250', unicast: false);

      expect(msg, startsWith('M-SEARCH * HTTP/1.1\r\n'));
      expect(msg, contains('HOST: 239.255.255.250:1900\r\n'));
      expect(msg, contains('MAN: "ssdp:discover"\r\n'));
      expect(msg, contains('MX: 2\r\n'));
      expect(msg, contains('ST: urn:schemas-upnp-org:device:MediaRenderer:1\r\n'));
      expect(msg, endsWith('\r\n\r\n'));
    });

    test('单播报文:HOST 指向目标设备,且不含 MX(UPnP 1.1 要求单播省略)', () {
      final msg = buildMSearch('urn:schemas-upnp-org:service:AVTransport:1',
          host: '192.168.1.23', unicast: true);

      expect(msg, contains('HOST: 192.168.1.23:1900\r\n'));
      expect(msg, isNot(contains('MX:')));
      expect(msg, contains('ST: urn:schemas-upnp-org:service:AVTransport:1\r\n'));
      expect(msg, endsWith('\r\n\r\n'));
    });
  });

  group('subnetHostsFor', () {
    test('推出同 /24 网段全部主机,排除自身/网络号/广播号', () {
      final hosts = subnetHostsFor('192.168.1.100');

      expect(hosts, hasLength(253)); // 1..254 去掉自身
      expect(hosts, contains('192.168.1.1'));
      expect(hosts, contains('192.168.1.254'));
      expect(hosts, isNot(contains('192.168.1.100'))); // 自身
      expect(hosts, isNot(contains('192.168.1.0'))); // 网络号
      expect(hosts, isNot(contains('192.168.1.255'))); // 广播号
    });

    test('自身是 .1 时仍扫满其余 253 个', () {
      final hosts = subnetHostsFor('10.0.0.1');

      expect(hosts, hasLength(253));
      expect(hosts, isNot(contains('10.0.0.1')));
      expect(hosts.first, '10.0.0.2');
    });

    test('非法输入返回空,不产生扫描流量', () {
      expect(subnetHostsFor('192.168.1'), isEmpty);
      expect(subnetHostsFor(''), isEmpty);
      expect(subnetHostsFor('fe80::1'), isEmpty);
      expect(subnetHostsFor('192.168.1.abc'), isEmpty);
    });
  });

  group('isPrivateIPv4', () {
    test('三段私有地址段都认', () {
      expect(isPrivateIPv4('192.168.1.5'), isTrue);
      expect(isPrivateIPv4('10.1.2.3'), isTrue);
      expect(isPrivateIPv4('172.16.0.1'), isTrue);
      expect(isPrivateIPv4('172.31.255.254'), isTrue);
    });

    test('公网与 172.32+ 不认,避免把扫描打到蜂窝/公网', () {
      expect(isPrivateIPv4('8.8.8.8'), isFalse);
      expect(isPrivateIPv4('172.32.0.1'), isFalse);
      expect(isPrivateIPv4('172.15.0.1'), isFalse);
      expect(isPrivateIPv4('100.64.0.1'), isFalse); // 运营商级 NAT
    });

    test('link-local 不扫(169.254 上没有 DLNA 渲染器)', () {
      expect(isPrivateIPv4('169.254.1.1'), isFalse);
    });

    test('非法输入不认', () {
      expect(isPrivateIPv4('192.168.1'), isFalse);
      expect(isPrivateIPv4(''), isFalse);
    });
  });
}
