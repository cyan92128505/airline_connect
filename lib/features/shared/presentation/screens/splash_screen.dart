import 'package:app/features/member/application/dtos/member_dto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app/features/member/presentation/notifiers/member_auth_notifier.dart';
import 'package:app/features/shared/presentation/routes/app_routes.dart';
import 'package:app/core/presentation/theme/app_colors.dart';
import 'package:app/core/presentation/widgets/svg/logo.dart';
import 'package:app/core/presentation/widgets/svg/slogen.dart';
import 'package:gap/gap.dart';

/// Splash screen for app initialization display
/// Waits for proper initialization before navigation
class SplashScreen extends HookConsumerWidget {
  static const String routeName = '/splash';
  static const Key splashContainerKey = Key('splash_container');
  static const Key initializationIndicatorKey = Key('initialization_indicator');

  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(memberAuthNotifierProvider);
    final animationController = useAnimationController(
      duration: const Duration(milliseconds: 2000),
    );

    // Track if we've already navigated
    final hasNavigated = useRef(false);

    // Start animation immediately
    useEffect(() {
      animationController.forward();
      return null;
    }, []);

    // Handle navigation after initialization is complete
    useEffect(() {
      // Wait for both conditions:
      // 1. Authentication state is initialized
      // 2. Minimum display time has passed (2 seconds)
      if (authState.isInitialized && !hasNavigated.value) {
        debugPrint(
          'SplashScreen: Auth state initialized, waiting for minimum display time',
        );

        // Calculate remaining time for minimum display
        Future.delayed(const Duration(seconds: 2), () {
          if (context.mounted && !hasNavigated.value) {
            hasNavigated.value = true;
            _navigateToNextScreen(context, authState);
          }
        });
      }
      return null;
    }, [authState.isInitialized, authState.isAuthenticated]);

    return Scaffold(
      key: splashContainerKey,
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: animationController,
            builder: (context, child) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // Logo with fade-in animation
                  AnimatedOpacity(
                    opacity: animationController.value,
                    duration: const Duration(milliseconds: 800),
                    child: Transform.scale(
                      scale: 0.8 + (0.2 * animationController.value),
                      child: const LogoWidget(
                        width: 120,
                        height: 120,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const Gap(32),

                  // App name with slide-up animation
                  AnimatedSlide(
                    offset: Offset(0, 1 - animationController.value),
                    duration: const Duration(milliseconds: 1000),
                    child: AnimatedOpacity(
                      opacity: animationController.value,
                      duration: const Duration(milliseconds: 1000),
                      child: Column(
                        children: [
                          Text(
                            'AirlineConnect',
                            style: Theme.of(context).textTheme.headlineLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                          ),

                          const Gap(8),

                          const SlogenWidget(height: 24, color: Colors.white70),

                          const Gap(8),

                          Text(
                            '航空登機證管理系統',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(
                                  color: Colors.white70,
                                  letterSpacing: 0.8,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Loading section with status
                  _buildLoadingSection(context, authState),

                  const Gap(40),

                  // Version info
                  AnimatedOpacity(
                    opacity: animationController.value * 0.7,
                    duration: const Duration(milliseconds: 1500),
                    child: Text(
                      'Version 1.0.0',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.white54),
                    ),
                  ),

                  const Gap(20),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Build loading section with clear status messages
  Widget _buildLoadingSection(BuildContext context, MemberAuthState authState) {
    String statusMessage;
    IconData statusIcon;
    Color statusColor = Colors.white;

    // Clear status logic based on initialization state
    if (!authState.isInitialized) {
      statusMessage = '正在初始化應用程式...';
      statusIcon = Icons.sync;
      statusColor = Colors.white;
    } else if (authState.hasError) {
      statusMessage = '初始化完成，準備進入應用程式';
      statusIcon = Icons.info_outline;
      statusColor = Colors.orangeAccent;
    } else if (authState.isAuthenticated &&
        authState.member?.isAuthenticated == true) {
      statusMessage = '歡迎回來！';
      statusIcon = Icons.check_circle_outline;
      statusColor = Colors.greenAccent;
    } else {
      statusMessage = '準備就緒';
      statusIcon = Icons.done;
      statusColor = Colors.blueAccent;
    }

    return Column(
      key: initializationIndicatorKey,
      children: [
        // Status icon with pulse animation
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 1500),
          tween: Tween(begin: 0.8, end: 1.2),
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: Icon(statusIcon, color: statusColor, size: 32),
            );
          },
        ),

        const Gap(16),

        // Status message
        Text(
          statusMessage,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: statusColor,
            fontWeight: FontWeight.w500,
          ),
        ),

        const Gap(16),

        // Loading indicator (only show if not yet initialized)
        if (!authState.isInitialized) ...[
          SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
        ],
      ],
    );
  }

  /// Navigate to appropriate screen after splash display
  void _navigateToNextScreen(BuildContext context, MemberAuthState authState) {
    // Detailed logging for troubleshooting
    debugPrint('SplashScreen Navigation Decision:');
    debugPrint('- isInitialized: ${authState.isInitialized}');
    debugPrint('- isAuthenticated: ${authState.isAuthenticated}');
    debugPrint('- member exists: ${authState.member != null}');
    debugPrint('- member number: ${authState.member?.memberNumber}');
    debugPrint(
      '- member isAuthenticated: ${authState.member?.isAuthenticated}',
    );
    debugPrint(
      '- member isUnauthenticated: ${authState.member?.isUnauthenticated}',
    );

    if (authState.isAuthenticated &&
        authState.member?.isAuthenticated == true) {
      // User is authenticated with valid session, navigate to main screen
      debugPrint('- Navigation: Going to ${AppRoutes.boardingPass}');
      context.go(AppRoutes.boardingPass);
    } else {
      // User is not authenticated, navigate to login screen
      debugPrint('- Navigation: Going to ${AppRoutes.memberAuth}');
      context.go(AppRoutes.memberAuth);
    }
  }
}
