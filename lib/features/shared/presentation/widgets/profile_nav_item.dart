import 'package:app/core/presentation/theme/app_colors.dart';
import 'package:flutter/material.dart';

class ProfileNavItem extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isAuthenticated;

  const ProfileNavItem({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.isAuthenticated,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentIndex == 2;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(2),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    Icon(
                      isAuthenticated ? Icons.person : Icons.person_outline,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    if (!isAuthenticated)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.surface,
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isAuthenticated ? '會員' : '登入',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
