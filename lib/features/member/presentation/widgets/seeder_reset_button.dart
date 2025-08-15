import 'package:app/core/presentation/theme/app_colors.dart';
import 'package:app/features/member/presentation/notifiers/member_auth_notifier.dart';
import 'package:app/features/shared/presentation/routes/app_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SeederResetButton extends HookConsumerWidget {
  const SeederResetButton({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authNotifier = ref.read(memberAuthNotifierProvider.notifier);

    final goToSplash = useCallback(() {
      context.go(AppRoutes.splash);
    });

    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.error_outline_outlined,
                  color: AppColors.error,
                  size: 20,
                ),
                const Gap(8),
                Text(
                  '重新設置資料',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const Gap(8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.error),
              ),
              onPressed: () async {
                await authNotifier.seederReset();
                goToSplash();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'RESET',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
