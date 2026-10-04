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
    await tester.pumpWidget(const ProviderScope(child: LubaoApp()));
    // Сплэш ждёт асинхронного восстановления сессии (secure storage) перед
    // переходом на role-select — одного pump() теперь недостаточно.
    await tester.pumpAndSettle();

    expect(find.text('Водитель'), findsOneWidget);
    expect(find.text('Логистическая компания'), findsOneWidget);
  });
}
