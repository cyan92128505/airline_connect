import 'package:app/core/presentation/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class NotAuthenticatedView extends StatelessWidget {
  const NotAuthenticatedView({super.key});

  @override
  Widget build(BuildContext context) {
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
