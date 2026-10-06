// Общие хелперы сквозных сценариев (задача 034): ожидание по реальному
// времени, сброс сессии, вход, API логиста для шагов «за кадром» и проверка
// безопасной зоны (п.17).

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lubao_app/features/shared/photo_picker.dart';
import 'package:lubao_core/lubao_core.dart';
import 'package:lubao_app/providers/api_providers.dart';

const e2eApiBase = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:3100');
/// Куда складывать скриншоты и построчный отчёт шагов (задаёт `scripts/e2e.sh`).
const e2eShotDir = String.fromEnvironment('E2E_SHOT_DIR');
const e2eDevice = String.fromEnvironment('E2E_DEVICE', defaultValue: 'device');

const e2eDevCode = '1111';
const e2eCompanyEmail = 'e2e-owner@lubao-test.cn';
const e2ePassword = 'E2eLubao2026!';

const e2eCargo1 = '11111111-1111-4111-8111-111111111001';
const e2eCargo2 = '11111111-1111-4111-8111-111111111002';
const e2eCargo3 = '11111111-1111-4111-8111-111111111003';
const e2eCargo4 = '11111111-1111-4111-8111-111111111004';

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

/// Ждём, пока виджетов станет не меньше `count`.
Future<void> waitForCount(WidgetTester tester, Finder finder, int count, {Duration timeout = const Duration(seconds: 20)}) async {
  final deadline = DateTime.now().add(timeout);
  while (finder.evaluate().length < count) {
    if (DateTime.now().isAfter(deadline)) fail('Ждали $count× $finder за $timeout, нашли ${finder.evaluate().length}');
    await tester.pump(const Duration(milliseconds: 300));
  }
  await _settle(tester);
}

