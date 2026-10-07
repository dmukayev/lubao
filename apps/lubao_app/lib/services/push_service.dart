import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lubao_core/lubao_core.dart';

import '../providers/api_providers.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';
import '../router/app_router.dart';
import 'push_routing.dart';

/// Push включается флагом сборки (docs/release.md, раздел 5):
/// `--dart-define=PUSH_ENABLED=true` + google-services.json /
/// GoogleService-Info.plist, которых нет в репозитории. Без флага сервис
/// ничего не делает — приложение, e2e и сборка для КНР работают без Firebase.
const pushEnabled = bool.fromEnvironment('PUSH_ENABLED');

const _channelId = 'lubao_default';

/// Язык подписей кнопок: язык получателя из push (сервер пишет текст на нём),
/// иначе — язык устройства. Раньше брался только язык устройства, и на
/// английском телефоне кнопки были «Yes / No» под русским текстом.
LubaoLocalizations _deviceL10n([String? preferred]) {
  final code = preferred ?? PlatformDispatcher.instance.locale.languageCode;
  return lookupLubaoLocalizations(Locale(const {'kk', 'ru', 'zh', 'en'}.contains(code) ? code : 'ru'));
}

/// Push с кнопками приходит на Android data-only (сервер: fcmMessage) —
/// уведомление с действиями рисуем сами, и в фоне тоже.
Future<void> _showLocal(FlutterLocalNotificationsPlugin plugin, RemoteMessage message) async {
  final data = message.data;
  final title = message.notification?.title ?? data['title'] as String?;
  final body = message.notification?.body ?? data['body'] as String?;
  if (title == null && body == null) return;
  final t = _deviceL10n(data['locale'] as String?);
  final actions = pushActionsFor(data['category'] as String?, t);
  await plugin.show(
    id: message.messageId.hashCode,
    title: title,
    body: body,
    // В payload — и ссылка, и груз: кнопке «Да» у «Договорились?» нужен cargoId.
    payload: jsonEncode({'deepLink': data['deepLink'], 'cargoId': data['cargoId']}),
    notificationDetails: NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        t.pushChannelName,
        importance: Importance.high,
        priority: Priority.high,
        actions: [
          for (final (action, label) in actions) AndroidNotificationAction(pushActionId(action), label, showsUserInterface: true),
        ],
      ),
      iOS: DarwinNotificationDetails(categoryIdentifier: data['category'] as String?),
    ),
  );
}

@pragma('vm:entry-point')
Future<void> lubaoPushBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Обычные push система показывает сама; data-only (с кнопками) — мы.
  if (message.notification != null) return;
  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(settings: const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')));
  await _showLocal(plugin, message);
}

/// Push в приложении (042 п.1): токен при входе и смене, снятие при выходе,
/// разрешение — после первого осмысленного действия, тап — нужный экран,
/// кнопки «Да / Уехал», «Да / Нет».
class PushService {
  PushService(this._ref);

  final Ref _ref;
  final _plugin = FlutterLocalNotificationsPlugin();
  static const _iosActions = MethodChannel('lubao/push_actions');
  bool _ready = false;
  String? _token;

