class Playlist {
  final int? id;
  final String name;
  final String url;

  /// @deprecated channels数据已迁移到文件存储，使用PlaylistRepository.getPlaylistChannels()读取
  @Deprecated('Use PlaylistRepository.getPlaylistChannels() instead')
  final String? channels;

  final String? epgUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Playlist({
    this.id,
    required this.name,
    required this.url,
    @Deprecated('Use PlaylistRepository.getPlaylistChannels() instead')
    this.channels,
    this.epgUrl,
    this.createdAt,
    this.updatedAt,
  });

  // 将对象转换为 Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'channels': channels,
      'epgUrl': epgUrl,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // 从 Map 转换为对象
  factory Playlist.fromMap(Map<String, dynamic> map) {
    return Playlist(
        id: map['id'],
        name: map['name'] ?? '',
        url: map['url'] ?? '',
        channels: map['channels'],
        epgUrl: map['epgUrl'],
        createdAt: map['created_at'] != null
            ? DateTime.parse(map['created_at'])
            : null,
        updatedAt: map['updated_at'] != null
            ? DateTime.parse(map['updated_at'])
            : null);
  }

  // 创建 copyWith 方法
  Playlist copyWith({
    int? id,
    String? name,
    String? url,
    String? epgUrl,
    String? channels,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      channels: channels ?? this.channels,
      epgUrl: epgUrl ?? epgUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
