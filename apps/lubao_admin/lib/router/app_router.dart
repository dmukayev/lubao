import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../features/login/admin_login_screen.dart';
import '../features/login/admin_splash_screen.dart';
import '../features/shell/admin_shell.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/verification/verification_screen.dart';
import '../features/complaints/complaints_screen.dart';
import '../features/companies/admin_companies_screen.dart';
import '../features/companies/company_detail_screen.dart';
import '../features/drivers/admin_drivers_screen.dart';
import '../features/drivers/driver_detail_screen.dart';
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
          GoRoute(
            path: '/companies',
            builder: (context, state) => const AdminCompaniesScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => CompanyDetailScreen(id: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: '/drivers',
            builder: (context, state) => const AdminDriversScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) => DriverDetailScreen(id: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(path: '/reference', builder: (context, state) => const ReferenceScreen()),
        ],
      ),
    ],
  );
});
