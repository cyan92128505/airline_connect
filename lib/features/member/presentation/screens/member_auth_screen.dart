import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:app/features/member/presentation/notifiers/member_auth_notifier.dart';
import 'package:app/features/member/presentation/widgets/member_auth_form.dart';
import 'package:app/features/shared/presentation/widgets/loading_indicator.dart';
import 'package:app/features/shared/presentation/widgets/error_display.dart';
import 'package:app/features/shared/presentation/theme/app_colors.dart';
import 'package:gap/gap.dart';

/// Member authentication screen for login
class MemberAuthScreen extends HookConsumerWidget {
  static const Key errorMessageKey = Key('error_message');
  static const Key validationErrorKey = Key('validation_error');
  static const Key successMessageKey = Key('success_message');

  const MemberAuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(memberAuthNotifierProvider);
    final authNotifier = ref.read(memberAuthNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              // Authentication form
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const Gap(60),

                      // Header section
                      _buildHeader(),

                      const Gap(48),
                      // Form card
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                '會員登入',
                                style: Theme.of(context).textTheme.headlineSmall
                                    ?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                textAlign: TextAlign.center,
                              ),

                              const Gap(8),

                              Text(
                                '請輸入會員號碼和姓名後四碼進行驗證',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppColors.textSecondary),
                                textAlign: TextAlign.center,
                              ),

                              const Gap(32),

                              // Authentication form
                              MemberAuthForm(
                                isLoading: authState.isLoading,
                                onSubmit: (memberNumber, nameSuffix) {
                                  authNotifier.authenticateMember(
                                    memberNumber: memberNumber,
                                    nameSuffix: nameSuffix,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Gap(24),

                      // Error display
                      if (authState.hasError)
                        ErrorDisplay(
                          key: errorMessageKey,
                          message: authState.errorMessage!,
                          onRetry: () => authNotifier.clearError(),
                        ),

                      // Loading indicator
                      if (authState.isLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 24),
                          child: LoadingIndicator(message: '正在驗證會員身份...'),
                        ),

                      const Gap(32),

                      // Help section
                      _buildHelpSection(context),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build header with logo and title
  Widget _buildHeader() {
    return Column(
      children: [
        // App logo placeholder
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.flight_takeoff,
            color: Colors.white,
            size: 40,
          ),
        ),

        const Gap(16),

        Text(
          'Airline Connect',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),

        const Gap(8),

        Text(
          '航空登機牌管理系統',
          style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  /// Build help section with demo credentials
  Widget _buildHelpSection(BuildContext context) {
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
                Icon(Icons.info_outline, color: AppColors.info, size: 20),
                const Gap(8),
                Text(
                  '測試帳號',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.info,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const Gap(12),

            _buildCredentialRow(context, '會員號碼：', 'AA123456'),

            const Gap(8),

            _buildCredentialRow(context, '姓名後四碼：', 'Aoma'),

            const Gap(12),

            Text(
              '※ 此為展示用帳號，實際使用請聯繫客服',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build credential display row
  Widget _buildCredentialRow(BuildContext context, String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}