/// Ждём, пока появится любой из виджетов (главная водителя: анонс или «Я на месте»).
Future<void> waitForAny(WidgetTester tester, List<Finder> finders, {Duration timeout = const Duration(seconds: 20)}) async {
  final deadline = DateTime.now().add(timeout);
  while (finders.every((f) => f.evaluate().isEmpty)) {
    if (DateTime.now().isAfter(deadline)) fail('Не нашли ни один из виджетов за $timeout: $finders');
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

  Future<List<String>> ids(String path) async {
    final res = await _dio.get(path);
    return (res.data as List).cast<Map>().map((e) => e['id'] as String).toList();
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

/// Безопасная зона (задача 034, п.17, 039 п.19): верхний контент AppBar —
/// включая кнопки справа — ниже выреза/строки статуса; нижняя навигация,
/// поле чата и закреплённые кнопки нижних шторок — выше полоски «домой».
void expectInsideSafeZone(WidgetTester tester) {
  final view = tester.view;
  final padding = MediaQueryData.fromView(view).padding;
  final height = view.physicalSize.height / view.devicePixelRatio;
  final bottomLimit = height - padding.bottom + 0.5;

  final appBar = find.byType(AppBar);
  if (appBar.evaluate().isNotEmpty) {
    final interactive = [
      find.descendant(of: appBar, matching: find.byType(Text)),
      find.descendant(of: appBar, matching: find.byType(IconButton)),
      find.descendant(of: appBar, matching: find.byType(ButtonStyleButton)),
    ];
    for (final finder in interactive) {
      for (var i = 0; i < finder.evaluate().length; i++) {
        final top = tester.getTopLeft(finder.at(i)).dy;
        expect(top, greaterThanOrEqualTo(padding.top - 0.5), reason: 'элемент AppBar заезжает под вырез/строку статуса: ${finder.at(i)}');
      }
    }
  }
  final nav = find.byType(NavigationBar);
  if (nav.evaluate().isNotEmpty) {
    final icon = find.descendant(of: nav, matching: find.byType(Icon)).first;
    expect(tester.getBottomLeft(icon).dy, lessThanOrEqualTo(bottomLimit), reason: 'иконки навигации заезжают под «домой»');
  }
  final send = find.byKey(const Key('chatSendButton'));
  if (send.evaluate().isNotEmpty) {
    expect(tester.getBottomLeft(send).dy, lessThanOrEqualTo(bottomLimit), reason: 'поле ввода чата заезжает под «домой»');
  }
  // Нижние шторки: закреплённые кнопки и окно прокрутки — выше «домой».
  final sheets = find.byType(BottomSheet);
  for (var s = 0; s < sheets.evaluate().length; s++) {
    final sheet = sheets.at(s);
    for (final finder in [
      find.descendant(of: sheet, matching: find.byType(ButtonStyleButton)),
      find.descendant(of: sheet, matching: find.byType(Scrollable)),
    ]) {
      for (var i = 0; i < finder.evaluate().length; i++) {
        final box = tester.getRect(finder.at(i));
        if (box.top >= height) continue;
        expect(box.bottom, lessThanOrEqualTo(bottomLimit), reason: 'нижняя шторка заезжает под «домой»: ${finder.at(i)}');
      }
    }
  }
}

/// Бросает, если на экране красная полоса переполнения (RenderFlex).
void expectNoOverflow(WidgetTester tester) {
  final error = tester.takeException();
  if (error is FlutterError) debugPrint('E2E: ${error.toStringDeep()}');
  expect(error, isNull, reason: 'исключение/переполнение на экране: $error');
}




/// Шаги сценария со скриншотом после каждого (задача 034, п.3) и при падении
/// — ДО завершения приложения, прямо из теста. Построчный отчёт —
/// `<E2E_SHOT_DIR>/<устройство>/steps.jsonl` (собирается в report.md).
class E2eRun {
  E2eRun(this.binding, this.scenario);

  final IntegrationTestWidgetsFlutterBinding binding;
  final String scenario;
  int _n = 0;

  String get _dir => '$e2eShotDir/$e2eDevice/$scenario';

  Future<void> step(WidgetTester tester, String name, Future<void> Function() body) async {
    _n++;
    final id = '${_n.toString().padLeft(2, '0')}-$name';
    try {
      await body();
      // Любое необработанное исключение кадра (переполнение и т. п.) за шаг —
      // это падение именно этого шага.
      final pending = tester.takeException();
      if (pending != null) {
        debugPrint('E2E: исключение в шаге $id: ${pending is FlutterError ? pending.toStringDeep() : pending}');
        fail('исключение/переполнение на экране в шаге $id: ${pending is FlutterError ? pending.message : pending}');
      }
    } catch (error) {
      final shot = await _shoot(tester, '$id-FAIL');
      _record(id, ok: false, shot: shot, error: error.toString().split('\n').take(3).join(' '));
      rethrow;
    }
    _record(id, ok: true, shot: await _shoot(tester, id));
  }

  Future<String?> _shoot(WidgetTester tester, String name) async {
    if (e2eShotDir.isEmpty) return null;
    try {
      await tester.pump(const Duration(milliseconds: 200));
      final bytes = await binding.takeScreenshot('$scenario-$name');
      final file = File('$_dir/$name.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);
      return file.path;
    } catch (e) {
      debugPrint('E2E: скриншот $name не снят: $e');
      return null;
    }
  }

  void _record(String id, {required bool ok, String? shot, String? error}) {
    if (e2eShotDir.isEmpty) return;
    final file = File('$e2eShotDir/$e2eDevice/steps.jsonl');
    file.parent.createSync(recursive: true);
    file.writeAsStringSync(
      '${jsonEncode({'scenario': scenario, 'step': id, 'ok': ok, 'shot': shot, 'error': error})}\n',
      mode: FileMode.append,
    );
  }
}


/// Вкладка нижней навигации по подписи.
Future<void> goTab(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(of: find.byType(NavigationBar), matching: find.text(label)));
  await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 5)).catchError((_) => 0);
}

/// Выход из аккаунта через «Профиль» (водитель или логист).
Future<void> logoutViaProfile(WidgetTester tester, {required bool driver}) async {
  final t = tester.element(find.byType(Scaffold).first).l10n;
  await goTab(tester, t.profileTitle);
  final key = Key(driver ? 'driverProfileLogoutButton' : 'companyProfileLogoutButton');
  await waitFor(tester, find.byType(Scrollable));
  await reveal(tester, find.byKey(key));
  await tester.tap(find.byKey(key));
  await waitFor(tester, find.byKey(const Key('roleSelectDriverButton')));
}


/// Синтетический «документ»: белый лист с крупным текстом — Tesseract читает
/// его так же, как фото техпаспорта. Только выдуманные данные.
Future<XFile> makeSyntheticDocument(String fileName, List<String> lines) async {
  const width = 1400.0;
  final height = 140.0 + lines.length * 110.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));
  canvas.drawRect(Rect.fromLTWH(0, 0, width, height), Paint()..color = Colors.white);
  var y = 60.0;
  for (final line in lines) {
    final painter = TextPainter(
      text: TextSpan(text: line, style: const TextStyle(color: Colors.black, fontSize: 64, fontFamily: 'Onest')),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width - 120);
    painter.paint(canvas, Offset(60, y));
    y += 110;
  }
  final image = await recorder.endRecording().toImage(width.toInt(), height.toInt());
  final data = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File('${Directory.systemTemp.path}/$fileName');
  await file.writeAsBytes(data!.buffer.asUint8List());
  if (e2eShotDir.isNotEmpty) {
    final copy = File('$e2eShotDir/$e2eDevice/documents/$fileName');
    await copy.parent.create(recursive: true);
    await copy.writeAsBytes(data.buffer.asUint8List());
  }
  return XFile(file.path, name: fileName);
}

