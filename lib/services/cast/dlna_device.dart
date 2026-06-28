/// 一台 DLNA/UPnP MediaRenderer(可投屏的电视/盒子)。
class DlnaDevice {
  final String udn; // 唯一标识(uuid:...),用于去重
  final String friendlyName; // 设备友好名(展示用)
  final Uri location; // 设备描述文档 URL(SSDP LOCATION)
  final Uri controlUrl; // AVTransport 服务的控制 URL(已解析为绝对地址)

  const DlnaDevice({
    required this.udn,
    required this.friendlyName,
    required this.location,
    required this.controlUrl,
  });

  @override
  bool operator ==(Object other) => other is DlnaDevice && other.udn == udn;

  @override
  int get hashCode => udn.hashCode;

  @override
  String toString() => 'DlnaDevice($friendlyName, $controlUrl)';
}
