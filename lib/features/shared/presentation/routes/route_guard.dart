import 'package:app/features/member/application/dtos/member_dto.dart';
import 'package:app/features/member/presentation/notifiers/member_auth_notifier.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_routes.dart';

/// Route guard for authentication and authorization
/// Simplified to work with pre-initialized authentication state
class RouteGuard {
  RouteGuard._();

  /// Main redirect logic for authentication
  /// Now assumes all state is pre-initialized in main.dart
  static String? handleRedirect(
    BuildContext context,
    GoRouterState state,
    MemberAuthState authState,
  ) {
    final currentPath = state.uri.path;

    // Always redirect root to splash for consistent startup experience
    if (currentPath == AppRoutes.root) {
      return AppRoutes.splash;
    }

    // Handle splash screen - now with simplified logic
    if (currentPath == AppRoutes.splash) {
      // Since state is pre-initialized, we only need to check if we should stay on splash
      // Splash screen itself handles the timing and navigation
      return null; // Let splash screen control its own navigation timing
    }

    // For protected routes, check authentication status
    if (_isProtectedRoute(currentPath)) {
      // State is guaranteed to be initialized, so we can make direct decisions
      if (!authState.isAuthenticated ||
          authState.member?.isUnauthenticated == true) {
        return AppRoutes.memberAuth;
      }
      // User is authenticated, allow access to protected route
      return null;
    }

    // For member auth route
    if (currentPath == AppRoutes.memberAuth) {
      // If user is already authenticated, redirect to main app
      if (authState.isAuthenticated &&
          authState.member?.isAuthenticated == true) {
        return AppRoutes.boardingPass;
      }
      // User is not authenticated, stay on auth page
      return null;
    }

    // For other non-protected routes, allow access
    return null;
  }

  /// Check if route requires authentication
  static bool _isProtectedRoute(String path) {
    return AppRoutes.protectedRoutes.contains(path);
  }

  /// Validate if user can access specific route
  static bool canAccessRoute(String path, bool isAuthenticated) {
    if (_isProtectedRoute(path)) {
      return isAuthenticated;
    }
    return true;
  }

  /// Check if authenticated user should be redirected from auth page
  static bool shouldRedirectFromAuth(String currentPath, bool isAuthenticated) {
    return isAuthenticated && currentPath == AppRoutes.memberAuth;
  }

  /// Get appropriate member route based on authentication state
  static String getMemberRouteForState(bool isAuthenticated) {
    return isAuthenticated ? AppRoutes.memberProfile : AppRoutes.memberAuth;
  }
}
