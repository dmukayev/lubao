import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../features/prices/route_prices_screen.dart';
import '../features/login/admin_login_screen.dart';
import '../features/login/admin_splash_screen.dart';
import '../features/shell/admin_shell.dart';
import '../features/shell/admin_more_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/dashboard/admin_search_screen.dart';
import '../features/verification/verification_screen.dart';
import '../features/complaints/complaints_screen.dart';
import '../features/companies/admin_companies_screen.dart';
import '../features/companies/company_detail_screen.dart';
import '../features/drivers/admin_drivers_screen.dart';
import '../features/drivers/driver_detail_screen.dart';
import '../features/cargos/admin_cargos_screen.dart';
import '../features/cargos/cargo_detail_screen.dart';
import '../features/deals/admin_deals_screen.dart';
import '../features/deals/deal_detail_screen.dart';
import '../features/audit/admin_audit_screen.dart';
import '../features/blacklist/blacklist_screen.dart';
import '../features/settings/admin_settings_screen.dart';
import '../features/reference/reference_screen.dart';

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
      if (ref.read(sessionRestoringProvider)) {
        return loc == '/splash' ? null : '/splash';
      }

      final session = ref.read(sessionProvider);

      // Сплэш всегда нужно покинуть (в отличие от /login, где можно
      // оставаться без сессии) — иначе при session == null сплэш считался
      // бы "экраном логина" и редиректа никогда бы не было.
      if (loc == '/splash') {
        return session == null ? '/login' : '/dashboard';
      }

      final onLogin = loc == '/login';
      if (session == null) return onLogin ? null : '/login';
      if (onLogin) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const AdminSplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const AdminLoginScreen()),
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen()),
          GoRoute(path: '/verification', builder: (context, state) => const VerificationScreen()),
          GoRoute(path: '/complaints', builder: (context, state) => const ComplaintsScreen()),
          // Задача 030, п.2 — только на телефоне (нижняя навигация);
          // на компьютере поиск встроен в сводку, «Ещё» не показывается.
          GoRoute(path: '/search', builder: (context, state) => const AdminSearchScreen()),
          GoRoute(path: '/more', builder: (context, state) => const AdminMoreScreen()),
          GoRoute(
            path: '/companies',
            builder: (context, state) => AdminCompaniesScreen(queryParams: state.uri.queryParameters),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => CompanyDetailScreen(id: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/drivers',
            builder: (context, state) => AdminDriversScreen(queryParams: state.uri.queryParameters),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => DriverDetailScreen(id: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/cargos',
            builder: (context, state) => AdminCargosScreen(queryParams: state.uri.queryParameters),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => CargoDetailScreen(id: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/deals',
            builder: (context, state) => AdminDealsScreen(queryParams: state.uri.queryParameters),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => DealDetailScreen(id: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(path: '/audit', builder: (context, state) => const AdminAuditScreen()),
          GoRoute(path: '/blacklist', builder: (context, state) => const BlacklistScreen()),
          GoRoute(path: '/settings', builder: (context, state) => const AdminSettingsScreen()),
          GoRoute(path: '/reference', builder: (context, state) => const ReferenceScreen()),
          GoRoute(path: '/route-prices', builder: (context, state) => const RoutePricesScreen()),
        ],
      ),
    ],
  );
});
