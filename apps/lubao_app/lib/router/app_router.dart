import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lubao_core/lubao_core.dart';

import '../providers/auth_provider.dart';
import '../features/onboarding/role_select_screen.dart';
import '../features/onboarding/driver_login_screen.dart';
import '../features/onboarding/company_login_screen.dart';
import '../features/onboarding/company_otp_screen.dart';
import '../features/driver/driver_shell.dart';
import '../features/driver/feed/cargo_feed_screen.dart';
import '../features/driver/feed/cargo_detail_screen.dart';
import '../features/driver/deals/driver_deals_screen.dart';
import '../features/driver/profile/driver_profile_screen.dart';
import '../features/driver/profile/driver_setup_screen.dart';
import '../features/driver/profile/driver_verification_screen.dart';
import '../features/company/company_shell.dart';
import '../features/company/cargos/company_cargos_screen.dart';
import '../features/company/cargos/post_cargo_screen.dart';
import '../features/company/cargos/cargo_responses_screen.dart';
import '../features/company/deals/company_deals_screen.dart';
import '../features/company/drivers/drivers_at_point_screen.dart';
import '../features/company/profile/company_profile_screen.dart';
import '../features/shared/deal_detail_screen.dart';
import '../features/shared/chat_screen.dart';
import '../features/shared/devices_screen.dart';
import '../features/shared/splash_screen.dart';

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen(sessionProvider, (previous, next) => notifyListeners());
    ref.listen(sessionRestoringProvider, (previous, next) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) {
      final loc = state.matchedLocation;

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
        if (isDriverSplash && session.driver == null) return '/driver/register';
        return isDriverSplash ? '/driver/feed' : '/company/cargos';
      }

      final onAuthScreen = loc == '/role-select' || loc.startsWith('/login');

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

      if (onAuthScreen) {
        return isDriver ? '/driver/feed' : '/company/cargos';
      }
      if (isDriver && loc.startsWith('/company')) return '/driver/feed';
      if (!isDriver && loc.startsWith('/driver')) return '/company/cargos';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/devices', builder: (context, state) => const DevicesScreen()),
      GoRoute(path: '/role-select', builder: (context, state) => const RoleSelectScreen()),
      GoRoute(path: '/login/driver', builder: (context, state) => const DriverLoginScreen()),
      GoRoute(path: '/login/company', builder: (context, state) => const CompanyLoginScreen()),
      GoRoute(
        path: '/login/company/otp',
        builder: (context, state) => CompanyOtpScreen(email: state.extra as String),
      ),
      ShellRoute(
        builder: (context, state, child) => DriverShell(child: child),
        routes: [
          GoRoute(path: '/driver/feed', builder: (context, state) => const CargoFeedScreen()),
          GoRoute(path: '/driver/deals', builder: (context, state) => const DriverDealsScreen()),
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
      ShellRoute(
        builder: (context, state, child) => CompanyShell(child: child),
        routes: [
          GoRoute(path: '/company/cargos', builder: (context, state) => const CompanyCargosScreen()),
          GoRoute(path: '/company/drivers', builder: (context, state) => const DriversAtPointScreen()),
          GoRoute(path: '/company/deals', builder: (context, state) => const CompanyDealsScreen()),
          GoRoute(path: '/company/profile', builder: (context, state) => const CompanyProfileScreen()),
        ],
      ),
      GoRoute(
        path: '/company/cargos/new',
        builder: (context, state) => PostCargoScreen(cargo: state.extra as Cargo?),
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
        path: '/deal/:id/chat',
        builder: (context, state) => ChatScreen(dealId: state.pathParameters['id']!),
      ),
    ],
  );
});
