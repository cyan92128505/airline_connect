import 'package:app/core/presentation/widgets/network_status_icon.dart';
import 'package:app/core/presentation/widgets/svg/logo.dart';
import 'package:app/features/boarding_pass/presentation/widgets/bottom_network_summary.dart';
import 'package:app/features/boarding_pass/presentation/widgets/empty_state.dart';
import 'package:app/features/boarding_pass/presentation/widgets/network_status_sliver.dart';
import 'package:app/features/boarding_pass/presentation/widgets/not_authenticated_view.dart';
import 'package:app/features/boarding_pass/presentation/widgets/offline_warning.dart';
import 'package:app/features/boarding_pass/presentation/widgets/section_header.dart';
import 'package:app/features/boarding_pass/presentation/widgets/simple_boarding_pass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:app/features/boarding_pass/presentation/notifiers/boarding_pass_notifier.dart';
import 'package:app/features/boarding_pass/presentation/widgets/boarding_pass_card.dart';
import 'package:app/features/member/presentation/notifiers/member_auth_notifier.dart';
import 'package:app/features/member/presentation/widgets/member_info_card.dart';
import 'package:app/core/presentation/widgets/loading_indicator.dart';
import 'package:app/core/presentation/widgets/error_display.dart';
import 'package:app/core/presentation/theme/app_colors.dart';
import 'package:app/features/shared/presentation/providers/network_connectivity_provider.dart';
import 'package:gap/gap.dart';

/// Main boarding pass screen with network awareness
class BoardingPassScreen extends HookConsumerWidget {
  const BoardingPassScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAuthState = ref.watch(memberAuthNotifierProvider);
    final boardingPassState = ref.watch(boardingPassNotifierProvider);
    final networkState = ref.watch(networkConnectivityProvider);
    final boardingPassNotifier = ref.read(
      boardingPassNotifierProvider.notifier,
    );

    // Load boarding passes when member is authenticated
    useEffect(() {
      if (memberAuthState.isAuthenticated && memberAuthState.member != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          boardingPassNotifier.loadBoardingPasses();
        });
      }
      return null;
    }, [memberAuthState.isAuthenticated]);

    // Smart refresh - adjust frequency based on network conditions
    useEffect(
      () {
        if (memberAuthState.isAuthenticated) {
          // Reduce refresh frequency when network is poor or offline
          final refreshInterval =
              networkState.isOnline && !networkState.isPoorConnection
              ? const Duration(seconds: 30)
              : const Duration(minutes: 2);

          final timer = Stream.periodic(refreshInterval).listen((_) {
            if (networkState.isOnline) {
              boardingPassNotifier.refresh();
            }
          });
          return timer.cancel;
        }
        return null;
      },
      [
        memberAuthState.isAuthenticated,
        networkState.isOnline,
        networkState.quality,
      ],
    );

    if (!memberAuthState.isAuthenticated) {
      return const NotAuthenticatedView();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          if (networkState.isOnline) {
            await boardingPassNotifier.refresh();
          } else {
            // Show offline message but still try to refresh local data
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('離線模式：顯示本地資料'),
                backgroundColor: AppColors.warning,
                duration: Duration(seconds: 2),
              ),
            );
            await boardingPassNotifier.refresh();
          }
        },
        child: CustomScrollView(
          slivers: [
            // App bar with member info and network status
            SliverAppBar(
              expandedHeight: 180, // Increased height for network status
              floating: false,
              pinned: false,
              backgroundColor: AppColors.primary,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withAlpha(204),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Gap(16),
                          Row(
                            children: [
                              const LogoWidget(
                                width: 28,
                                height: 28,
                                color: Colors.white,
                              ),
                              const Gap(12),
                              Text(
                                'AirlineConnect',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              NetworkStatusIcon(networkState),
                            ],
                          ),
                          const Spacer(),
                          if (memberAuthState.member != null)
                            MemberInfoCard(
                              member: memberAuthState.member!,
                              isCompact: true,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Enhanced network status indicator
            const NetworkStatusSliver(),

            // Content
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: _buildContent(
                context,
                boardingPassState,
                boardingPassNotifier,
                networkState,
                ref,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build main content with network awareness
  Widget _buildContent(
    BuildContext context,
    BoardingPassState state,
    BoardingPassNotifier notifier,
    NetworkConnectivityState networkState,
    WidgetRef ref,
  ) {
    if (state.isLoading && state.boardingPasses.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: LoadingIndicator(
            message: networkState.isOnline ? '載入登機證中...' : '載入本地資料中...',
          ),
        ),
      );
    }

    if (state.hasError && state.boardingPasses.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: ErrorDisplay(
            message: state.errorMessage!,
            onRetry: () => notifier.refresh(),
            // Show different retry text based on network status
            retryText: networkState.isOnline ? '重試' : '重新載入',
          ),
        ),
      );
    }

    if (!state.hasBoardingPasses) {
      return SliverFillRemaining(child: const EmptyState());
    }

    return SliverList(
      delegate: SliverChildListDelegate([
        // Section: Next departure
        if (state.nextDeparture != null) ...[
          SectionHeader(
            title: '即將起飛',
            icon: Icons.schedule,
            color: AppColors.warning,
          ),
          const Gap(12),
          BoardingPassCard(
            boardingPass: state.nextDeparture!,
            isHighlighted: true,
            onTap: () => notifier.selectBoardingPass(state.nextDeparture!),
            onActivate: _canActivatePass(state, networkState)
                ? () =>
                      notifier.activateBoardingPass(state.nextDeparture!.passId)
                : null,
          ),
          if (!networkState.isOnline) const OfflineWarning('登機證啟用需要網路連線'),
          const Gap(24),
        ],

        // Section: Today's flights
        if (state.todayPasses.isNotEmpty) ...[
          SectionHeader(
            title: '今日航班',
            icon: Icons.today,
            color: AppColors.info,
          ),
          const Gap(12),
          ...state.todayPasses.map(
            (pass) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SimpleBoardingPassCard(
                boardingPass: pass,
                onTap: () => notifier.selectBoardingPass(pass),
                onActivate: _canActivatePass(state, networkState)
                    ? () => notifier.activateBoardingPass(pass.passId)
                    : null,
              ),
            ),
          ),
          const Gap(24),
        ],

        // Section: All boarding passes
        SectionHeader(
          title: '所有登機證',
          icon: Icons.list_alt,
          color: AppColors.textSecondary,
        ),
        const Gap(12),
        ...state.boardingPasses.map(
          (pass) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SimpleBoardingPassCard(
              boardingPass: pass,
              onTap: () => notifier.selectBoardingPass(pass),
              onActivate: _canActivatePass(state, networkState)
                  ? () => notifier.activateBoardingPass(pass.passId)
                  : null,
            ),
          ),
        ),

        // Network status summary at bottom
        if (!networkState.isOnline || state.needsSync)
          const BottomNetworkSummary(),

        // Error display at bottom if exists
        if (state.hasError)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: ErrorDisplay(
              message: state.errorMessage!,
              onRetry: () => notifier.clearError(),
              isCompact: true,
            ),
          ),

        // Bottom spacing
        const Gap(32),
      ]),
    );
  }

  /// Check if boarding pass can be activated
  bool _canActivatePass(
    BoardingPassState state,
    NetworkConnectivityState networkState,
  ) {
    return !state.isActivating && networkState.isOnline;
  }
}
