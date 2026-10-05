import '../api/api_client.dart';
import '../models/notification_settings.dart';

class NotificationsRepository {
  NotificationsRepository(this._client);

  final ApiClient _client;

  /// Вкл/выкл по группе событий (задача 011, п.4) — в профиле.
  Future<List<NotificationEventSetting>> eventSettings() async {
    final res = await _client.dio.get('/notifications/settings');
    return (res.data as List<dynamic>)
        .map((e) => NotificationEventSetting.tryFromJson(e as Map<String, dynamic>))
        .whereType<NotificationEventSetting>()
        .toList();
  }

  Future<void> setEventSetting(NotificationEventGroup group, bool enabled) async {
    await _client.dio.patch('/notifications/settings/${eventGroupToWire(group)}', data: {'enabled': enabled});
  }

  /// Push-токен устройства (задача 011, п.2) — FCM/APNs/JPush. Реальная
  /// интеграция плагина push-уведомлений в это приложение (firebase_messaging
  /// + google-services.json/GoogleService-Info.plist/JPush-ключ) осознанно
  /// не делалась в этой задаче — нет настоящего Firebase/APNs/JPush проекта
  /// в репозитории, подключать плагин без них бессмысленно (сразу упадёт
  /// на старте или будет выдавать мусорный токен). Эндпоинт готов и
  /// покрыт backend-тестами — остаётся только вызвать его, когда появятся
  /// проекты push-провайдеров.
  Future<void> registerDeviceToken(String token, String platform) async {
    await _client.dio.post('/notifications/device-tokens', data: {'token': token, 'platform': platform});
  }
}
