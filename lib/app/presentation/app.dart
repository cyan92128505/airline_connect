// Presentation imports will be added here

import 'package:app/features/shared/presentation/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'routes/router_provider.dart';

/// Main application widget with router configuration
class AirlineConnectApp extends ConsumerWidget {
  const AirlineConnectApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Airline Connect',
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(1.0)),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
