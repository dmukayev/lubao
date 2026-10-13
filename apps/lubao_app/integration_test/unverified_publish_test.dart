// Задача 066: новая компания публикует груз сразу после регистрации, без
// проверки и документов; 11-й активный груз упирается в лимит («Пройти
// проверку»); у водителя в ленте — «Не проверена» и «Проверена». Данные —
// синтетические e2e; в конце грузы компании снимаются, чтобы не менять ленту
// следующим сценариям.
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lubao_app/app.dart';
import 'package:lubao_app/providers/auth_provider.dart';
import 'package:lubao_app/providers/data_providers.dart';
import 'package:lubao_core/lubao_core.dart';

import 'e2e_support.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('066/069: китайская компания с латинским названием публикует без проверки, лимит 10, плашки у водителя', (tester) async {
    final run = E2eRun(binding, 'unverified_publish');
    final email = 'e2e-066-${DateTime.now().millisecondsSinceEpoch}@lubao-test.kz';
    const chineseName = '霍尔果斯瑞达贸易有限公司';
    const latinName = 'Horgos Ruida Trading Co., Ltd.';

    await clearPersistedSession();
    await tester.pumpWidget(const ProviderScope(child: LubaoApp()));
    await waitFor(tester, find.byKey(const Key('roleSelectCompanyButton')));
    final t = tester.element(find.byType(Scaffold).first).l10n;
    final container = ProviderScope.containerOf(tester.element(find.byType(LubaoApp)));

    // 069: китайское название → поле «Название латиницей» с пиньинем (сервер,
    // локальная библиотека); кириллица/латиница — поля нет.
    await run.step(tester, 'регистрация-китайское-название-латиница', () async {
      await tester.tap(find.byKey(const Key('roleSelectCompanyButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('companyLoginRegisterLink')));
      await waitFor(tester, find.byKey(const Key('companyRegisterEmail')));
      for (final (key, value) in [
        ('companyRegisterEmail', email),
        ('companyRegisterPassword', e2ePassword),
        ('companyRegisterOwnerName', 'Ли Вэй'),
        ('companyRegisterCompanyName', 'Ruida Test'),
      ]) {
        final field = find.byKey(Key(key));
        await reveal(tester, field);
        await tester.enterText(field, value);
        await tester.pumpAndSettle();
      }
      expect(find.byKey(const Key('companyRegisterCompanyNameLatin')), findsNothing, reason: 'латинское название — поля нет');
      final name = find.byKey(const Key('companyRegisterCompanyName'));
      await tester.enterText(name, chineseName);
      await tester.pumpAndSettle();
      final latin = find.byKey(const Key('companyRegisterCompanyNameLatin'));
      await waitAndReveal(tester, latin);
      await waitForCondition(tester, () => find.descendant(of: latin, matching: find.text(latinName)).evaluate().isNotEmpty, timeout: const Duration(seconds: 15));
      expect(find.text(t.companyRegisterLatinHint), findsOneWidget);
      final china = find.byKey(const Key('companyRegisterCountryCN'));
      await reveal(tester, china);
      await tester.tap(china);
      await tester.pumpAndSettle();
      final offer = find.byKey(const Key('companyRegisterOfferCheckbox'));
      await reveal(tester, offer);
      await tester.tap(offer);
      await tester.pumpAndSettle();
      expectNoOverflow(tester);
    });

    await run.step(tester, 'регистрация-отправка', () async {
      final submit = find.byKey(const Key('companyRegisterSubmit'));
      await reveal(tester, submit);
      await tester.tap(submit);
      await waitFor(tester, find.text(t.navDrivers));
      final company = container.read(sessionProvider)?.company;
      expect(company?.name, chineseName);
      expect(company?.nameLatin, latinName);
    });

    final dio = Dio(BaseOptions(baseUrl: e2eApiBase, connectTimeout: e2eHttpTimeout, receiveTimeout: e2eHttpTimeout, validateStatus: (_) => true));
    final login = await dio.post('/auth/company/login', data: {'email': email, 'password': e2ePassword, 'deviceName': 'e2e', 'platform': 'ios'});
    expect(login.statusCode, lessThan(300), reason: 'вход компании через API: ${login.data}');
    final companyApi = Dio(BaseOptions(
      baseUrl: e2eApiBase,
      connectTimeout: e2eHttpTimeout,
      receiveTimeout: e2eHttpTimeout,
      validateStatus: (_) => true,
      headers: {'Authorization': 'Bearer ${(login.data as Map)['accessToken']}'},
    ));

    late String cargoId;
    await run.step(tester, 'публикация-без-проверки', () async {
      await goTab(tester, t.navCargos);
      await tester.tap(find.byKey(const Key('companyPostCargoFab')));
      await waitFor(tester, find.byKey(const Key('postCargoPickupCity')));
      expect(find.byKey(const Key('postCargoVerificationBanner')), findsNothing, reason: '066: проверка для публикации не нужна');
      await tester.tap(find.byKey(const Key('postCargoPickupCity')));
      await pickCityByName(tester, 'Almaty', 'Алматы');
      await tester.enterText(find.byKey(const Key('postCargoDestination')), 'Астана');
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Астана').last);
      await tester.pumpAndSettle();
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      final category = find.byKey(const Key('postCargoCategory-CONSTRUCTION'));
      await reveal(tester, category);
      await tester.tap(category);
      await tester.pumpAndSettle();
      await reveal(tester, find.byKey(const Key('postCargoBodyType')));
      await tester.tap(find.byKey(const Key('postCargoBodyType')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Тентованный').last);
      await tester.pumpAndSettle();
      // 072: цена не заполнена (внизу формы) → «Опубликовать» → экран к цене,
      // под ней ошибка, в поле фокус.
      final publish = find.byKey(const Key('postCargoSubmit'));
      await reveal(tester, publish);
      await tester.tap(publish);
      await tester.pumpAndSettle();
      expectFieldShownWithError(tester, const Key('postCargoPrice'));
      final price = find.byKey(const Key('postCargoPrice'));
      await reveal(tester, price);
      await tester.enterText(price, '900');
      await tester.pumpAndSettle();
      final phone = find.byKey(const Key('postCargoContactPhone'));
      await reveal(tester, phone);
      await tester.enterText(phone, '+86 138 0000 0084');
      await tester.pumpAndSettle();
      final submit = find.byKey(const Key('postCargoSubmit'));
      await reveal(tester, submit);
      expect(tester.widget<PrimaryButton>(submit).onPressed, isNotNull, reason: 'кнопка «Опубликовать» активна у непроверенной компании');
      await tester.tap(submit);
      await waitFor(tester, find.byKey(const Key('companyPostCargoFab')));
      final cargos = await container.read(myCargosProvider.future);
      expect(cargos, hasLength(1));
      expect(cargos.single.companyIsVerified, isFalse);
      cargoId = cargos.single.id;
      await waitAndReveal(tester, find.byKey(Key('companyCargoCard-$cargoId')));
      expectNoOverflow(tester);
    });

    // Ещё 9 — через API (форма уже проверена выше); 11-й — «Повторить» в приложении.
    await run.step(tester, 'одиннадцатый-груз-лимит', () async {
      final cargo = (await companyApi.get('/cargos/$cargoId')).data as Map;
      for (var i = 2; i <= 10; i++) {
        final res = await companyApi.post('/cargos', data: {
          'pointId': cargo['pointId'],
          'destinationCountryId': cargo['destinationCountryId'],
          'destinationCityId': cargo['destinationCityId'],
          'bodyTypeId': cargo['bodyTypeId'],
          'categoryId': cargo['categoryId'],
          'price': 900 + i,
          'currency': 'USD',
          'readyDate': cargo['readyDate'],
        });
        expect(res.statusCode, lessThan(300), reason: 'груз $i из 10: ${res.data}');
      }
      final repeat = find.byKey(Key('cargoRepeat-$cargoId'));
      await waitAndReveal(tester, repeat);
      await tester.tap(repeat);
      await waitFor(tester, find.byKey(const Key('postCargoDestination')));
      final submit = find.byKey(const Key('postCargoSubmit'));
      await reveal(tester, submit);
      await tester.tap(submit);
      await waitFor(tester, find.byKey(const Key('postCargoLimitDialog')));
      expect(find.text(t.errCompanyActiveLimit), findsOneWidget);
      expectNoOverflow(tester);
      await tester.tap(find.byKey(const Key('postCargoGoVerify')));
      await waitFor(tester, find.byKey(const Key('companyNotVerifiedBanner')));
      expect(find.text(t.preVerifyCompanyCan), findsOneWidget);
      expectInsideSafeZone(tester);
    });

    // 067: непроверенная компания видит карточку водителя целиком — фото
    // водителя, фото машины, «Позвонить». D4 стоит в Хоргосе (D3 к этому
    // моменту уже в рейсе); фото — синтетические, через API.
    await run.step(tester, 'карточка-водителя-без-проверки', () async {
      const d4 = 'dddddddd-dddd-4ddd-8ddd-ddddddddd004';
      await vehiclePhotoViaApi('7010000004', 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaa004', withAvatar: true);
      await goTab(tester, t.navDrivers);
      await waitFor(tester, find.byKey(const Key('driversPointChip')));
      await tester.tap(find.byKey(const Key('driversPointChip')));
      await pickCityByName(tester, 'korg', 'Хоргос');
      // 071 п.4: логист приглашает водителя на свой груз — в строке «Приглашён: …».
      final invite = find.byKey(const Key('driversAtPointInvite-$d4'));
      await waitAndReveal(tester, invite);
      await tester.tap(invite);
      final option = find.byKey(Key('inviteCargo-$cargoId'));
      await waitAndReveal(tester, option);
      await tester.tap(option);
      await tester.pumpAndSettle();
      final submit = find.byKey(const Key('inviteCargoSubmit'));
      await reveal(tester, submit);
      await tester.tap(submit);
      await waitAndReveal(tester, find.byKey(const Key('driverInvited-$d4')));
      expectNoOverflow(tester);
      await openDriverCardByRow(tester, const Key('driversAtPointCard-$d4'));
      await waitFor(tester, find.descendant(of: find.byKey(const Key('driverCard')), matching: find.byKey(const Key('driverAvatar-$d4-photo'))), timeout: const Duration(seconds: 30));
      final photo = find.byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('driverVehiclePhoto-'));
      await waitAndReveal(tester, photo, timeout: const Duration(seconds: 30));
      expect(find.byKey(const Key('driverVehiclePhotosUnavailable')), findsNothing, reason: 'фото машины без проверки компании');
      await waitAndReveal(tester, find.byKey(const Key('driverCardCall')));
      expectNoOverflow(tester);
    });

    // Снимок выше — шторка открыта; здесь ✕ закрывает её.
    await run.step(tester, 'карточка-водителя-крестик', () async {
      await tester.tap(find.byKey(const Key('driverCardClose')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('driverCard')), findsNothing);
    });

    // 071: логист открывает свой груз — фото, описание, условия, «Отклики»,
    // блок «Приглашены» с водителем; в списке «Приглашено: 1».
    await run.step(tester, 'полная-карточка-груза-логиста', () async {
      final image = await makeSyntheticDocument('cargo-photo.png', ['SYNTHETIC CARGO', 'TILES', 'E2E']);
      final upload = await companyApi.post('/uploads/image', data: FormData.fromMap({'file': MultipartFile.fromBytes(await image.readAsBytes(), filename: 'cargo-photo.png')}));
      expect(upload.statusCode, lessThan(300), reason: 'загрузка фото груза: ${upload.data}');
      final patched = await companyApi.patch('/cargos/$cargoId', data: {
        'photoUrls': [(upload.data as Map)['url']],
        'description': 'Плитка в коробках, грузить аккуратно',
        'paymentForm': 'CASH',
        'paymentDelayDays': 5,
      });
      expect(patched.statusCode, lessThan(300), reason: 'фото и описание груза: ${patched.data}');
      await goTab(tester, t.navCargos);
      final container = ProviderScope.containerOf(tester.element(find.byType(LubaoApp)));
      container.invalidate(myCargosProvider);
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 600));
      await tester.pumpAndSettle();
      final line = find.byKey(Key('cargoResponsesLine-$cargoId'));
      await waitAndReveal(tester, line);
      await waitFor(tester, find.byKey(Key('cargoInvitedCount-$cargoId')));
      await tester.tap(find.byKey(Key('companyCargoCard-$cargoId')));
      await waitFor(tester, find.byKey(const Key('companyCargoDetail')));
      await waitFor(tester, find.byKey(const Key('cargoPhoto-0')));
      expect(find.byKey(Key('cargoDetailTerms-$cargoId')), findsOneWidget, reason: 'условия оплаты');
      await waitAndReveal(tester, find.byKey(const Key('companyCargoDescription')));
      expect(find.text('Плитка в коробках, грузить аккуратно'), findsOneWidget);
      await waitAndReveal(tester, find.byKey(const Key('companyCargoResponsesTitle')));
      await waitAndReveal(tester, find.byKey(const Key('companyCargoInvited-dddddddd-dddd-4ddd-8ddd-ddddddddd004')));
      expectNoOverflow(tester);
    });

    await run.step(tester, 'фото-груза-на-весь-экран', () async {
      await tester.drag(find.byType(Scrollable).first, const Offset(0, 4000));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('cargoPhoto-0')));
      await waitFor(tester, find.byKey(const Key('fullScreenPhotos')));
      await tester.tap(find.byKey(const Key('fullScreenPhotosClose')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('fullScreenPhotos')), findsNothing);
      await tester.tap(find.byType(BackButton).first);
      await tester.pumpAndSettle();
    });

    await run.step(tester, 'водитель-видит-плашки', () async {
      final driverApi = await DriverApi.login('+77010000005');
      final feed = ((await driverApi.feed({'showOtherCities': 'true'}))['items'] as List).cast<Map>();
      expect(feed.any((c) => c['id'] == cargoId && c['companyIsVerified'] == false), isTrue, reason: 'груз непроверенной компании в ленте');
      final verified = feed.firstWhere((c) => c['companyIsVerified'] == true, orElse: () => fail('в ленте нет груза проверенной компании'));
      await logoutViaProfile(tester, driver: false);
      await loginDriver(tester, '7010000005');
      await waitFor(tester, find.byKey(const Key('feedChipsBar')));
      await waitAndReveal(tester, find.byKey(Key('companyUnverifiedBadge-$cargoId')));
      // 069: водитель видит латинское название вместо иероглифов.
      expect(find.descendant(of: find.byKey(Key('feedCargoCard-$cargoId')), matching: find.textContaining(latinName, findRichText: true)), findsOneWidget);
      expect(find.descendant(of: find.byKey(Key('feedCargoCard-$cargoId')), matching: find.textContaining(chineseName, findRichText: true)), findsNothing);
      expect(find.text(t.companyBadgeUnverified), findsWidgets);
      await waitAndReveal(tester, find.byKey(Key('companyVerifiedBadge-${verified['id']}')));
      expect(find.text(t.companyBadgeVerified), findsWidgets);
      expectNoOverflow(tester);
      // Карточка могла уехать за экран, пока искали плашку другой компании.
      await waitAndReveal(tester, find.byKey(Key('feedCargoCard-$cargoId')));
      await tester.tap(find.byKey(Key('feedCargoCard-$cargoId')));
      await waitFor(tester, find.byKey(const Key('companyUnverifiedBadge-detail')));
      // В карточке груза — латиницей, оригинал мелко серым.
      expect(find.text(latinName), findsWidgets);
      expect(find.byKey(const Key('cargoDetailCompanyOriginal')), findsOneWidget);
      expectInsideSafeZone(tester);
    });

    // Уборка: грузы компании снимаются — лента следующих сценариев как раньше.
    final mine = ((await companyApi.get('/cargos/mine')).data as List).cast<Map>();
    for (final c in mine.where((c) => c['status'] == 'PUBLISHED')) {
      await companyApi.post('/cargos/${c['id']}/close', data: {'outcome': 'CARGO_CANCELLED'});
    }
  });
}
