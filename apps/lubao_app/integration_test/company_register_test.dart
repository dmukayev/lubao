// Задача 034, сценарий 8: регистрация компании (email + пароль) → баннер
// «Публикация откроется после проверки» → загрузка синтетического
// свидетельства → «на проверке» → публикация груза заблокирована.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lubao_app/app.dart';
import 'package:lubao_core/lubao_core.dart';

import 'e2e_support.dart';

const e2eNewCompanyEmail = 'e2e-new-logist@lubao-test.cn';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('логист: регистрация компании → баннер → свидетельство → публикация заблокирована', (tester) async {
    final run = E2eRun(binding, 'company_register');
    await clearPersistedSession();
    await tester.pumpWidget(const ProviderScope(child: LubaoApp()));
    await waitFor(tester, find.byKey(const Key('roleSelectCompanyButton')));
    final t = tester.element(find.byType(Scaffold).first).l10n;

    await run.step(tester, 'форма-регистрации', () async {
      await tester.tap(find.byKey(const Key('roleSelectCompanyButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('companyLoginRegisterLink')));
      await waitFor(tester, find.byKey(const Key('companyRegisterEmail')));
      expectInsideSafeZone(tester);
      // Каждое поле — сначала на экран (форма длиннее экрана 16e/17 с
      // клавиатурой; без этого поле ещё не построено и ввод падает).
      for (final (key, value) in [
        ('companyRegisterEmail', e2eNewCompanyEmail),
        ('companyRegisterPassword', e2ePassword),
        ('companyRegisterOwnerName', 'Ли Вэй'),
        ('companyRegisterCompanyName', 'Urumqi Test Logistics'),
      ]) {
        final field = find.byKey(Key(key));
        await reveal(tester, field);
        await tester.enterText(field, value);
        await tester.pumpAndSettle();
      }
      final china = find.byKey(const Key('companyRegisterCountryCN'));
      await reveal(tester, china);
      await tester.tap(china);
      await tester.pumpAndSettle();
    });

    await run.step(tester, 'отправка-регистрации', () async {
      final submit = find.byKey(const Key('companyRegisterSubmit'));
      await reveal(tester, submit);
      await tester.tap(submit);
      await waitFor(tester, find.text(t.navDrivers));
      expectInsideSafeZone(tester);
    });

    await run.step(tester, 'баннер-в-профиле', () async {
      await goTab(tester, t.profileTitle);
      await waitFor(tester, find.byKey(const Key('companyNotVerifiedBanner')));
      expect(find.text(t.companyNotVerifiedBannerText), findsOneWidget);
      expectNoOverflow(tester);
    });

    await run.step(tester, 'загрузка-свидетельства', () async {
      final photo = await makeSyntheticDocument('company-registration.png', [
        'BUSINESS LICENSE',
        'Urumqi Test Logistics',
        'USCC 91110000MA01ABCD2Q',
      ]);
      usePhoto(photo);
      final gallery = find.byKey(const Key('companyVerificationGallery'));
      await reveal(tester, gallery);
      await tester.tap(gallery);
      // 043 п.2: новая компания — согласие на ПДн перед первой загрузкой.
      await acceptPdConsent(tester);
      await waitFor(tester, find.text(t.companyVerificationStatusPending));
    });

    await run.step(tester, 'публикация-заблокирована', () async {
      await goTab(tester, t.navCargos);
      await waitFor(tester, find.byKey(const Key('companyPostCargoFab')));
      await tester.tap(find.byKey(const Key('companyPostCargoFab')));
      await waitFor(tester, find.byKey(const Key('postCargoVerificationBanner')));
      final submit = find.byKey(const Key('postCargoSubmit'));
      await reveal(tester, submit);
      final button = tester.widget<PrimaryButton>(submit);
      expect(button.onPressed, isNull, reason: 'кнопка «Опубликовать» должна быть заблокирована у непроверенной компании');
      expectInsideSafeZone(tester);
    });
  });
}
