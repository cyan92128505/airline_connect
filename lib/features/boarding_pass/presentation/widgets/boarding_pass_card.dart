import 'package:flutter/material.dart';
import 'package:app/features/boarding_pass/application/dtos/boarding_pass_dto.dart';
import 'package:app/features/boarding_pass/presentation/widgets/qr_code_display.dart';
import 'package:app/features/boarding_pass/presentation/widgets/flight_info_section.dart';
import 'package:app/features/boarding_pass/presentation/widgets/passenger_info_section.dart';
import 'package:app/features/shared/presentation/utils/date_formatter.dart';
import 'package:app/features/shared/presentation/utils/status_helpers.dart';
import 'package:app/features/shared/presentation/theme/app_colors.dart';
import 'package:gap/gap.dart';

/// Widget for displaying boarding pass information
class BoardingPassCard extends StatelessWidget {
  final BoardingPassDTO boardingPass;
  final bool isHighlighted;
  final VoidCallback? onTap;
  final VoidCallback? onActivate;
  final bool showQRCode;
  final bool isCompact;

  const BoardingPassCard({
    super.key,
    required this.boardingPass,
    this.isHighlighted = false,
    this.onTap,
    this.onActivate,
    this.showQRCode = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isHighlighted ? 8 : 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isHighlighted
            ? BorderSide(color: AppColors.warning, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isHighlighted
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.warning.withAlpha(25),
                      AppColors.warning.withAlpha(12),
                    ],
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with status and actions
                _buildHeader(context),

                if (!isCompact) ...[
                  const Gap(20),

                  // Flight information
                  FlightInfoSection(
                    flightNumber: boardingPass.flightNumber,
                    scheduleSnapshot: boardingPass.scheduleSnapshot,
                    seatNumber: boardingPass.seatNumber,
                  ),

                  const Gap(16),

                  // Passenger information
                  PassengerInfoSection(boardingPass: boardingPass),

                  if (showQRCode && boardingPass.isActive == true) ...[
                    const Gap(20),

                    // QR Code section
                    QRCodeDisplay(
                      qrCodeData: boardingPass.qrCode,
                      passId: boardingPass.passId,
                    ),
                  ],

                  if (boardingPass.isActive != true && onActivate != null) ...[
                    const Gap(20),

                    // Activation button
                    _buildActivationButton(context),
                  ],

                  const Gap(16),

                  // DDD Architecture info
                  _buildArchitectureInfo(context),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build card header with status and flight info
  Widget _buildHeader(BuildContext context) {
    final statusColor = StatusHelpers.getStatusColor(boardingPass.status);
    final statusText = StatusHelpers.getStatusText(boardingPass.status);

    return Row(
      children: [
        // Flight number and route
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    boardingPass.flightNumber,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  if (isHighlighted) ...[
                    const Gap(8),
                    Icon(Icons.star, color: AppColors.warning, size: 20),
                  ],
                ],
              ),

              const Gap(4),

              Text(
                '${boardingPass.scheduleSnapshot.departure} → ${boardingPass.scheduleSnapshot.arrival}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const Gap(4),

              Text(
                DateFormatter.formatFlightTime(
                  boardingPass.scheduleSnapshot.departureTime,
                ),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        // Status badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withAlpha(25),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: statusColor.withAlpha(77)),
          ),
          child: Text(
            statusText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  /// Build activation button for inactive passes
  Widget _buildActivationButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onActivate,
        icon: const Icon(Icons.play_arrow),
        label: const Text('啟用登機證'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  /// Build DDD architecture information section
  Widget _buildArchitectureInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.info.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.info.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.architecture, size: 16, color: AppColors.info),
              const Gap(6),
              Text(
                'DDD 架構展示',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.info,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const Gap(8),

          _buildArchitecturePoint(context, '聚合邊界：', 'BoardingPass 獨立聚合'),

          const Gap(4),

          _buildArchitecturePoint(
            context,
            '弱參考策略：',
            '透過 MemberNumber/FlightNumber 參考',
          ),

          const Gap(4),

          _buildArchitecturePoint(context, '快照模式：', '航班時刻表快照確保資料獨立性'),

          if (boardingPass.scheduleSnapshot.snapshotTime.isNotEmpty) ...[
            const Gap(4),
            _buildArchitecturePoint(
              context,
              '快照時間：',
              DateFormatter.formatDateTime(
                boardingPass.scheduleSnapshot.snapshotTime,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build single architecture point
  Widget _buildArchitecturePoint(
    BuildContext context,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.info,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.info.withAlpha(204),
            ),
          ),
        ),
      ],
    );
  }
}
