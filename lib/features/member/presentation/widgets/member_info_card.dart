import 'package:flutter/material.dart';
import 'package:app/features/member/application/dtos/member_dto.dart';
import 'package:app/features/shared/presentation/theme/app_colors.dart';
import 'package:app/features/shared/presentation/utils/date_formatter.dart';
import 'package:gap/gap.dart';

/// Widget for displaying member information
class MemberInfoCard extends StatelessWidget {
  final MemberDTO member;
  final bool isCompact;

  const MemberInfoCard({
    super.key,
    required this.member,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return _buildCompactCard(context);
    }

    return _buildFullCard(context);
  }

  /// Build compact member card for app bar
  Widget _buildCompactCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(51)),
      ),
      child: Row(
        children: [
          // Member tier icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.getTierColor(member.tier.name),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getTierIcon(member.tier.name),
              color: Colors.white,
              size: 18,
            ),
          ),

          const Gap(12),

          // Member info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.fullName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${member.memberNumber} • ${member.tier.displayName}',
                  style: TextStyle(
                    color: Colors.white.withAlpha(204),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build full member card
  Widget _buildFullCard(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: AppColors.getTierGradient(member.tier.name),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  // Tier badge
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(51),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getTierIcon(member.tier.name),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),

                  const Gap(16),

                  // Member info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.fullName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Gap(4),
                        Text(
                          '${member.tier.displayName} 會員',
                          style: TextStyle(
                            color: Colors.white.withAlpha(229),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const Gap(20),

              // Member details
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildDetailRow(
                      context,
                      '會員號碼',
                      member.memberNumber,
                      Icons.badge,
                    ),

                    const Gap(12),

                    _buildDetailRow(context, '電子信箱', member.email, Icons.email),

                    const Gap(12),

                    _buildDetailRow(context, '聯絡電話', member.phone, Icons.phone),

                    if (member.lastLoginAt != null) ...[
                      const Gap(12),
                      _buildDetailRow(
                        context,
                        '最後登入',
                        DateFormatter.formatDateTime(member.lastLoginAt!),
                        Icons.access_time,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build detail row
  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(icon, color: Colors.white.withAlpha(179), size: 16),
        const Gap(8),
        Text(
          '$label：',
          style: TextStyle(color: Colors.white.withAlpha(179), fontSize: 12),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  /// Get icon for member tier
  IconData _getTierIcon(String tier) {
    switch (tier.toLowerCase()) {
      case 'gold':
        return Icons.star;
      case 'silver':
        return Icons.star_half;
      case 'bronze':
        return Icons.star_border;
      default:
        return Icons.person;
    }
  }
}
