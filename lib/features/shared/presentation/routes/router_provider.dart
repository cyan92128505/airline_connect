import 'package:app/features/boarding_pass/presentation/screens/boarding_pass_screen.dart';
import 'package:app/features/boarding_pass/presentation/screens/qr_scanner_screen.dart';
import 'package:app/features/member/presentation/notifiers/member_auth_notifier.dart';
import 'package:app/features/member/presentation/screens/member_auth_screen.dart';
import 'package:app/features/member/presentation/screens/member_profile_screen.dart';
import 'package:app/features/shared/presentation/routes/transitions/page_transition_builder.dart';
import 'package:app/features/shared/presentation/screens/splash_screen.dart';
import 'package:app/features/shared/presentation/shells/error_shell.dart';
import 'package:app/features/shared/presentation/shells/main_shell.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

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
            pageBuilder: (context, state) {
              return PageTransitionBuilder.buildSlideTransitionAnimatedPage(
                context: context,
                state: state,
                child: const BoardingPassScreen(),
                currentRoute: AppRoutes.boardingPass,
              );
            },
          ),
          GoRoute(
            path: AppRoutes.qrScanner,
            name: AppRoutes.qrScannerName,
            pageBuilder: (context, state) {
              return PageTransitionBuilder.buildSlideTransitionAnimatedPage(
                context: context,
                state: state,
                child: const QRScannerScreen(),
                currentRoute: AppRoutes.qrScanner,
              );
            },
          ),
          GoRoute(
            path: AppRoutes.memberAuth,
            name: AppRoutes.memberAuthName,
            builder: (context, state) => const MemberAuthScreen(),
          ),
          GoRoute(
            path: AppRoutes.memberProfile,
            name: AppRoutes.memberProfileName,
            pageBuilder: (context, state) {
              return PageTransitionBuilder.buildSlideTransitionAnimatedPage(
                context: context,
                state: state,
                child: const MemberProfileScreen(),
                currentRoute: AppRoutes.memberProfile,
              );
            },
          ),
        ],
      ),
    ],
  );
});
