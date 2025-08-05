import 'package:app/core/presentation/theme/app_colors.dart';
import 'package:app/features/boarding_pass/presentation/notifiers/boarding_pass_notifier.dart';
import 'package:app/features/shared/presentation/providers/network_connectivity_provider.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class EmptyState extends HookConsumerWidget {
  const EmptyState({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networkState = ref.watch(networkConnectivityProvider);
    return Center(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
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
              networkState.isOnline
                  ? '您目前沒有任何登機證\n請聯繫客服或透過官網預訂機票'
                  : '離線模式下沒有找到登機證\n請連接網路後重新載入',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const Gap(32),
            OutlinedButton.icon(
              onPressed: () {
                ref.read(boardingPassNotifierProvider.notifier).refresh();
              },
              icon: const Icon(Icons.refresh),
              label: Text(networkState.isOnline ? '重新載入' : '重新載入本地資料'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
