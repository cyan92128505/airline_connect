import 'package:flutter/material.dart';
import 'package:app/features/boarding_pass/application/dtos/boarding_pass_dto.dart';
import 'package:app/features/shared/presentation/utils/date_formatter.dart';
import 'package:app/features/shared/presentation/theme/app_colors.dart';
import 'package:gap/gap.dart';

/// Widget for displaying flight information section
class FlightInfoSection extends StatelessWidget {
  final String flightNumber;
  final FlightScheduleSnapshotDTO scheduleSnapshot;
  final String seatNumber;

  const FlightInfoSection({
    super.key,
    required this.flightNumber,
    required this.scheduleSnapshot,
    required this.seatNumber,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section title
          Row(
            children: [
              Icon(Icons.flight_takeoff, color: AppColors.primary, size: 20),
              const Gap(8),
              Text(
                '航班資訊',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const Gap(16),

          // Flight route with airplane icon
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      scheduleSnapshot.departure,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const Gap(4),
                    Text(
                      DateFormatter.formatTime(scheduleSnapshot.departureTime),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow with flight icon
              Expanded(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: Divider(color: AppColors.border)),
                        Icon(Icons.flight, color: AppColors.primary, size: 20),
                        Expanded(child: Divider(color: AppColors.border)),
                      ],
                    ),
                    const Gap(4),
                    Text(
                      flightNumber,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: Column(
                  children: [
                    Text(
                      scheduleSnapshot.arrival,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const Gap(4),
                    Text(
                      '預計抵達',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Gap(20),

          // Flight details
          Row(
            children: [
              // Boarding time
              Expanded(
                child: _buildDetailItem(
                  context,
                  '登機時間',
                  DateFormatter.formatTime(scheduleSnapshot.boardingTime),
                  Icons.access_time,
                ),
              ),

              // Gate
              Expanded(
                child: _buildDetailItem(
                  context,
                  '登機門',
                  scheduleSnapshot.gate,
                  Icons.door_front_door,
                ),
              ),

              // Seat
              Expanded(
                child: _buildDetailItem(
                  context,
                  '座位',
                  seatNumber,
                  Icons.airline_seat_recline_normal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build detail item
  Widget _buildDetailItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 20),
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
}
