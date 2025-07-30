import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SlideTransitionPage extends CustomTransitionPage {
  final double direction;
  final Duration duration;

  const SlideTransitionPage({
    required super.child,
    required super.key,
    super.name,
    super.arguments,
    super.restorationId,
    this.direction = 1.0,
    this.duration = const Duration(milliseconds: 200),
    required super.transitionsBuilder,
  });

  @override
  Duration get transitionDuration => duration;

  @override
  Duration get reverseTransitionDuration => duration;
}

class SlideTransitionPageFactory {
  SlideTransitionPageFactory._();

  static SlideTransitionPage create({
    required GoRouterState state,
    required Widget child,
    required double direction,
    Duration duration = const Duration(milliseconds: 200),
  }) {
    return SlideTransitionPage(
      key: state.pageKey,
      child: child,
      name: state.name,
      direction: direction,
      duration: duration,
      transitionsBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
            Widget child,
          ) {
            final begin = Offset(direction, 0.0);
            const end = Offset.zero;
            final tween = Tween(begin: begin, end: end);

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
    );
  }

  static MaterialPage createStandard({
    required GoRouterState state,
    required Widget child,
  }) {
    return MaterialPage(key: state.pageKey, child: child, name: state.name);
  }
}
