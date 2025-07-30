import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_routes.dart';

/// Navigation service focused purely on navigation operations
/// Animation logic is handled by buildSlideTransitionAnimatedPage
class NavigationService {
  NavigationService._();

  // Simple navigation methods - no animation state management
  static void goToBoardingPass(BuildContext context) {
    context.go(AppRoutes.boardingPass);
  }

  static void goToQRScanner(BuildContext context) {
    context.go(AppRoutes.qrScanner);
  }

  static void goToMemberAuth(BuildContext context) {
    context.go(AppRoutes.memberAuth);
  }

  static void goToMemberProfile(BuildContext context) {
    context.go(AppRoutes.memberProfile);
  }

  /// Smart member navigation based on authentication state
  static void goToMember(BuildContext context, bool isAuthenticated) {
    final route = isAuthenticated
        ? AppRoutes.memberProfile
        : AppRoutes.memberAuth;
    context.go(route);
  }

  /// Tab navigation with authentication awareness
  static void navigateToTab(
    BuildContext context,
    int tabIndex,
    bool isAuthenticated,
  ) {
    final route = AppRoutes.getTabRoute(tabIndex, isAuthenticated);
    context.go(route);
  }

  // Authentication flow navigation
  static void handleAuthenticationSuccess(BuildContext context) {
    context.go(AppRoutes.boardingPass);
  }

  static void handleLogout(BuildContext context) {
    context.go(AppRoutes.memberAuth);
  }

  /// Member flow navigation
  static void handleMemberAccess(BuildContext context, bool isAuthenticated) {
    if (isAuthenticated) {
      context.go(AppRoutes.memberProfile);
    } else {
      context.go(AppRoutes.memberAuth);
    }
  }

  // Route utility methods
  static bool isCurrentRoute(BuildContext context, String route) {
    final currentLocation = GoRouterState.of(context).uri.path;
    return currentLocation == route;
  }

  static int getCurrentTabIndex(BuildContext context) {
    final currentLocation = GoRouterState.of(context).uri.path;
    return AppRoutes.getTabIndex(currentLocation);
  }

  static String getCurrentLocation(BuildContext context) {
    return GoRouterState.of(context).uri.path;
  }

  static bool isCurrentRouteProtected(BuildContext context) {
    final currentLocation = GoRouterState.of(context).uri.path;
    return AppRoutes.protectedRoutes.contains(currentLocation);
  }

  static String getMemberRoute(bool isAuthenticated) {
    return isAuthenticated ? AppRoutes.memberProfile : AppRoutes.memberAuth;
  }

  static bool isCurrentRouteMemberRelated(BuildContext context) {
    final currentLocation = GoRouterState.of(context).uri.path;
    return currentLocation == AppRoutes.memberAuth ||
        currentLocation == AppRoutes.memberProfile;
  }
}
