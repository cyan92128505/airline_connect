import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:app/features/boarding_pass/application/dtos/boarding_pass_dto.dart';
import 'package:app/core/presentation/theme/app_colors.dart';
import 'package:gap/gap.dart';

/// Widget for displaying QR code
class QRCodeDisplay extends StatelessWidget {
  final QRCodeDataDTO qrCodeData;
  final String passId;

  const QRCodeDisplay({
    super.key,
    required this.qrCodeData,
    required this.passId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                child: Row(
                  children: [
                    Icon(Icons.qr_code, color: AppColors.primary, size: 24),
                    const Gap(8),
                    Text(
                      '登機 QR Code',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              if (qrCodeData.isValid)
                Positioned(
                  right: -5,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withAlpha(25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.success.withAlpha(77),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                              size: 12,
                            ),
                            const Gap(4),
                            Text(
                              '有效',
                              style: TextStyle(
                                color: AppColors.success,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const Gap(20),

          // QR Code
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: QrImageView(
              data: qrCodeData.qrString ?? '',
              version: QrVersions.auto,
              size: 200.0,
              backgroundColor: Colors.white,
              eyeStyle: QrEyeStyle(color: Colors.black),
              errorCorrectionLevel: QrErrorCorrectLevel.M,
            ),
          ),

          const Gap(16),

          // Warning for offline mode
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.warning.withAlpha(25),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(Icons.wifi_off, color: AppColors.warning, size: 14),
                const Gap(6),
                Expanded(
                  child: Text(
                    '離線模式下顯示快照資料',
                    style: TextStyle(color: AppColors.warning, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
