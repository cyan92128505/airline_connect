import 'package:app/core/presentation/theme/app_colors.dart';
import 'package:app/features/boarding_pass/presentation/notifiers/boarding_pass_notifier.dart';
import 'package:app/features/boarding_pass/presentation/providers/connection_status_provider.dart';
import 'package:app/features/boarding_pass/presentation/widgets/additional_info.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class NetworkStatusSliver extends HookConsumerWidget {
  const NetworkStatusSliver({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(connectionStatusProvider);
    final shouldShow = ref.watch(shouldShowStatusProvider);
    final detailMessage = ref.watch(connectionStatusDetailMessageProvider);

    // Only show when there are issues
    if (!shouldShow) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: status.backgroundColor, // Direct property access
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: status.borderColor, // Direct property access
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  status.icon, // Direct property access
                  color: status.iconColor, // Direct property access
                  size: 20,
                ),
                const Gap(8),
                Expanded(
                  child: Text(
                    detailMessage, // Dynamic message from provider
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: status.textColor, // Direct property access
                    ),
                  ),
                ),
                if (status.showSync) // Direct property access
                  TextButton(
                    onPressed: () {
                      ref
                          .read(boardingPassNotifierProvider.notifier)
                          .forceSync();
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                    ),
                    child: const Text('立即同步'),
                  ),
              ],
            ),
            if (status.showAdditionalInfo) ...[
              const Gap(8),
              const AdditionalInfo(),
            ],
          ],
        ),
      ),
    );
  }
}
