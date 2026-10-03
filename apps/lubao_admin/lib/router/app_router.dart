import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../features/login/admin_login_screen.dart';
import '../features/shell/admin_shell.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/verification/verification_screen.dart';
import '../features/complaints/complaints_screen.dart';
import '../features/companies/admin_companies_screen.dart';
import '../features/drivers/admin_drivers_screen.dart';
import '../features/reference/reference_screen.dart';

class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen(sessionProvider, (previous, next) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      final onLogin = state.matchedLocation == '/login';
      if (session == null) return onLogin ? null : '/login';
      if (onLogin) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const AdminLoginScreen()),
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen()),
          GoRoute(path: '/verification', builder: (context, state) => const VerificationScreen()),
          GoRoute(path: '/complaints', builder: (context, state) => const ComplaintsScreen()),
          GoRoute(path: '/companies', builder: (context, state) => const AdminCompaniesScreen()),
          GoRoute(path: '/drivers', builder: (context, state) => const AdminDriversScreen()),
          GoRoute(path: '/reference', builder: (context, state) => const ReferenceScreen()),
        ],
      ),
    ],
  );
});
