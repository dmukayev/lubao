import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lubao_app/app.dart';

void main() {
  // SessionController восстанавливает сессию из flutter_secure_storage на
  // старте (см. задачу 006) — без мока канала платформенный вызов 'read'
  // никогда не ответит в тестовой среде, и сплэш зависнет навсегда.
  const secureStorageChannel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      secureStorageChannel,
      (call) async => call.method == 'read' ? null : null,
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      secureStorageChannel,
      null,
    );
  });

  testWidgets('shows the role selection screen on first launch', (WidgetTester tester) async {
    // Тестовое окружение Flutter по умолчанию отдаёт системную локаль
    // en_US — после задачи 013 (en теперь поддерживается) это больше не
    // падает в ru-фолбэк, и экран реально показался бы по-английски.
    // Явно фиксируем ru, чтобы тест проверял экран, а не язык устройства.
    tester.platformDispatcher.localeTestValue = const Locale('ru');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);

    await tester.pumpWidget(const ProviderScope(child: LubaoApp()));
    // Сплэш ждёт асинхронного восстановления сессии (secure storage) перед
    // переходом на role-select — одного pump() теперь недостаточно.
    await tester.pumpAndSettle();

    expect(find.text('Водитель'), findsOneWidget);
    expect(find.text('Логистическая компания'), findsOneWidget);
  });
}
