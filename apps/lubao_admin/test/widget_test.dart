import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lubao_admin/app.dart';

void main() {
  // SessionController восстанавливает сессию из flutter_secure_storage на
  // старте — без мока канала платформенный вызов 'read' никогда не ответит
  // в тестовой среде, и сплэш зависнет навсегда (тот же паттерн, что в
  // apps/lubao_app/test/widget_test.dart).
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

  testWidgets('shows the admin login screen on first launch', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: LubaoAdminApp()));
    // Сплэш ждёт асинхронного восстановления сессии (secure storage) перед
    // переходом на экран входа — одного pump() недостаточно.
    await tester.pumpAndSettle();

    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Пароль'), findsOneWidget);
  });
}
