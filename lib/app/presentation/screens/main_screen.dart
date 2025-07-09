import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:app/features/member/presentation/screens/member_auth_screen.dart';
import 'package:app/features/boarding_pass/presentation/screens/boarding_pass_screen.dart';
import 'package:app/features/boarding_pass/presentation/screens/qr_scanner_screen.dart';
import 'package:app/features/member/presentation/notifiers/member_auth_notifier.dart';
import 'package:app/features/shared/presentation/widgets/app_navigation_bar.dart';
import 'package:app/features/shared/presentation/widgets/offline_indicator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Main screen with bottom navigation
class MainScreen extends HookConsumerWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = useState(0);
    final memberAuthState = ref.watch(memberAuthNotifierProvider);
    final isOnline = useState(true);

    // Monitor connectivity
    useEffect(() {
      final connectivity = Connectivity();
      final subscription = connectivity.onConnectivityChanged.listen((result) {
        isOnline.value = result.last != ConnectivityResult.none;
      });

      // Check initial connectivity
      connectivity.checkConnectivity().then((result) {
        isOnline.value = result.last != ConnectivityResult.none;
      });

      return subscription.cancel;
    }, []);

    // Redirect to auth if not authenticated and trying to access protected screens
    useEffect(() {
      if (!memberAuthState.isAuthenticated && currentIndex.value != 2) {
        // Auto switch to member tab if not authenticated
        WidgetsBinding.instance.addPostFrameCallback((_) {
          currentIndex.value = 2;
        });
      }
      return null;
    }, [memberAuthState.isAuthenticated]);

    final screens = [
      const BoardingPassScreen(),
      const QRScannerScreen(),
      const MemberAuthScreen(),
    ];

    return Scaffold(
      body: Column(
        children: [
          // Offline indicator
          if (!isOnline.value) const OfflineIndicator(),

          // Main content
          Expanded(
            child: IndexedStack(index: currentIndex.value, children: screens),
          ),
        ],
      ),
      bottomNavigationBar: AppNavigationBar(
        currentIndex: currentIndex.value,
        onTap: (index) => currentIndex.value = index,
        isAuthenticated: memberAuthState.isAuthenticated,
      ),
    );
  }
}
