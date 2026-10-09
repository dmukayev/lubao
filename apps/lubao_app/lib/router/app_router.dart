import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';

import '../providers/app_update_provider.dart';
import '../providers/auth_provider.dart';
import '../features/onboarding/role_select_screen.dart';
import '../features/onboarding/driver_login_screen.dart';
import '../features/onboarding/company_login_screen.dart';
import '../features/onboarding/company_register_screen.dart';
import '../features/onboarding/forgot_password_screen.dart';
import '../features/onboarding/accept_invite_screen.dart';
import '../features/driver/driver_shell.dart';
import '../features/driver/feed/cargo_feed_screen.dart';
import '../features/driver/feed/cargo_detail_screen.dart';
import '../features/driver/trips/driver_trips_screen.dart';
import '../features/driver/trips/trip_history_screen.dart';
import '../features/driver/profile/driver_profile_screen.dart';
import '../features/driver/profile/driver_setup_screen.dart';
import '../features/driver/profile/driver_verification_screen.dart';
import '../features/driver/profile/garage_screen.dart';
import '../features/company/company_shell.dart';
import '../features/company/cargos/company_cargos_screen.dart';
import '../features/company/cargos/post_cargo_screen.dart';
import '../features/company/cargos/cargo_responses_screen.dart';
import '../features/company/drivers/drivers_at_point_screen.dart';
import '../features/company/profile/company_profile_screen.dart';
import '../features/shared/deal_detail_screen.dart';
import '../features/shared/chat_screen.dart';
import '../features/shared/my_chats_screen.dart';
import '../features/shared/devices_screen.dart';
import '../features/shared/notification_settings_screen.dart';
import '../features/shared/splash_screen.dart';
import '../features/shared/about_screen.dart';
import '../features/shared/update_required_screen.dart';
import '../services/share_links.dart';
import '../features/driver/feed/company_cargos_public_screen.dart';

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen(sessionProvider, (previous, next) => notifyListeners());
    ref.listen(sessionRestoringProvider, (previous, next) => notifyListeners());
    ref.listen(appUpdateRequiredProvider, (previous, next) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final loc = state.matchedLocation;

      // 043 п.8: версия ниже минимальной — только экран обновления.
      if (ref.read(appUpdateRequiredProvider)) {
        return loc == '/update' ? null : '/update';
      }
      if (loc == '/update') return '/splash';

      // 052 п.3: ссылка «Поделиться» — код запоминаем; экран откроется после
      // входа (или сразу, если сессия уже есть).
      final shareMatch = shareLinkPath.firstMatch(loc);
      if (shareMatch != null) {
        final handler = ref.read(shareLinkHandlerProvider)..remember(shareMatch.group(2)!);
        final s = ref.read(sessionProvider);
        if (ref.read(sessionRestoringProvider)) return '/splash';
        if (s == null) return '/role-select';
        Future.microtask(handler.consume);
        return s.user.role == UserRole.driver ? '/driver/feed' : '/company/cargos';
      }

      // Пока идёт восстановление сессии из secure storage — остаёмся на
      // сплэше, чтобы не мигнуть экраном входа перед тем, как токен
      // окажется валидным (см. SessionController._restore).
      if (ref.read(sessionRestoringProvider)) {
        return loc == '/splash' ? null : '/splash';
      }

      final session = ref.read(sessionProvider);

      // Сплэш — временная точка, с которой всегда нужно уйти дальше (в
      // отличие от role-select/login, куда можно оставаться, если сессии
      // ещё нет): иначе при session == null и loc == '/splash' ветка ниже
      // считала бы сплэш "экраном входа" и никогда не делала редирект.
      if (loc == '/splash') {
        if (session == null) return '/role-select';
        final isDriverSplash = session.user.role == UserRole.driver;
        if (isDriverSplash) return session.driver == null ? '/driver/register' : '/driver/feed';
        return '/company/cargos';
      }

      final onAuthScreen = loc == '/role-select' || loc.startsWith('/login') || loc.startsWith('/invite');

      if (session == null) {
        return onAuthScreen ? null : '/role-select';
      }

      final isDriver = session.user.role == UserRole.driver;

      // Подтвердил SMS-код, но анкеты (имя/кузов/направления) ещё нет —
      // пока не пускаем дальше формы регистрации.
      final needsDriverRegistration = isDriver && session.driver == null;
      if (needsDriverRegistration) {
        return loc == '/driver/register' ? null : '/driver/register';
      }

      // Регистрация и приглашение компании теперь атомарны (задача 025) —
      // COMPANY-сессия всегда приходит с уже привязанной компанией, отдельный
      // промежуточный шаг /company/register больше не нужен.

      if (onAuthScreen) {
        return isDriver ? '/driver/feed' : '/company/cargos';
      }
      if (isDriver && loc.startsWith('/company')) return '/driver/feed';
      if (!isDriver && loc.startsWith('/driver')) return '/company/cargos';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/update', builder: (context, state) => const UpdateRequiredScreen()),
      GoRoute(path: '/devices', builder: (context, state) => const DevicesScreen()),
      GoRoute(path: '/about', builder: (context, state) => const AboutScreen()),
      GoRoute(path: '/notifications/settings', builder: (context, state) => const NotificationSettingsScreen()),
      GoRoute(path: '/role-select', builder: (context, state) => const RoleSelectScreen()),
      GoRoute(path: '/login/driver', builder: (context, state) => const DriverLoginScreen()),
      GoRoute(
        path: '/login/company',
        builder: (context, state) => CompanyLoginScreen(prefillEmail: state.extra as String?),
      ),
      GoRoute(
        path: '/login/company/register',
        builder: (context, state) => const CompanyRegisterScreen(),
      ),
      GoRoute(
        path: '/login/company/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/invite/:token',
        builder: (context, state) => AcceptInviteScreen(token: state.pathParameters['token']!),
      ),
      ShellRoute(
        builder: (context, state, child) => DriverShell(child: child),
        routes: [
          GoRoute(path: '/driver/feed', builder: (context, state) => const CargoFeedScreen()),
          GoRoute(path: '/driver/chats', builder: (context, state) => const MyChatsScreen()),
          // 056 п.6: «Сделки» водителя → «Мои рейсы»; старые ссылки и push — туда же.
          GoRoute(path: '/driver/trips', builder: (context, state) => const DriverTripsScreen()),
          GoRoute(path: '/driver/deals', redirect: (context, state) => '/driver/trips'),
          GoRoute(path: '/driver/profile', builder: (context, state) => const DriverProfileScreen()),
        ],
      ),
      GoRoute(
        path: '/driver/cargo/:id',
        builder: (context, state) => CargoDetailScreen(cargoId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/driver/setup',
        builder: (context, state) => const DriverSetupScreen(),
      ),
      GoRoute(
        path: '/driver/register',
        builder: (context, state) => const DriverSetupScreen(isRegistration: true),
      ),
      GoRoute(
        path: '/driver/verification',
        builder: (context, state) => const DriverVerificationScreen(),
      ),
      GoRoute(
        path: '/driver/garage',
        builder: (context, state) => const GarageScreen(),
      ),
      GoRoute(path: '/driver/responses', redirect: (context, state) => '/driver/trips'),
      GoRoute(path: '/driver/history', builder: (context, state) => const TripHistoryScreen()),
      GoRoute(path: '/driver/company/:id', builder: (context, state) => CompanyCargosPublicScreen(companyId: state.pathParameters['id']!)),
      ShellRoute(
        builder: (context, state, child) => CompanyShell(child: child),
        routes: [
          GoRoute(
            path: '/company/cargos',
            builder: (context, state) => CompanyCargosScreen(
              key: ValueKey(state.uri.queryParameters['tab']),
              initialTab: CompanyCargoTab.values.firstWhere((t) => t.name == state.uri.queryParameters['tab'], orElse: () => CompanyCargoTab.active),
            ),
          ),
          GoRoute(path: '/company/drivers', builder: (context, state) => const DriversAtPointScreen()),
          GoRoute(path: '/company/chats', builder: (context, state) => const MyChatsScreen()),
          // 056 п.4: старые ссылки и push на «Сделки» логиста — «Грузы» → «В работе».
          GoRoute(path: '/company/deals', redirect: (context, state) => '/company/cargos?tab=work'),
          GoRoute(path: '/company/profile', builder: (context, state) => const CompanyProfileScreen()),
        ],
      ),
      GoRoute(
        path: '/company/cargos/new',
        builder: (context, state) => PostCargoScreen(cargo: state.extra as Cargo?),
      ),
      GoRoute(
        path: '/company/cargos/repeat',
        builder: (context, state) => PostCargoScreen(template: state.extra as Cargo?),
      ),
      GoRoute(
        path: '/company/cargos/:id/responses',
        builder: (context, state) => CargoResponsesScreen(cargoId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/deal/:id',
        builder: (context, state) => DealDetailScreen(dealId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) => ChatScreen(chatId: state.pathParameters['id']!),
      ),
    ],
  );
});
