import 'package:app/features/shared/presentation/routes/app_routes.dart';

class PagePositionManager {
  PagePositionManager._();

  static bool shouldSlideRight(String fromRoute, String toRoute) {
    final fromPosition = AppRoutes.getTabIndex(fromRoute);
    final toPosition = AppRoutes.getTabIndex(toRoute);

    if (fromRoute == AppRoutes.splash || toRoute == AppRoutes.splash) {
      return false;
    }

    return toPosition < fromPosition;
  }

  static bool shouldAnimateTransition(String fromRoute, String toRoute) {
    if (fromRoute == AppRoutes.splash || toRoute == AppRoutes.splash) {
      return false;
    }

    return AppRoutes.pagePositions.containsKey(fromRoute) &&
        AppRoutes.pagePositions.containsKey(toRoute);
  }

  static double getAnimationDirection(String fromRoute, String toRoute) {
    if (!shouldAnimateTransition(fromRoute, toRoute)) {
      return 0.0;
    }

    return shouldSlideRight(fromRoute, toRoute) ? -1.0 : 1.0;
  }

  static bool isValidPageConfiguration() {
    // Ensure all main routes have positions defined
    final requiredRoutes = [
      AppRoutes.boardingPass,
      AppRoutes.qrScanner,
      AppRoutes.memberAuth,
      AppRoutes.memberProfile,
    ];

    return requiredRoutes.every(
      (route) => AppRoutes.pagePositions.containsKey(route),
    );
  }
}
