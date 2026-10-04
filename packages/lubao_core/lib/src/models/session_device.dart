class DeviceSession {
  const DeviceSession({
    required this.id,
    required this.deviceName,
    required this.platform,
    required this.createdAt,
    required this.lastUsedAt,
    required this.isCurrent,
  });

  final String id;
  final String? deviceName;
  final String? platform;
  final DateTime createdAt;
  final DateTime lastUsedAt;
  final bool isCurrent;

  factory DeviceSession.fromJson(Map<String, dynamic> json) => DeviceSession(
        id: json['id'] as String,
        deviceName: json['deviceName'] as String?,
        platform: json['platform'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        lastUsedAt: DateTime.parse(json['lastUsedAt'] as String),
        isCurrent: json['isCurrent'] as bool,
      );
}
