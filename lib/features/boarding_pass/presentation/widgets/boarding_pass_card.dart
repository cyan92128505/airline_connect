import 'dart:math';

import 'package:app/features/boarding_pass/domain/enums/pass_status.dart';
import 'package:flutter/material.dart';
import 'package:app/features/boarding_pass/application/dtos/boarding_pass_dto.dart';
import 'package:app/features/boarding_pass/presentation/widgets/qr_code_display.dart';
import 'package:app/features/shared/presentation/utils/date_formatter.dart';
import 'package:app/core/presentation/theme/app_colors.dart';
import 'package:gap/gap.dart';

/// Widget for displaying boarding pass information
class BoardingPassCard extends StatelessWidget {
  final BoardingPassDTO boardingPass;
  final bool isUrgent;
  final VoidCallback? onTap;
  final VoidCallback? onActivate;
  final VoidCallback? onViewDetails;
  final bool showQRCode;

  const BoardingPassCard({
    super.key,
    required this.boardingPass,
    this.isUrgent = false,
    this.onTap,
    this.onActivate,
    this.onViewDetails,
    this.showQRCode = true,
  });

  @override
  Widget build(BuildContext context) {
    final status = boardingPass.status;
    final isActivated = status.allowsBoarding;
    final timeToFlight = _getTimeToFlight();

    return Card(
      elevation: isUrgent ? 6 : 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isUrgent
            ? BorderSide(color: AppColors.warning, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: isUrgent
                ? LinearGradient(
                    colors: [
                      AppColors.warning.withAlpha(15),
                      Colors.transparent,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Flight header with status
                _buildFlightHeader(context, status),

                const Gap(16),

                // Flight route and timing
                _buildFlightRoute(context),

                const Gap(12),

                // Critical flight information
                _buildFlightDetails(context),

                // Time alerts for urgent flights
                if (timeToFlight != null && timeToFlight.inHours < 3)
                  _buildTimeAlert(context, timeToFlight),

                // Flight status alerts
                if (_hasFlightAlerts()) _buildFlightAlerts(context),

                const Gap(16),

                // Passenger and seat information
                _buildPassengerInfo(context),

                // QR Code for activated passes
                if (showQRCode &&
                    isActivated &&
                    boardingPass.qrCode.isValid) ...[
                  const Gap(16),
                  QRCodeDisplay(
                    qrCodeData: boardingPass.qrCode,
                    passId: boardingPass.passId,
                  ),
                ],

                const Gap(16),

                // Action buttons
                _buildActionButtons(context, isActivated),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build flight header with airline and status
  Widget _buildFlightHeader(BuildContext context, PassStatus status) {
    return Row(
      children: [
        // Airline logo placeholder and flight number
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.flight, color: AppColors.primary, size: 24),
        ),

        const Gap(12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                boardingPass.flightNumber,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const Gap(2),

              Text(
                _getAirlineName(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),

        // Status badge
        _buildStatusBadge(context, status),
      ],
    );
  }

  /// Build flight route with departure and arrival
  Widget _buildFlightRoute(BuildContext context) {
    return Row(
      children: [
        // Departure
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                boardingPass.scheduleSnapshot.departure,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const Gap(4),

              Text(
                DateFormatter.formatTime(
                  boardingPass.scheduleSnapshot.departureTime,
                ),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),

              Text(
                DateFormatter.formatDate(
                  boardingPass.scheduleSnapshot.departureTime,
                ),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),

        // Flight path with duration
        Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withAlpha(100),
                            AppColors.primary,
                          ],
                        ),
                      ),
                    ),
                  ),

                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Transform.rotate(
                      angle: 90 * pi / 180,
                      child: Icon(Icons.flight, color: Colors.white, size: 16),
                    ),
                  ),

                  Expanded(
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withAlpha(100),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const Gap(8),

              Text(
                _getFlightDuration(),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),

        // Arrival
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                boardingPass.scheduleSnapshot.arrival,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const Gap(4),

              Text(
                _getArrivalTime(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),

              Text(
                '預計抵達',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build critical flight details
  Widget _buildFlightDetails(BuildContext context) {
    return Row(
      children: [
        _buildDetailItem(
          context,
          '登機門',
          boardingPass.scheduleSnapshot.gate,
          Icons.door_front_door,
          AppColors.primary,
        ),

        const Gap(24),

        _buildDetailItem(
          context,
          '座位',
          boardingPass.seatNumber,
          Icons.airline_seat_recline_normal,
          AppColors.secondary,
        ),

        const Gap(24),

        _buildDetailItem(
          context,
          '登機時間',
          DateFormatter.formatTime(boardingPass.scheduleSnapshot.boardingTime),
          Icons.schedule,
          AppColors.textSecondary,
        ),
      ],
    );
  }

  /// Build detail item
  Widget _buildDetailItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),

        const Gap(4),

        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),

        const Gap(2),

        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  /// Build time alert for urgent flights
  Widget _buildTimeAlert(BuildContext context, Duration timeToFlight) {
    final hours = timeToFlight.inHours;
    final minutes = timeToFlight.inMinutes.remainder(60);

    Color alertColor;
    IconData alertIcon;
    String alertText;

    if (timeToFlight.inMinutes < 30) {
      alertColor = AppColors.error;
      alertIcon = Icons.warning;
      alertText = '登機即將結束！';
    } else if (timeToFlight.inMinutes < 90) {
      alertColor = AppColors.warning;
      alertIcon = Icons.schedule;
      alertText = '準備登機';
    } else {
      alertColor = AppColors.info;
      alertIcon = Icons.info_outline;
      alertText = '即將起飛';
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: alertColor.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: alertColor.withAlpha(77)),
      ),
      child: Row(
        children: [
          Icon(alertIcon, color: alertColor, size: 18),

          const Gap(8),

          Expanded(
            child: Text(
              '$alertText（$hours小時$minutes分鐘後起飛）',
              style: TextStyle(
                color: alertColor,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build flight status alerts
  Widget _buildFlightAlerts(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.warning.withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications_active,
                color: AppColors.warning,
                size: 18,
              ),

              const Gap(8),

              Text(
                '航班狀態更新',
                style: TextStyle(
                  color: AppColors.warning,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),

          const Gap(8),

          // Mock flight alerts - in real app, these would come from live data
          Text(
            '• 登機門由 A12 變更至 ${boardingPass.scheduleSnapshot.gate}',
            style: TextStyle(color: AppColors.warning, fontSize: 13),
          ),

          Text(
            '• 預計延誤 15 分鐘起飛',
            style: TextStyle(color: AppColors.warning, fontSize: 13),
          ),
        ],
      ),
    );
  }

  /// Build passenger information
  Widget _buildPassengerInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.person, color: AppColors.textSecondary, size: 20),

          const Gap(12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '登機證：${boardingPass.passId}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),

                const Gap(2),

                Text(
                  '會員：${boardingPass.memberNumber}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Seat type indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getSeatTypeColor().withAlpha(25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _getSeatTypeColor().withAlpha(77)),
            ),
            child: Text(
              _getSeatTypeText(),
              style: TextStyle(
                color: _getSeatTypeColor(),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build action buttons
  Widget _buildActionButtons(BuildContext context, bool isActivated) {
    if (isActivated) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onViewDetails,
              icon: const Icon(Icons.info_outline, size: 18),
              label: const Text('查看詳情'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          const Gap(12),

          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _showQRFullScreen(context),
              icon: const Icon(Icons.qr_code_scanner, size: 18),
              label: const Text('顯示 QR'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      );
    } else {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onActivate,
          icon: const Icon(Icons.play_arrow),
          label: const Text('啟用登機證'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      );
    }
  }

  /// Build status badge
  Widget _buildStatusBadge(BuildContext context, PassStatus status) {
    final statusColor = status.displayColor;
    final statusText = status.displayName;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withAlpha(77)),
      ),
      child: Text(
        statusText,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: statusColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // Helper methods for business logic

  String _getAirlineName() {
    final airlineCode = boardingPass.flightNumber.substring(0, 2);
    switch (airlineCode) {
      case 'CI':
        return '中華航空';
      case 'BR':
        return '長榮航空';
      case 'JX':
        return '星宇航空';
      case 'IT':
        return '台灣虎航';
      default:
        return '航空公司';
    }
  }

  Duration? _getTimeToFlight() {
    try {
      final now = DateTime.now();
      final departureTime = DateTime.parse(
        boardingPass.scheduleSnapshot.departureTime,
      );
      final difference = departureTime.difference(now);
      return difference.isNegative ? null : difference;
    } catch (e) {
      return null;
    }
  }

  String _getFlightDuration() {
    // Mock flight duration - in real app, calculate from departure/arrival times
    return '2小時15分';
  }

  String _getArrivalTime() {
    try {
      final departureTime = DateTime.parse(
        boardingPass.scheduleSnapshot.departureTime,
      );
      final arrivalTime = departureTime.add(
        const Duration(hours: 2, minutes: 15),
      );
      return DateFormatter.formatTime(arrivalTime.toIso8601String());
    } catch (e) {
      return '預計時間';
    }
  }

  bool _hasFlightAlerts() {
    // Mock alerts - in real app, check against live flight data
    return isUrgent || boardingPass.scheduleSnapshot.gate != 'A12';
  }

  Color _getSeatTypeColor() {
    final seatLetter = boardingPass.seatNumber.substring(
      boardingPass.seatNumber.length - 1,
    );
    if (['A', 'F'].contains(seatLetter)) {
      return AppColors.info; // Window seat
    } else if (['C', 'D'].contains(seatLetter)) {
      return AppColors.warning; // Aisle seat
    } else {
      return AppColors.textSecondary; // Middle seat
    }
  }

  String _getSeatTypeText() {
    final seatLetter = boardingPass.seatNumber.substring(
      boardingPass.seatNumber.length - 1,
    );
    if (['A', 'F'].contains(seatLetter)) {
      return '靠窗';
    } else if (['C', 'D'].contains(seatLetter)) {
      return '靠走道';
    } else {
      return '中間';
    }
  }

  void _showQRFullScreen(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QRCodeDisplay(
              qrCodeData: boardingPass.qrCode,
              passId: boardingPass.passId,
            ),

            const Gap(16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [const Text('關閉')],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
