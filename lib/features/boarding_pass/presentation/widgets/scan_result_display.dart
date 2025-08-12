import 'package:flutter/material.dart';
import 'package:app/features/boarding_pass/application/dtos/boarding_pass_operation_dto.dart';
import 'package:app/core/presentation/theme/app_colors.dart';
import 'package:app/features/shared/presentation/utils/date_formatter.dart';
import 'package:gap/gap.dart';

/// Widget for displaying QR scan results
class ScanResultDisplay extends StatelessWidget {
  final QRCodeValidationResponseDTO result;
  final VoidCallback onClear;

  const ScanResultDisplay({
    super.key,
    required this.result,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  result.isValid ? Icons.check_circle : Icons.error,
                  color: result.isValid ? AppColors.success : AppColors.error,
                  size: 24,
                ),
                const Gap(12),
                Expanded(
                  child: Text(
                    result.isValid ? '掃描成功' : '掃描失敗',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: result.isValid
                          ? AppColors.success
                          : AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onClear,
                  icon: const Icon(Icons.close),
                  iconSize: 20,
                ),
              ],
            ),

            const Gap(16),

            if (result.isValid) ...[
              // Valid result details
              _buildResultSection(context, '登機證資訊', [
                _ResultItem('登機證編號', result.passId ?? 'N/A'),
                _ResultItem('航班號碼', result.flightNumber ?? 'N/A'),
                _ResultItem('座位號碼', result.seatNumber ?? 'N/A'),
                _ResultItem('會員號碼', result.memberNumber ?? 'N/A'),
              ]),

              if (result.departureTime != null) ...[
                const Gap(12),
                _buildResultSection(context, '航班時間', [
                  _ResultItem(
                    '起飛時間',
                    DateFormatter.formatDateTime(result.departureTime!),
                  ),
                ]),
              ],

              const Gap(16),

              // Success message
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.success.withAlpha(77)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.verified, color: AppColors.success, size: 20),
                    const Gap(12),
                    Expanded(
                      child: Text(
                        'QR Code 驗證成功，登機證有效',
                        style: TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Invalid result
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.error.withAlpha(77)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: AppColors.error, size: 20),
                        const Gap(12),
                        Text(
                          '驗證失敗',
                          style: TextStyle(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    if (result.errorMessage != null) ...[
                      const Gap(8),
                      Text(
                        result.errorMessage!,
                        style: TextStyle(color: AppColors.error, fontSize: 14),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const Gap(16),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onClear,
                    icon: const Icon(Icons.refresh),
                    label: const Text('重新掃描'),
                  ),
                ),

                if (result.isValid) ...[
                  const Gap(12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Navigate to boarding pass details
                        // This would typically use navigation
                      },
                      icon: const Icon(Icons.airplane_ticket),
                      label: const Text('查看詳情'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build result section
  Widget _buildResultSection(
    BuildContext context,
    String title,
    List<_ResultItem> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.bold,
          ),
        ),

        const Gap(8),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;

              return Column(
                children: [
                  if (index > 0) Divider(height: 16, color: AppColors.border),
                  Row(
                    children: [
                      Text(
                        '${item.label}：',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          item.value,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

/// Helper class for result items
class _ResultItem {
  final String label;
  final String value;

  _ResultItem(this.label, this.value);
}

// Extension for MemberTier display name
extension MemberTierExtension on Object {
  String get displayName {
    final tierName = toString().split('.').last;
    switch (tierName.toLowerCase()) {
      case 'bronze':
        return '銅卡會員';
      case 'silver':
        return '銀卡會員';
      case 'gold':
        return '金卡會員';
      default:
        return '一般會員';
    }
  }

  String get name {
    return toString().split('.').last;
  }
}
