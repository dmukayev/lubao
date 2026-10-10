import '../api/api_client.dart';
import '../api/device_info.dart';
import '../models/common.dart';
import '../models/session_device.dart';
import '../models/user.dart';

/// Редакция текста согласия на обработку ПДн (ARB `pdConsentBody`, политика
/// `infra/site/legal/privacy.html`) — совпадает с `PD_CONSENT_VERSION` на сервере.
const pdConsentVersion = '2026-10-08';

/// Редакция оферты для компании (`infra/site/legal/offer.html`) — совпадает с
/// `OFFER_VERSION` на сервере; принимается галочкой при регистрации компании.
const offerVersion = '2026-10-08';

class AuthRepository {
  AuthRepository(this._client);

  final ApiClient _client;

  /// Каналы кода, включённые в админке, в порядке показа (042 п.3):
  /// `whatsapp` / `telegram` / `sms`.
  Future<List<String>> driverCodeChannels() async {
    final res = await _client.dio.get('/auth/phone/channels');
    return ((res.data as Map)['channels'] as List).cast<String>();
  }

  /// 050: способы входа в порядке из админки — `telegram_bot` (вход через бота
  /// без кода) и каналы кода. Старый сервер без `methods` — только каналы кода.
  Future<List<String>> driverLoginMethods() async {
    final res = await _client.dio.get('/auth/phone/channels');
    final data = res.data as Map;
    return ((data['methods'] ?? data['channels']) as List).cast<String>();
  }

  /// 050: начать вход через бот Telegram — одноразовый nonce и ссылка t.me.
  Future<({String nonce, Uri url})> startTelegramLogin() async {
    final device = DeviceInfo.current();
    final res = await _client.dio.post('/auth/telegram/start', data: {'deviceName': device.name, 'platform': device.platform});
    final data = res.data as Map<String, dynamic>;
    return (nonce: data['nonce'] as String, url: Uri.parse(data['url'] as String));
  }

  /// 050: опрос входа через бота — `null`, пока водитель не поделился номером;
  /// 410 — ссылка устарела, 409 — уже использована (DioException наверх).
  Future<Session?> pollTelegramLogin(String nonce) async {
    final res = await _client.dio.get('/auth/telegram/$nonce');
    final data = res.data as Map<String, dynamic>;
    if (data['status'] != 'READY') return null;
    return _sessionFromTokenResponse(data);
  }

  /// Отправляет код; `channel` — куда (выбор водителя или «отправить
  /// по-другому»). Возвращает канал, куда код ушёл на самом деле: при сбое
  /// сервер берёт следующий по порядку.
  Future<String> requestDriverCode({required String phone, String? channel}) async {
    final res = await _client.dio.post('/auth/phone/request-code', data: {'phone': phone, 'channel': ?channel});
    return ((res.data as Map?)?['channel'] as String?) ?? 'sms';
  }

  /// null, если код неверный/истёк — иначе сессия (с driver==null, если это
  /// ещё не зарегистрированный водитель и анкету нужно донаполнить).
  Future<Session> verifyDriverCode({required String phone, required String code}) async {
    final device = DeviceInfo.current();
    final res = await _client.dio.post('/auth/phone/verify', data: {
      'phone': phone,
      'code': code,
      'deviceName': device.name,
      'platform': device.platform,
    });
    return _sessionFromTokenResponse(res.data as Map<String, dynamic>);
  }

  /// Вход логиста — email и пароль (задача 025, заменяет код на email из
  /// 006/022). 429/401 — та же защита, что у админа: 5 неверных попыток →
  /// блокировка на 15 минут.
  Future<Session> loginCompany({required String email, required String password}) async {
    final device = DeviceInfo.current();
    final res = await _client.dio.post('/auth/company/login', data: {
      'email': email,
      'password': password,
      'deviceName': device.name,
      'platform': device.platform,
    });
    return _sessionFromTokenResponse(res.data as Map<String, dynamic>);
  }

  /// Регистрация компании в один шаг — без предварительного входа (задача
  /// 025). 409, если email уже зарегистрирован.
  Future<Session> registerCompany({
    required String email,
    required String password,
    required String ownerName,
    required String companyName,
    String? companyNameRu,
    required String countryId,
    CompanyKind? kind,
  }) async {
    final res = await _client.dio.post('/auth/company/register', data: {
      // 058 п.8а: грузовладелец / экспедитор / перевозчик.
      if (kind != null) 'kind': kind.name.toUpperCase(),
      'email': email,
      'password': password,
      'ownerName': ownerName,
      'companyName': companyName,
      if (companyNameRu != null) 'companyNameRu': companyNameRu,
      'countryId': countryId,
      'offerVersion': offerVersion,
    });
    return _sessionFromTokenResponse(res.data as Map<String, dynamic>);
  }

