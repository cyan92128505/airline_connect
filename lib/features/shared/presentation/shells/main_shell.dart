import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:app/features/shared/presentation/routes/navigation_service.dart';
import 'package:app/features/member/presentation/notifiers/member_auth_notifier.dart';
import 'package:app/features/shared/presentation/widgets/app_navigation_bar.dart';

/// Main application shell with bottom navigation
class MainShell extends HookConsumerWidget {
  final Widget child;

  const MainShell({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAuthState = ref.watch(memberAuthNotifierProvider);
    final currentTabIndex = NavigationService.getCurrentTabIndex(context);
    final isAuthenticated = memberAuthState.isAuthenticated;

    return Scaffold(
      body: Column(
        children: [
          // Global UI elements can be added here
          // if (!isOnline) const OfflineIndicator(),

          // Main content area
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: AppNavigationBar(
        currentIndex: currentTabIndex,
        onTap: (index) =>
            NavigationService.navigateToTab(context, index, isAuthenticated),
        isAuthenticated: isAuthenticated,
      ),
    );
  }
}
