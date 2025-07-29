import 'package:app/features/boarding_pass/presentation/widgets/simple_boarding_pass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:app/features/boarding_pass/presentation/notifiers/boarding_pass_notifier.dart';
import 'package:app/features/boarding_pass/presentation/widgets/boarding_pass_card.dart';
import 'package:app/features/member/presentation/notifiers/member_auth_notifier.dart';
import 'package:app/features/member/presentation/widgets/member_info_card.dart';
import 'package:app/features/shared/presentation/widgets/loading_indicator.dart';
import 'package:app/features/shared/presentation/widgets/error_display.dart';
import 'package:app/features/shared/presentation/widgets/offline_indicator.dart';
import 'package:app/features/shared/presentation/theme/app_colors.dart';
import 'package:gap/gap.dart';

/// Main boarding pass screen showing member's passes
class BoardingPassScreen extends HookConsumerWidget {
  const BoardingPassScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberAuthState = ref.watch(memberAuthNotifierProvider);
    final boardingPassState = ref.watch(boardingPassNotifierProvider);
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

    // Auto refresh every 30 seconds for real-time updates
    useEffect(() {
      if (memberAuthState.isAuthenticated) {
        final timer = Stream.periodic(const Duration(seconds: 30)).listen((_) {
          boardingPassNotifier.refresh();
        });
        return timer.cancel;
      }
      return null;
    }, [memberAuthState.isAuthenticated]);

    if (!memberAuthState.isAuthenticated) {
      return _buildNotAuthenticatedView();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          await boardingPassNotifier.refresh();
        },
        child: CustomScrollView(
          slivers: [
            // App bar with member info
            SliverAppBar(
              expandedHeight: 200,
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
                              Icon(
                                Icons.flight_takeoff,
                                color: Colors.white,
                                size: 28,
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

            // Offline indicator
            if (boardingPassState.isOffline)
              const SliverToBoxAdapter(child: OfflineIndicator()),

            // Content
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: _buildContent(
                context,
                boardingPassState,
                boardingPassNotifier,
                ref,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build main content based on state
  Widget _buildContent(
    BuildContext context,
    BoardingPassState state,
    BoardingPassNotifier notifier,
    WidgetRef ref,
  ) {
    if (state.isLoading && state.boardingPasses.isEmpty) {
      return const SliverFillRemaining(
        child: Center(child: LoadingIndicator(message: '載入登機證中...')),
      );
    }

    if (state.hasError && state.boardingPasses.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: ErrorDisplay(
            message: state.errorMessage!,
            onRetry: () => notifier.refresh(),
          ),
        ),
      );
    }

    if (!state.hasBoardingPasses) {
      return SliverFillRemaining(child: _buildEmptyState(context, ref));
    }

    return SliverList(
      delegate: SliverChildListDelegate([
        // Section: Next departure
        if (state.nextDeparture != null) ...[
          _buildSectionHeader(
            context,
            '即將起飛',
            Icons.schedule,
            AppColors.warning,
          ),
          const Gap(12),
          BoardingPassCard(
            boardingPass: state.nextDeparture!,
            isHighlighted: true,
            onTap: () => notifier.selectBoardingPass(state.nextDeparture!),
            onActivate: state.isActivating
                ? null
                : () => notifier.activateBoardingPass(
                    state.nextDeparture!.passId,
                  ),
          ),
          const Gap(24),
        ],

        // Section: Today's flights
        if (state.todayPasses.isNotEmpty) ...[
          _buildSectionHeader(context, '今日航班', Icons.today, AppColors.info),
          const Gap(12),
          ...state.todayPasses.map(
            (pass) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SimpleBoardingPassCard(
                boardingPass: pass,
                onTap: () => notifier.selectBoardingPass(pass),
                onActivate: state.isActivating
                    ? null
                    : () => notifier.activateBoardingPass(pass.passId),
              ),
            ),
          ),
          const Gap(24),
        ],

        // Section: All boarding passes
        _buildSectionHeader(
          context,
          '所有登機證',
          Icons.list_alt,
          AppColors.textSecondary,
        ),
        const Gap(12),
        ...state.boardingPasses.map(
          (pass) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SimpleBoardingPassCard(
              boardingPass: pass,
              onTap: () => notifier.selectBoardingPass(pass),
              onActivate: state.isActivating
                  ? null
                  : () => notifier.activateBoardingPass(pass.passId),
            ),
          ),
        ),

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

  /// Build section header
  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const Gap(8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  /// Build empty state when no boarding passes
  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.airplane_ticket_outlined,
          size: 80,
          color: AppColors.textSecondary.withAlpha(127),
        ),
        const Gap(24),
        Text(
          '尚無登機證',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Gap(12),
        Text(
          '您目前沒有任何登機證\n請聯繫客服或透過官網預訂機票',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
        const Gap(32),
        OutlinedButton.icon(
          onPressed: () {
            // Trigger refresh
            ref.read(boardingPassNotifierProvider.notifier).refresh();
          },
          icon: const Icon(Icons.refresh),
          label: const Text('重新載入'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }

  /// Build not authenticated view
  Widget _buildNotAuthenticatedView() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.login,
              size: 80,
              color: AppColors.textSecondary.withAlpha(127),
            ),
            const Gap(24),
            Text(
              '請先登入會員',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            const Gap(12),
            Text(
              '需要登入會員才能查看登機證',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
