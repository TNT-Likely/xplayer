class SyncPlaylist {
  final String name;
  final String url;
  final String? epgUrl;
  const SyncPlaylist({required this.name, required this.url, this.epgUrl});
  Map<String, dynamic> toJson() => {'name': name, 'url': url, 'epgUrl': epgUrl};
  factory SyncPlaylist.fromJson(Map<String, dynamic> j) => SyncPlaylist(
      name: j['name'] as String? ?? '',
      url: j['url'] as String? ?? '',
      epgUrl: j['epgUrl'] as String?);
}

class SyncProxy {
  final String hostPort;
  final bool useForUpdate;
  final bool useForSource;
  const SyncProxy(
      {required this.hostPort,
      required this.useForUpdate,
      required this.useForSource});
  Map<String, dynamic> toJson() => {
        'hostPort': hostPort,
        'useForUpdate': useForUpdate,
        'useForSource': useForSource
      };
  factory SyncProxy.fromJson(Map<String, dynamic> j) => SyncProxy(
      hostPort: j['hostPort'] as String? ?? '',
      useForUpdate: j['useForUpdate'] == true,
      useForSource: j['useForSource'] == true);
}

/// 跨设备同步的配置包。缺失类别整体省略。
class ConfigBundle {
  final int version;
  final String deviceName;
  final List<SyncPlaylist> playlists;
  final SyncProxy? proxy;
  final List<Map<String, dynamic>> favorites;
  final Map<String, dynamic> settings;

  const ConfigBundle({
    this.version = 1,
    required this.deviceName,
    this.playlists = const [],
    this.proxy,
    this.favorites = const [],
    this.settings = const {},
  });

  Map<String, dynamic> toJson() => {
        'version': version,
        'deviceName': deviceName,
        'playlists': playlists.map((p) => p.toJson()).toList(),
        if (proxy != null) 'proxy': proxy!.toJson(),
        'favorites': favorites,
        'settings': settings,
      };

  factory ConfigBundle.fromJson(Map<String, dynamic> j) => ConfigBundle(
        version: (j['version'] as num?)?.toInt() ?? 1,
        deviceName: j['deviceName'] as String? ?? 'Unknown',
        playlists: (j['playlists'] as List? ?? [])
            .map((e) => SyncPlaylist.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        proxy: j['proxy'] == null
            ? null
            : SyncProxy.fromJson(Map<String, dynamic>.from(j['proxy'])),
        favorites: (j['favorites'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e))
            .toList(),
        settings: j['settings'] == null
            ? const {}
            : Map<String, dynamic>.from(j['settings']),
      );
}
