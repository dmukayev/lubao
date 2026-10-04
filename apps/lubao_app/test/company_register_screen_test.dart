import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubao_core/lubao_core.dart';

import 'package:lubao_app/features/onboarding/company_register_screen.dart';
import 'package:lubao_app/providers/api_providers.dart';
import 'package:lubao_app/providers/locale_provider.dart';

const _cn = Country(id: 'cn-1', code: 'CN', name: I18nText(kk: 'Қытай', ru: 'Китай', zh: '中国'), isCisMember: false);
const _kz = Country(id: 'kz-1', code: 'KZ', name: I18nText(kk: 'Қазақстан', ru: 'Казахстан', zh: '哈萨克斯坦'), isCisMember: true);

final _fixture = ReferenceData(
  countries: const [_cn, _kz],
  regions: const [],
  cities: const [],
  bodyTypes: const [],
  permits: const [],
  points: const [],
);

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository() : super(ApiClient(baseUrl: 'http://localhost'));

  String? lastEmail;
  String? lastOwnerName;
  String? lastCompanyName;
  String? lastCountryId;

  @override
  Future<Session?> restore() async => null;

  @override
  Future<Session> registerCompany({
    required String email,
    required String password,
    required String ownerName,
    required String companyName,
    String? companyNameRu,
    required String countryId,
  }) async {
    lastEmail = email;
    lastOwnerName = ownerName;
    lastCompanyName = companyName;
    lastCountryId = countryId;
    final company = Company(
      id: 'company-1',
      name: companyName,
      nameRu: companyNameRu,
      countryId: countryId,
      isVerified: false,
      ratingAvg: 0,
      ratingCount: 0,
    );
    final member = CompanyMember(id: 'member-1', companyId: 'company-1', userId: 'user-1', role: CompanyMemberRole.owner);
    return Session(
      user: AppUser(id: 'user-1', role: UserRole.company, email: email, locale: 'ru'),
      company: company,
      companyMember: member,
    );
  }
}

void main() {
  testWidgets('owner fills email, password, name, company name and country, submits, and the session gets the new company',
      (tester) async {
    final authRepo = _FakeAuthRepository();
    await tester.pumpWidget(ProviderScope(
      overrides: [
        referenceDataProvider.overrideWith((ref) async => _fixture),
        authRepositoryProvider.overrideWithValue(authRepo),
      ],
      child: MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: supportedLocales,
        localizationsDelegates: LubaoLocalizations.localizationsDelegates,
        home: const CompanyRegisterScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Email'), 'owner@example.com');
    await tester.enterText(find.widgetWithText(TextField, 'Пароль'), 'password123');
    await tester.enterText(find.widgetWithText(TextField, 'Ваше имя'), 'Ли Вэй');
    await tester.enterText(find.widgetWithText(TextField, 'Название компании'), '新疆测试物流');
    await tester.tap(find.text('Китай'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byType(PrimaryButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PrimaryButton));
    await tester.pumpAndSettle();

    expect(authRepo.lastEmail, 'owner@example.com');
    expect(authRepo.lastOwnerName, 'Ли Вэй');
    expect(authRepo.lastCompanyName, '新疆测试物流');
    expect(authRepo.lastCountryId, 'cn-1');
  });

  testWidgets('submitting without picking a country shows the inline error', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        referenceDataProvider.overrideWith((ref) async => _fixture),
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
      ],
      child: MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: supportedLocales,
        localizationsDelegates: LubaoLocalizations.localizationsDelegates,
        home: const CompanyRegisterScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Email'), 'owner@example.com');
    await tester.enterText(find.widgetWithText(TextField, 'Пароль'), 'password123');
    await tester.enterText(find.widgetWithText(TextField, 'Ваше имя'), 'Ли Вэй');
    await tester.enterText(find.widgetWithText(TextField, 'Название компании'), '新疆测试物流');
    await tester.ensureVisible(find.byType(PrimaryButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(PrimaryButton));
    await tester.pumpAndSettle();

    expect(find.text('Выберите страну'), findsOneWidget);
  });
}
