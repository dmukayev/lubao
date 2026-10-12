// Задача 073: понятные ошибки входа вместо «Что-то пошло не так» — логист с
// неверным паролем видит «Неверный email или пароль» под полем (поле очищено),
// водитель с неверным кодом — «Неверный код». Данные — синтетические e2e.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lubao_app/app.dart';
import 'package:lubao_app/providers/tracking_provider.dart';
import 'package:lubao_core/lubao_core.dart';

import 'e2e_support.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('073: неверный пароль логиста и неверный код водителя — понятные тексты', (tester) async {
    final run = E2eRun(binding, 'auth_errors');
    await clearPersistedSession();
    await tester.pumpWidget(ProviderScope(
      overrides: [osLocationPermissionRequestProvider.overrideWithValue(() async {})],
      child: const LubaoApp(),
    ));
    await waitFor(tester, find.byKey(const Key('roleSelectDriverButton')));
    final t = tester.element(find.byType(Scaffold).first).l10n;

    await run.step(tester, 'логист-неверный-пароль', () async {
      await tester.tap(find.byKey(const Key('roleSelectCompanyButton')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('companyLoginEmailField')), e2eCompanyEmail);
      await tester.enterText(find.byKey(const Key('companyLoginPasswordField')), 'wrong-password-1');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('companyLoginSubmitButton')));
      await waitFor(tester, find.text(t.companyLoginInvalidCredentials));
      expect(find.text(t.commonError), findsNothing);
      final field = tester.widget<TextField>(find.descendant(of: find.byKey(const Key('companyLoginPasswordField')), matching: find.byType(TextField)));
      expect(field.controller?.text, isEmpty, reason: 'поле пароля очищено');
      expectNoOverflow(tester);
    });

    await run.step(tester, 'водитель-неверный-код', () async {
      await tester.tap(find.byType(BackButton).first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('roleSelectDriverButton')));
      await tester.pumpAndSettle();
      final phone = find.byKey(const Key('driverLoginPhoneField'));
      await waitAndReveal(tester, phone);
      await tester.tap(phone);
      // Свой номер, которого нет в других сценариях: лишний запрос кода не
      // съедает часовой лимит SMS у номеров, которыми входят другие шаги.
      await tester.enterText(phone, '7010000097');
      await tester.pumpAndSettle();
      final send = find.byKey(const Key('driverLoginSendCodeButton'));
      await reveal(tester, send);
      await tester.tap(send);
      await waitFor(tester, find.byKey(const Key('driverLoginCodeDigit0')));
      const wrong = '0000';
      for (var i = 0; i < 4; i++) {
        await reveal(tester, find.byKey(Key('driverLoginCodeDigit$i')));
        await tester.enterText(find.byKey(Key('driverLoginCodeDigit$i')), wrong[i]);
        await tester.pump(const Duration(milliseconds: 300));
      }
      await waitFor(tester, find.text(t.authInvalidCode));
      expect(find.text(t.commonError), findsNothing);
      expectNoOverflow(tester);
    });
  });
}
