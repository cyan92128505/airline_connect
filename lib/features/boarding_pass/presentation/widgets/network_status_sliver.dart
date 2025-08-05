import 'package:app/core/presentation/theme/app_colors.dart';
import 'package:app/features/boarding_pass/presentation/helpers/network_status_styling_helper.dart';
import 'package:app/features/boarding_pass/presentation/notifiers/boarding_pass_notifier.dart';
import 'package:app/features/boarding_pass/presentation/widgets/additional_info.dart';
import 'package:app/features/shared/presentation/providers/network_connectivity_provider.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class NetworkStatusSliver extends HookConsumerWidget {
  const NetworkStatusSliver({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardingPassState = ref.watch(boardingPassNotifierProvider);
    final networkState = ref.watch(networkConnectivityProvider);
    final boardingPassNotifier = ref.read(
      boardingPassNotifierProvider.notifier,
    );

    // Show detailed network status only when there are issues or pending operations
    if (networkState.isOnline &&
        networkState.isStable &&
        !boardingPassState.needsSync) {
      return SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: getStatusBackgroundColor(networkState, boardingPassState),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: getStatusBorderColor(networkState, boardingPassState),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  getStatusIcon(networkState, boardingPassState),
                  color: getStatusIconColor(networkState, boardingPassState),
                  size: 20,
                ),
                const Gap(8),
                Expanded(
                  child: Text(
                    getDetailedStatusText(networkState, boardingPassState),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: getStatusTextColor(
                        networkState,
                        boardingPassState,
                      ),
                    ),
                  ),
                ),
                if (boardingPassState.needsSync && networkState.isOnline)
                  TextButton(
                    onPressed: () => boardingPassNotifier.forceSync(),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                    ),
                    child: Text('立即同步'),
                  ),
              ],
            ),
            if (shouldShowAdditionalInfo(networkState, boardingPassState)) ...[
              const Gap(8),
              const AdditionalInfo(),
            ],
          ],
        ),
      ),
    );
  }
}
