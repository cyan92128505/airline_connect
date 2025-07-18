import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_routes.dart';

/// Navigation service for programmatic navigation
class NavigationService {
  NavigationService._();

  // Direct navigation methods
  static void goToBoardingPass(BuildContext context) {
    context.go(AppRoutes.boardingPass);
  }

  static void goToQRScanner(BuildContext context) {
    context.go(AppRoutes.qrScanner);
  }

  static void goToMemberAuth(BuildContext context) {
    context.go(AppRoutes.memberAuth);
  }

  // Tab navigation
  static void navigateToTab(BuildContext context, int tabIndex) {
    if (tabIndex < AppRoutes.tabIndexToRoute.length) {
      final route = AppRoutes.tabIndexToRoute[tabIndex];
      context.go(route);
    }
  }

  // Authentication flow navigation
  static void handleAuthenticationSuccess(BuildContext context) {
    context.go(AppRoutes.boardingPass);
  }

  static void handleLogout(BuildContext context) {
    context.go(AppRoutes.memberAuth);
  }

  // Utility methods
  static bool isCurrentRoute(BuildContext context, String route) {
    final currentLocation = GoRouterState.of(context).uri.path;
    return currentLocation == route;
  }

  static int getCurrentTabIndex(BuildContext context) {
    final currentLocation = GoRouterState.of(context).uri.path;
    return AppRoutes.routeToTabIndex[currentLocation] ?? 0;
  }
}
