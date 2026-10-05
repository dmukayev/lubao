/// Группы событий уведомлений (задача 011, п.4) — зеркало backend-enum
/// NotificationEventGroup. Строковые значения — как их отдаёт/принимает API.
enum NotificationEventGroup {
  newCargoMatch,
  cargoInvite,
  chatMessage,
  newResponse,
  newDriverDigest,
  dealStatus,
  verification,
  agreedCheck,
}

const _eventGroupWire = {
  NotificationEventGroup.newCargoMatch: 'NEW_CARGO_MATCH',
  NotificationEventGroup.cargoInvite: 'CARGO_INVITE',
  NotificationEventGroup.chatMessage: 'CHAT_MESSAGE',
  NotificationEventGroup.newResponse: 'NEW_RESPONSE',
  NotificationEventGroup.newDriverDigest: 'NEW_DRIVER_DIGEST',
  NotificationEventGroup.dealStatus: 'DEAL_STATUS',
  NotificationEventGroup.verification: 'VERIFICATION',
  NotificationEventGroup.agreedCheck: 'AGREED_CHECK',
};

String eventGroupToWire(NotificationEventGroup group) => _eventGroupWire[group]!;

NotificationEventGroup? eventGroupFromWire(String wire) {
  for (final entry in _eventGroupWire.entries) {
    if (entry.value == wire) return entry.key;
  }
  return null;
}

class NotificationEventSetting {
  const NotificationEventSetting({required this.eventGroup, required this.enabled});

  final NotificationEventGroup eventGroup;
  final bool enabled;

  /// Null, если сервер прислал группу, которую этот клиент ещё не знает
  /// (новее бэкенда) — вызывающая сторона должна её пропустить, а не
  /// подставлять случайную группу.
  static NotificationEventSetting? tryFromJson(Map<String, dynamic> json) {
    final group = eventGroupFromWire(json['eventGroup'] as String);
    if (group == null) return null;
    return NotificationEventSetting(eventGroup: group, enabled: json['enabled'] as bool? ?? true);
  }
}
