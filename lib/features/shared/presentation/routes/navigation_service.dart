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

  static void goToMemberProfile(BuildContext context) {
    context.go(AppRoutes.memberProfile);
  }

  // Smart member navigation based on authentication state
  static void goToMember(BuildContext context, bool isAuthenticated) {
    final route = isAuthenticated
        ? AppRoutes.memberProfile
        : AppRoutes.memberAuth;
    context.go(route);
  }

  // Tab navigation with authentication awareness
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

  // Member flow navigation
  static void handleMemberAccess(BuildContext context, bool isAuthenticated) {
    if (isAuthenticated) {
      context.go(AppRoutes.memberProfile);
    } else {
      context.go(AppRoutes.memberAuth);
    }
  }

  // Utility methods
  static bool isCurrentRoute(BuildContext context, String route) {
    final currentLocation = GoRouterState.of(context).uri.path;
    return currentLocation == route;
  }

  static int getCurrentTabIndex(BuildContext context) {
    final currentLocation = GoRouterState.of(context).uri.path;
    return AppRoutes.getTabIndex(currentLocation);
  }

  // Check if current route requires authentication
  static bool isCurrentRouteProtected(BuildContext context) {
    final currentLocation = GoRouterState.of(context).uri.path;
    return AppRoutes.protectedRoutes.contains(currentLocation);
  }

  // Get appropriate member route based on authentication state
  static String getMemberRoute(bool isAuthenticated) {
    return isAuthenticated ? AppRoutes.memberProfile : AppRoutes.memberAuth;
  }

  // Check if current route is a member-related route
  static bool isCurrentRouteMemberRelated(BuildContext context) {
    final currentLocation = GoRouterState.of(context).uri.path;
    return currentLocation == AppRoutes.memberAuth ||
        currentLocation == AppRoutes.memberProfile;
  }
}
