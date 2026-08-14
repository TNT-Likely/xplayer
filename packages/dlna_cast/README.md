# dlna_cast

DLNA / UPnP 投屏客户端：SSDP 设备发现与 AVTransport 控制。

**纯 Dart，无 Flutter 依赖。**

## 用法

```dart
import 'package:dlna_cast/dlna_cast.dart';

final discovery = DlnaDiscovery(
  logger: (level, msg) => print('[$level] $msg'),
);
final devices = await discovery.search();

final controller = DlnaController(devices.first);
await controller.setUriAndPlay('http://example.com/stream.m3u8', title: 'CCTV-1');
```

## 发现走两条腿

**多播 M-SEARCH** —— 一个包问全网段，最快。

⚠️ iOS 14+ 要求 `com.apple.developer.networking.multicast` entitlement
（需向 Apple 单独申请审批），没有它系统**直接拒发**。这正是「安卓能搜到设备、
iOS 搜不到」的根因，而且失败时若被静默吞掉，表现成「搜索正常结束、就是一台
设备都没有」，完全无从排查。

**单播 M-SEARCH** —— 逐个 IP 探 1900 端口，不需要任何多播权限。

⚠️ 它是 UPnP **1.1** 才引入的可选特性。真机取证：两台 `UPnP/1.0` 设备
（LG SmartShare、Cling/2.0）在同一网络下，多播能发现 2 台，单播 506 个包发出、
**0 个响应**。所以它**不能当多播的等价替代**，保留它是为了 UPnP 1.1 设备，
以及被路由器 IGMP snooping 挡掉多播的情况。

两条腿分开 try：多播被系统拒绝时，单播扫描照常进行。

## 安全边界

单播扫描**只在 RFC1918 私有段进行**。对蜂窝/公网地址段扫 254 个端口既发现不了
客厅电视，又会让 App 的出网流量长得像端口扫描。

扫描分批节流（每 24 个包歇 12ms），避免冲爆发送缓冲导致丢包。

## 日志

发现过程里有大量「失败了但不该中断流程」的分支：多播被拒、个别地址不可达、
设备描述拉不下来。默认丢弃，但**强烈建议接上 logger**——不写出来的话排查时
无从下手。

包不假设宿主用什么日志系统，只给一个回调。

## 测试

```bash
dart test
```

19 条测试，覆盖 M-SEARCH 报文构造（多播带 MX / 单播省略 MX）、网段推导、
私有段判定、SSDP 响应解析、SOAP 构造与响应解析。
