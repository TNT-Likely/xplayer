// Minimal remote input protocol contracts and message types.

enum RemoteMessageType { hello, text, key, ack, error }

class RemoteMessage {
  final RemoteMessageType type;
  final Map<String, dynamic> payload;

  RemoteMessage(this.type, this.payload);

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'payload': payload,
      };

  static RemoteMessage fromJson(Map<String, dynamic> json) {
    final typeStr = (json['type'] as String?) ?? 'error';
    final type = RemoteMessageType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => RemoteMessageType.error,
    );
    return RemoteMessage(
        type, Map<String, dynamic>.from(json['payload'] ?? {}));
  }
}

class RemoteDeviceInfo {
  final String id; // uuid
  final String name; // friendly name
  final String host;
  final int port;

  RemoteDeviceInfo({
    required this.id,
    required this.name,
    required this.host,
    required this.port,
  });
}
