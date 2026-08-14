/// DLNA / UPnP 投屏客户端。
///
/// 自写的最小实现，覆盖投屏所需的全部环节：SSDP 设备发现、设备描述解析、
/// AVTransport 控制（播放 / 暂停 / 停止 / 音量 / 进度查询）。
///
/// **纯 Dart，无 Flutter 依赖。**
///
/// ## 发现走两条腿
///
/// - **多播 M-SEARCH**：一个包问全网段，最快。但 iOS 14+ 要求
///   `com.apple.developer.networking.multicast` entitlement（需向 Apple
///   单独申请），没有它系统直接拒发——这正是「安卓能搜到设备、iOS 搜不到」
///   的根因。
/// - **单播 M-SEARCH**：逐个 IP 探 1900 端口，不需要任何多播权限。
///   ⚠️ 它是 UPnP **1.1** 才引入的可选特性，实测对 `UPnP/1.0` 的老电视
///   （LG SmartShare、Cling/2.0）**0 响应**，不能当多播的等价替代。
///   保留它是为了 UPnP 1.1 设备，以及被路由器 IGMP snooping 挡掉多播的情况。
///
/// 两条腿分开 try：多播被系统拒绝时，单播扫描照常进行。
///
/// ## 安全边界
///
/// 单播扫描只在 RFC1918 私有段进行。对蜂窝/公网地址段扫 254 个端口既发现不了
/// 客厅电视，又会让出网流量长得像端口扫描。
///
/// ## 日志
///
/// 发现过程中有大量「失败了但不该中断流程」的分支。默认丢弃，
/// 但强烈建议接上 [CastLogger]——不写出来的话，排查时只剩
/// 「搜索正常结束、一台设备都没有」，完全无从下手。
///
/// ```dart
/// final discovery = DlnaDiscovery(
///   logger: (level, msg) => print('[$level] $msg'),
/// );
/// final devices = await discovery.search();
/// ```
library dlna_cast;

export 'src/cast_logger.dart';
export 'src/dlna_controller.dart';
export 'src/dlna_device.dart';
export 'src/dlna_discovery.dart';
export 'src/dlna_xml.dart';
