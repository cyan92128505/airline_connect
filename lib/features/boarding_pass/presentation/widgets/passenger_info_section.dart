import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:app/features/boarding_pass/application/dtos/boarding_pass_dto.dart';
import 'package:app/features/shared/presentation/utils/date_formatter.dart';
import 'package:app/core/presentation/theme/app_colors.dart';

/// Widget for displaying passenger information section
class PassengerInfoSection extends StatelessWidget {
  final BoardingPassDTO boardingPass;

  const PassengerInfoSection({super.key, required this.boardingPass});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Row(
            children: [
              Icon(Icons.person, color: AppColors.secondary, size: 20),
              const Gap(8),
              Text(
                '乘客資訊',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const Gap(16),

          // Passenger details
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  context,
                  '登機證編號',
                  boardingPass.passId,
                  Icons.confirmation_number,
                ),
              ),

              Expanded(
                child: _buildInfoItem(
                  context,
                  '會員號碼',
                  boardingPass.memberNumber,
                  Icons.badge,
                ),
              ),
            ],
          ),

          const Gap(16),

          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  context,
                  '發行時間',
                  DateFormatter.formatDateTime(boardingPass.issueTime),
                  Icons.schedule,
                ),
              ),

              if (boardingPass.activatedAt != null)
                Expanded(
                  child: _buildInfoItem(
                    context,
                    '啟用時間',
                    DateFormatter.formatDateTime(boardingPass.activatedAt!),
                    Icons.check_circle,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build info item
  Widget _buildInfoItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 16),
        const Gap(8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              const Gap(2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
