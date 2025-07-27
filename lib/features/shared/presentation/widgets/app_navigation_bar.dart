import 'package:flutter/material.dart';
import 'package:app/features/shared/presentation/theme/app_colors.dart';

/// Bottom navigation bar for the app
class AppNavigationBar extends StatelessWidget {
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
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: onTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.normal,
          ),
          items: [
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  const Icon(Icons.airplane_ticket_outlined),
                  if (!isAuthenticated)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.warning,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              activeIcon: const Icon(Icons.airplane_ticket),
              label: '登機證',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner_outlined),
              activeIcon: Icon(Icons.qr_code_scanner),
              label: '掃描器',
            ),
            BottomNavigationBarItem(
              icon: Stack(
                children: [
                  Icon(isAuthenticated ? Icons.person : Icons.person_outline),
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
              activeIcon: Icon(
                isAuthenticated ? Icons.person : Icons.person_outline,
              ),
              label: isAuthenticated ? '會員' : '登入',
            ),
          ],
        ),
      ),
    );
  }
}
