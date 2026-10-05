import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lubao_core/lubao_core.dart';

import 'package:lubao_app/features/company/profile/company_profile_screen.dart';
import 'package:lubao_app/providers/api_providers.dart';
import 'package:lubao_app/providers/auth_provider.dart';
import 'package:lubao_app/providers/data_providers.dart';
import 'package:lubao_app/providers/locale_provider.dart';

/// Задача 012 — непроверенная компания видит прямо в профиле, почему не
/// может опубликовать груз (баннер + карточка загрузки свидетельства), и
/// список сотрудников показывает имена, а не только роль.
class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository(this.session) : super(ApiClient(baseUrl: 'http://localhost'));

  final Session session;

  @override
  Future<Session?> restore() async => session;
}

Session _session({required bool isVerified, String? memberFullName}) {
  final company = Company(id: 'c1', name: 'Yidao', nameRu: 'Идао', countryId: 'cn-1', isVerified: isVerified, ratingAvg: 0, ratingCount: 0);
  final member = CompanyMember(id: 'm1', companyId: 'c1', userId: 'u1', role: CompanyMemberRole.owner, fullName: memberFullName);
  return Session(
    user: AppUser(id: 'u1', role: UserRole.company, email: 'owner@yidao.cn', locale: 'ru', emailVerifiedAt: DateTime(2026, 1, 1)),
    company: company,
    companyMember: member,
  );
}

Future<void> _pump(WidgetTester tester, Session session, {List<CompanyMember> members = const []}) async {
  await tester.pumpWidget(ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(_FakeAuthRepository(session)),
      companyMembersProvider.overrideWith((ref) async => members),
      companyVerificationDocumentsProvider.overrideWith((ref) async => []),
    ],
    child: MaterialApp(
      locale: const Locale('ru'),
      supportedLocales: supportedLocales,
      localizationsDelegates: LubaoLocalizations.localizationsDelegates,
      home: const CompanyProfileScreen(),
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('an unverified company sees the banner and the verification upload card', (tester) async {
    await _pump(tester, _session(isVerified: false));

    expect(find.textContaining('не проверена'), findsOneWidget);
    expect(find.textContaining('Подтвердите компанию'), findsOneWidget);
  });

  testWidgets('a verified company sees neither the banner nor the upload card', (tester) async {
    await _pump(tester, _session(isVerified: true));

    expect(find.textContaining('не проверена'), findsNothing);
    expect(find.textContaining('Подтвердите компанию'), findsNothing);
  });

  testWidgets('members list shows a colleague\'s fullName, not just the role', (tester) async {
    final colleague = CompanyMember(id: 'm2', companyId: 'c1', userId: 'u2', role: CompanyMemberRole.logist, fullName: 'Ли Вэй');
    await _pump(tester, _session(isVerified: true), members: [colleague]);

    expect(find.text('Ли Вэй'), findsOneWidget);
  });

  testWidgets('«Мой профиль» shows a placeholder until the member fills it in', (tester) async {
    await _pump(tester, _session(isVerified: true, memberFullName: null));

    expect(find.textContaining('Заполните профиль'), findsOneWidget);
  });
}
