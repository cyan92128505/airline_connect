import 'package:app/features/shared/presentation/routes/route_state_manager.dart';
import 'package:app/features/shared/presentation/routes/page_position_manager.dart';
import 'package:app/features/shared/presentation/routes/transitions/slide_transition_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PageTransitionBuilder {
  PageTransitionBuilder._();

  static Page buildSlideTransitionAnimatedPage({
    required BuildContext context,
    required GoRouterState state,
    required Widget child,
    required String currentRoute,
  }) {
    RouteStateManager.updateRouteTransition(currentRoute);

    final previousRoute = RouteStateManager.getPreviousRoute();

    final shouldAnimate =
        previousRoute != null &&
        PagePositionManager.shouldAnimateTransition(
          previousRoute,
          currentRoute,
        );

    if (!shouldAnimate) {
      return SlideTransitionPageFactory.createStandard(
        state: state,
        child: child,
      );
    }

    final direction = PagePositionManager.getAnimationDirection(
      previousRoute,
      currentRoute,
    );

    return SlideTransitionPageFactory.create(
      state: state,
      child: child,
      direction: direction,
    );
  }
}
