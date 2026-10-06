// Общие хелперы сквозных сценариев (задача 034): ожидание по реальному
// времени, сброс сессии, вход, API логиста для шагов «за кадром» и проверка
// безопасной зоны (п.17).

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubao_app/providers/api_providers.dart';

const e2eApiBase = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:3100');
const e2eDevCode = '1111';
const e2eCompanyEmail = 'e2e-owner@lubao-test.cn';
const e2ePassword = 'E2eLubao2026!';

const e2eCargo1 = '11111111-1111-4111-8111-111111111001';
const e2eCargo2 = '11111111-1111-4111-8111-111111111002';
const e2eCargo3 = '11111111-1111-4111-8111-111111111003';

/// Ждём виджет реальным временем, а не кадрами: первый сетевой запрос
/// (сессия, справочники) может идти дольше, чем `pumpAndSettle` считает
/// «успокоившимся». По истечении — понятная ошибка с тем, что видно на экране.
Future<void> waitFor(WidgetTester tester, Finder finder, {Duration timeout = const Duration(seconds: 20)}) async {
  final deadline = DateTime.now().add(timeout);
  while (finder.evaluate().isEmpty) {
    if (DateTime.now().isAfter(deadline)) {
      final texts = find.byType(Text).evaluate().map((e) => (e.widget as Text).data).whereType<String>().take(20).toList();
      fail('Не нашли виджет за $timeout: $finder. На экране: $texts');
    }
    await tester.pump(const Duration(milliseconds: 300));
  }
  await _settle(tester);
}

/// `pumpAndSettle` падает по таймауту, если на экране вечная анимация
/// (индикатор загрузки, пульсация) — для сквозных сценариев это не ошибка:
/// достаточно нескольких кадров.
Future<void> _settle(WidgetTester tester) async {
  try {
    await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5));
  } catch (_) {
    await tester.pump(const Duration(milliseconds: 500));
  }
}

/// Сессия живёт в Keychain и переживает `simctl uninstall` — чистим токены
/// ДО сборки приложения (реальный TokenStorage, не фейк).
Future<void> clearPersistedSession() async {
  final container = ProviderContainer();
  try {
    await container.read(authRepositoryProvider).logout();
  } catch (_) {
    // нет сети/токена — важно лишь, что tokenStorage.clear() выполнился
  } finally {
    container.dispose();
  }
}

/// Роль «водитель» → телефон → код 1111 → ждём главного экрана (кнопка
/// анонса или «Я на месте»).
Future<void> loginDriver(WidgetTester tester, String phoneLocal) async {
  await waitFor(tester, find.byKey(const Key('roleSelectDriverButton')));
  await tester.tap(find.byKey(const Key('roleSelectDriverButton')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('driverLoginPhoneField')), phoneLocal);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('driverLoginSendCodeButton')));
  await waitFor(tester, find.byKey(const Key('driverLoginCodeDigit0')));
  for (var i = 0; i < 4; i++) {
    await tester.enterText(find.byKey(Key('driverLoginCodeDigit$i')), e2eDevCode[i]);
    await tester.pump(const Duration(milliseconds: 300));
  }
}

/// Роль «компания» → email + пароль → вход логиста.
Future<void> loginLogist(WidgetTester tester) async {
  await waitFor(tester, find.byKey(const Key('roleSelectCompanyButton')));
  await tester.tap(find.byKey(const Key('roleSelectCompanyButton')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('companyLoginEmailField')), e2eCompanyEmail);
  await tester.enterText(find.byKey(const Key('companyLoginPasswordField')), e2ePassword);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('companyLoginSubmitButton')));
}

/// Шаги «за кадром» от имени логиста (выбор водителя из откликов) — тот же
/// публичный API, что использует приложение логиста.
class LogistApi {
  LogistApi._(this._dio);
  final Dio _dio;

  static Future<LogistApi> login() async {
    final dio = Dio(BaseOptions(baseUrl: e2eApiBase, validateStatus: (_) => true));
    final res = await dio.post('/auth/company/login', data: {
      'email': e2eCompanyEmail,
      'password': e2ePassword,
      'deviceName': 'e2e',
      'platform': 'ios',
    });
    final token = (res.data as Map)['accessToken'] as String;
    dio.options.headers['Authorization'] = 'Bearer $token';
    return LogistApi._(dio);
  }

  /// Ждёт отклик на груз (запись на сервере появляется асинхронно) и
  /// выбирает этого водителя; возвращает id сделки.
  Future<String> selectFirstResponse(String cargoId) async {
    final deadline = DateTime.now().add(const Duration(seconds: 20));
    while (true) {
      final res = await _dio.get('/cargos/$cargoId/responses');
      final list = (res.data as List).cast<Map>();
      final pending = list.where((r) => r['status'] == 'PENDING');
      if (pending.isNotEmpty) {
        final sel = await _dio.patch('/responses/${pending.first['id']}', data: {'status': 'SELECTED'});
        if (sel.statusCode! >= 300) fail('Выбор водителя не удался: ${sel.statusCode} ${sel.data}');
        break;
      }
      if (DateTime.now().isAfter(deadline)) fail('Отклик на груз $cargoId так и не появился');
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    final deals = (await _dio.get('/deals/mine')).data as List;
    return (deals.cast<Map>().firstWhere((d) => d['cargoId'] == cargoId && d['status'] != 'CANCELLED'))['id'] as String;
  }
}

/// Безопасная зона (задача 034, п.17): верхний контент AppBar ниже выреза/
/// строки статуса, нижняя навигация и поле ввода — выше полоски «домой».
void expectInsideSafeZone(WidgetTester tester) {
  final view = tester.view;
  final padding = MediaQueryData.fromView(view).padding;
  final height = view.physicalSize.height / view.devicePixelRatio;

  final appBarTexts = find.descendant(of: find.byType(AppBar), matching: find.byType(Text));
  if (appBarTexts.evaluate().isNotEmpty) {
    final top = tester.getTopLeft(appBarTexts.first).dy;
    expect(top, greaterThanOrEqualTo(padding.top - 0.5), reason: 'заголовок AppBar заезжает под вырез/строку статуса');
  }
  final nav = find.byType(NavigationBar);
  if (nav.evaluate().isNotEmpty) {
    final icon = find.descendant(of: nav, matching: find.byType(Icon)).first;
    expect(tester.getBottomLeft(icon).dy, lessThanOrEqualTo(height - padding.bottom + 0.5), reason: 'иконки навигации заезжают под «домой»');
  }
  final send = find.byKey(const Key('chatSendButton'));
  if (send.evaluate().isNotEmpty) {
    expect(tester.getBottomLeft(send).dy, lessThanOrEqualTo(height - padding.bottom + 0.5), reason: 'поле ввода чата заезжает под «домой»');
  }
}

/// Бросает, если на экране красная полоса переполнения (RenderFlex).
void expectNoOverflow(WidgetTester tester) {
  final error = tester.takeException();
  expect(error, isNull, reason: 'исключение/переполнение на экране: $error');
}