/// Подставляет синтетический документ вместо системной камеры/галереи.
void usePhoto(XFile photo) {
  debugPhotoPicker = (source) async => photo;
  addTearDown(() => debugPhotoPicker = null);
}


/// Водитель «за кадром» (отклик на груз новой компании) — тот же публичный
/// API, что использует приложение водителя.
class DriverApi {
  DriverApi._(this._dio);
  final Dio _dio;

  static Future<DriverApi> login(String phone) async {
    final dio = Dio(BaseOptions(baseUrl: e2eApiBase, validateStatus: (_) => true));
    await dio.post('/auth/phone/request-code', data: {'phone': phone});
    final res = await dio.post('/auth/phone/verify', data: {'phone': phone, 'code': e2eDevCode, 'deviceName': 'e2e', 'platform': 'ios'});
    if (res.statusCode! >= 300) fail('Вход водителя через API не удался: ${res.statusCode} ${res.data}');
    dio.options.headers['Authorization'] = 'Bearer ${(res.data as Map)['accessToken']}';
    return DriverApi._(dio);
  }

  Future<void> respond(String cargoId) async {
    final res = await _dio.post('/cargos/$cargoId/responses', data: {});
    if (res.statusCode! >= 300) fail('Отклик водителя через API не удался: ${res.statusCode} ${res.data}');
  }
}


/// Показывает виджет: если он ещё не построен (ленивый список) — прокручивает
/// самую большую вертикальную прокрутку экрана, затем `ensureVisible`.
Future<void> reveal(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    Finder? best;
    var bestArea = 0.0;
    // Открытая нижняя шторка — прокручиваем её, а не страницу под ней.
    final sheet = find.byType(BottomSheet);
    final all = sheet.evaluate().isNotEmpty ? find.descendant(of: sheet.last, matching: find.byType(Scrollable)) : find.byType(Scrollable);
    for (var i = 0; i < all.evaluate().length; i++) {
      final candidate = all.at(i);
      final widget = tester.widget<Scrollable>(candidate);
      if (widget.axis != Axis.vertical) continue;
      final size = tester.getSize(candidate);
      if (size.width * size.height > bestArea) {
        bestArea = size.width * size.height;
        best = candidate;
      }
    }
    if (best == null) fail('Нет вертикальной прокрутки, чтобы найти $finder');
    await tester.scrollUntilVisible(finder, 200, scrollable: best);
  }
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle(const Duration(milliseconds: 100), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 3)).catchError((_) => 0);
}
