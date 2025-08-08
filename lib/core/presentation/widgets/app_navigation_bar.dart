import 'package:app/features/shared/presentation/widgets/nav_item.dart';
import 'package:app/features/shared/presentation/widgets/profile_nav_item.dart';
import 'package:flutter/material.dart';
import 'package:app/core/presentation/theme/app_colors.dart';

/// Bottom navigation bar for the app
class AppNavigationBar extends StatelessWidget {
  static const Key boardingPassScreenKey = Key('boarding_pass_screen');
  static const Key qrScannerScreenKey = Key('qr_scanner_screen');
  static const Key memberScreenKey = Key('member_screen');

  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isAuthenticated;

  const AppNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.isAuthenticated,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            NavItem(
              key: boardingPassScreenKey,
              index: 0,
              icon: Icons.airplane_ticket_outlined,
              activeIcon: Icons.airplane_ticket,
              label: '登機證',
              isEnabled: isAuthenticated,
              currentIndex: currentIndex,
              onTap: onTap,
            ),
            NavItem(
              key: qrScannerScreenKey,
              index: 1,
              icon: Icons.qr_code_scanner_outlined,
              activeIcon: Icons.qr_code_scanner,
              label: '掃描器',
              isEnabled: isAuthenticated,
              currentIndex: currentIndex,
              onTap: onTap,
            ),
            ProfileNavItem(
              key: memberScreenKey,
              currentIndex: currentIndex,
              onTap: onTap,
              isAuthenticated: isAuthenticated,
            ),
          ],
        ),
      ),
    );
  }
}
