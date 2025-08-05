import 'package:app/core/presentation/theme/app_colors.dart';
import 'package:app/features/boarding_pass/presentation/notifiers/boarding_pass_notifier.dart';
import 'package:app/features/shared/presentation/providers/network_connectivity_provider.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class BottomNetworkSummary extends HookConsumerWidget {
  const BottomNetworkSummary({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardingPassState = ref.watch(boardingPassNotifierProvider);
    final networkState = ref.watch(networkConnectivityProvider);
    final notifier = ref.read(boardingPassNotifierProvider.notifier);

    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '網路狀態摘要',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Gap(8),
          Text(
            notifier.getNetworkStatusDescription(),
            style: TextStyle(color: AppColors.textSecondary),
          ),
          if (boardingPassState.needsSync && networkState.isOnline) ...[
            const Gap(12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => notifier.forceSync(),
                icon: Icon(Icons.sync),
                label: Text('立即同步'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
