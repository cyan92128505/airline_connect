import 'package:app/features/shared/presentation/screens/splash_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:app/features/shared/presentation/shells/error_shell.dart';
import 'package:app/features/shared/presentation/shells/main_shell.dart';
import 'package:app/features/member/presentation/notifiers/member_auth_notifier.dart';
import 'package:app/features/boarding_pass/presentation/screens/boarding_pass_screen.dart';
import 'package:app/features/boarding_pass/presentation/screens/qr_scanner_screen.dart';
import 'package:app/features/member/presentation/screens/member_auth_screen.dart';
import 'package:app/features/member/presentation/screens/member_profile_screen.dart';

import 'app_routes.dart';
import 'route_guard.dart';

/// GoRouter configuration provider
final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(memberAuthNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.root,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      return RouteGuard.handleRedirect(context, state, authState);
    },
    errorBuilder: (context, state) => ErrorShell(error: state.error!),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: AppRoutes.splashName,
        builder: (context, state) => const SplashScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.boardingPass,
            name: AppRoutes.boardingPassName,
            builder: (context, state) => const BoardingPassScreen(),
          ),
          GoRoute(
            path: AppRoutes.qrScanner,
            name: AppRoutes.qrScannerName,
            builder: (context, state) => const QRScannerScreen(),
          ),
          GoRoute(
            path: AppRoutes.memberAuth,
            name: AppRoutes.memberAuthName,
            builder: (context, state) => const MemberAuthScreen(),
          ),
          GoRoute(
            path: AppRoutes.memberProfile,
            name: AppRoutes.memberProfileName,
            builder: (context, state) => const MemberProfileScreen(),
          ),
        ],
      ),
    ],
  );
});