  Future<void> requestPasswordReset({required String email}) async {
    await _client.dio.post('/auth/company/forgot-password', data: {'email': email});
  }

  Future<void> resetPassword({required String email, required String code, required String newPassword}) async {
    await _client.dio.post('/auth/company/reset-password', data: {
      'email': email,
      'code': code,
      'newPassword': newPassword,
    });
  }

  Future<void> resendEmailVerification() async {
    await _client.dio.post('/auth/company/resend-verification');
  }

  Future<void> verifyEmail({required String code}) async {
    await _client.dio.post('/auth/company/verify-email', data: {'code': code});
  }

  Future<CompanyInviteInfo> getInvite(String token) async {
    final res = await _client.dio.get('/companies/invites/$token');
    return CompanyInviteInfo.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Session> acceptInvite(
    String token, {
    required String password,
    required String name,
    String? phone,
    String? wechat,
  }) async {
    final res = await _client.dio.post('/auth/company/invites/$token/accept', data: {
      'password': password,
      'name': name,
      if (phone != null) 'phone': phone,
      if (wechat != null) 'wechat': wechat,
    });
    return _sessionFromTokenResponse(res.data as Map<String, dynamic>);
  }

  Future<Session> loginAdmin({required String email, required String password}) async {
    final device = DeviceInfo.current();
    final res = await _client.dio.post('/auth/admin/login', data: {
      'email': email,
      'password': password,
      'deviceName': device.name,
      'platform': device.platform,
    });
    return _sessionFromTokenResponse(res.data as Map<String, dynamic>);
  }

  /// Восстановление сессии при запуске приложения — если в secure storage
  /// есть валидный access/refresh токен, возвращает текущий профиль без
  /// повторного ввода логина/кода.
  Future<Session?> restore() async {
    final access = await _client.tokenStorage.readAccess();
    if (access == null) return null;
    try {
      final res = await _client.dio.get('/auth/me');
      return Session.fromJson(res.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    final refreshToken = await _client.tokenStorage.readRefresh();
    if (refreshToken != null) {
      try {
        await _client.dio.post('/auth/logout', data: {'refreshToken': refreshToken});
      } catch (_) {
        // лучший вариант — локальный логаут всё равно происходит
      }
    }
    await _client.logoutLocally();
  }

  /// Согласие на обработку ПДн (043 п.2) — версия текста, который показан
  /// пользователю ([pdConsentVersion]); сервер принимает только текущую.
  Future<void> acceptPdConsent() async {
    await _client.dio.post('/auth/me/pd-consent', data: {'version': pdConsentVersion});
  }

  /// Удаление аккаунта (043 п.1): сервер обезличивает ПДн и отзывает все
  /// сессии; локально — как выход. Ошибка (409 — активная сделка/сотрудники)
  /// пробрасывается, локальные токены тогда не трогаем.
  Future<void> deleteAccount() async {
    await _client.dio.delete('/auth/me');
    await _client.logoutLocally();
  }

  /// Смена языка (задача 013) — хранится на сервере (`users.locale`), не
  /// только в состоянии клиента, чтобы push/WeCom/перевод чата и выбор
  /// языка были одинаковыми на всех устройствах пользователя.
  Future<void> updateLocale(String locale) async {
    await _client.dio.patch('/auth/me/locale', data: {'locale': locale});
  }

  Future<List<DeviceSession>> listSessions() async {
    final res = await _client.dio.get('/auth/sessions');
    return (res.data as List).map((e) => DeviceSession.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> revokeSession(String id) async {
    await _client.dio.delete('/auth/sessions/$id');
  }

  Future<void> revokeAllOthers() async {
    await _client.dio.delete('/auth/sessions', queryParameters: {'except': 'current'});
  }

  Future<Session> _sessionFromTokenResponse(Map<String, dynamic> data) async {
    final accessToken = data['accessToken'] as String;
    final refreshToken = data['refreshToken'] as String;
    await _client.tokenStorage.save(accessToken, refreshToken);
    return Session.fromJson(data);
  }
}