  bool get _supported => pushEnabled && !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> init() async {
    if (!_supported || _ready) return;
    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('PushService: Firebase не настроен ($e) — push выключен');
      return;
    }
    _ready = true;
    FirebaseMessaging.onBackgroundMessage(lubaoPushBackgroundHandler);
    // Кнопки iOS регистрируются один раз — на языке, выбранном в приложении.
    final t = _deviceL10n(_ref.read(localeProvider).languageCode);
    await _plugin.initialize(
      settings: InitializationSettings(
        android: const AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          // Разрешение спрашиваем сами — после первого действия, не на старте.
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
          notificationCategories: [
            for (final category in const [pushCategoryStillLooking, pushCategoryAgreed])
              DarwinNotificationCategory(category, actions: [
                for (final (action, label) in pushActionsFor(category, t))
                  DarwinNotificationAction.plain(pushActionId(action), label, options: {DarwinNotificationActionOption.foreground}),
              ]),
          ],
        ),
      ),
      onDidReceiveNotificationResponse: (r) => unawaited(_onResponse(r.actionId, r.payload)),
    );
    // Кнопки push, пришедшего напрямую через APNs (не наше локальное
    // уведомление), AppDelegate присылает сюда.
    _iosActions.setMethodCallHandler((call) async {
      if (call.method != 'action') return;
      final args = (call.arguments as Map?)?.cast<String, Object?>() ?? const {};
      await _onResponse(args['action'] as String?, args['deepLink'] as String?, cargoId: args['cargoId'] as String?);
    });
    if (Platform.isIOS) {
      // Приложение запущено нажатием кнопки — AppDelegate придержал его.
      final pending = (await _iosActions.invokeMethod<Map>('pending'))?.cast<String, Object?>();
      if (pending != null) unawaited(_onResponse(pending['action'] as String?, pending['deepLink'] as String?, cargoId: pending['cargoId'] as String?));
    }

    FirebaseMessaging.onMessage.listen((m) => unawaited(_showLocal(_plugin, m)));
    FirebaseMessaging.onMessageOpenedApp.listen((m) => _open(m.data['deepLink'] as String?));
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) _open(initial.data['deepLink'] as String?);
    final launch = await _plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      unawaited(_onResponse(launch!.notificationResponse?.actionId, launch.notificationResponse?.payload));
    }
    FirebaseMessaging.instance.onTokenRefresh.listen((token) => unawaited(_register(token)));

    _ref.read(sessionProvider.notifier).addBeforeLogout(unregister);
    _ref.listen<Session?>(sessionProvider, (previous, next) {
      if (next != null) unawaited(_registerIfAllowed());
    }, fireImmediately: true);
  }

  /// После первого отклика/анонса (042 п.1): спрашиваем разрешение и
  /// регистрируем токен. Повторные вызовы — без повторного вопроса системы.
  Future<void> requestPermissionAndRegister() async {
    if (!_ready) return;
    final settings = await FirebaseMessaging.instance.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;
    await _registerIfAllowed();
  }

  Future<void> _registerIfAllowed() async {
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      return;
    }
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) await _register(token);
  }

  Future<void> _register(String token) async {
    if (_ref.read(sessionProvider) == null) return;
    try {
      // И Android, и iOS — через FCM (APNs-ключ загружен в Firebase).
      await _ref.read(notificationsRepositoryProvider).registerDeviceToken(token, 'FCM');
      _token = token;
    } catch (e) {
      debugPrint('PushService: токен не зарегистрирован: $e');
    }
  }

  /// До выхода из аккаунта, пока ещё есть авторизация.
  Future<void> unregister() async {
    final token = _token;
    if (!_ready || token == null) return;
    try {
      await _ref.read(notificationsRepositoryProvider).unregisterDeviceToken(token);
    } catch (e) {
      debugPrint('PushService: токен не снят: $e');
    }
    _token = null;
  }

  void _open(String? deepLink) {
    if (deepLink == null || deepLink.isEmpty) return;
    final role = _ref.read(sessionProvider)?.user.role;
    _ref.read(routerProvider).push(resolvePushRoute(deepLink, role));
  }

  Future<void> _onResponse(String? actionId, String? payload, {String? cargoId}) async {
    // Наше локальное уведомление несёт JSON {deepLink, cargoId}; из AppDelegate
    // и старых уведомлений — просто ссылка.
    var deepLink = payload;
    if (payload != null && payload.startsWith('{')) {
      final map = jsonDecode(payload) as Map<String, dynamic>;
      deepLink = map['deepLink'] as String?;
      cargoId ??= map['cargoId'] as String?;
    }
    final action = pushActionFromId(actionId);
    final arrivals = _ref.read(arrivalRepositoryProvider);
    try {
      switch (action) {
        case PushAction.stillLookingYes:
          await arrivals.stillLooking();
        case PushAction.stillLookingLeft:
          await arrivals.cancel();
        case PushAction.agreedNo:
          return;
        case PushAction.agreedYes:
          // Договорились мимо кнопок (decisions.md): отклик + сигнал логисту
          // «выберите его»; сделку по-прежнему создаёт выбор логиста.
          if (cargoId != null) await _ref.read(cargoRepositoryProvider).agreed(cargoId);
          _open(deepLink);
          return;
        case null:
          _open(deepLink);
          return;
      }
      _open('/arrival');
    } catch (e) {
      debugPrint('PushService: действие $actionId не выполнено: $e');
      _open(deepLink);
    }
  }
}

final pushServiceProvider = Provider<PushService>((ref) {
  final service = PushService(ref);
  unawaited(service.init());
  return service;
});
