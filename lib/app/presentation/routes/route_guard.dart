import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'app_routes.dart';

/// Route guard for authentication and authorization
class RouteGuard {
  RouteGuard._();

  /// Main redirect logic for authentication
  static String? handleRedirect(
    BuildContext context,
    GoRouterState state,
    bool isAuthenticated,
  ) {
    final currentPath = state.uri.path;

    // Redirect unauthenticated users from protected routes
    if (!isAuthenticated && _isProtectedRoute(currentPath)) {
      return AppRoutes.memberAuth;
    }

    // Redirect authenticated users from auth page to boarding pass
    if (isAuthenticated && currentPath == AppRoutes.memberAuth) {
      return AppRoutes.boardingPass;
    }

    // Handle root path
    if (currentPath == AppRoutes.root) {
      return isAuthenticated ? AppRoutes.boardingPass : AppRoutes.memberAuth;
    }

    return null; // No redirect needed
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
}
