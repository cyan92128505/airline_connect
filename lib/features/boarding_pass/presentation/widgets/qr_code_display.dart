import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:app/features/boarding_pass/application/dtos/boarding_pass_dto.dart';
import 'package:app/features/shared/presentation/theme/app_colors.dart';
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
              data: _generateQRData(),
              version: QrVersions.auto,
              size: 200.0,
              backgroundColor: Colors.white,
              eyeStyle: QrEyeStyle(color: Colors.black),
              errorCorrectionLevel: QrErrorCorrectLevel.M,
            ),
          ),

          const Gap(16),

          // QR Code info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.info.withAlpha(77)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.info, size: 16),
                    const Gap(8),
                    Text(
                      'QR Code 資訊',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.info,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),

                const Gap(8),

                _buildInfoRow('版本', 'v${qrCodeData.version}'),
                _buildInfoRow('生成時間', qrCodeData.generatedAt),
                _buildInfoRow(
                  '檢查碼',
                  '${qrCodeData.checksum.substring(0, 8)}...',
                ),

                if (qrCodeData.timeRemainingMinutes != null)
                  _buildInfoRow('剩餘時間', '${qrCodeData.timeRemainingMinutes}分鐘'),
              ],
            ),
          ),

          const Gap(12),

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

  /// Generate QR code data string
  String _generateQRData() {
    // In real implementation, this would be the encrypted payload
    // For demo purposes, we'll create a structured string
    return '${qrCodeData.encryptedPayload}|${qrCodeData.checksum}|${qrCodeData.generatedAt}|${qrCodeData.version}';
  }

  /// Build info row
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label：',
            style: TextStyle(
              color: AppColors.info.withAlpha(204),
              fontSize: 11,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: AppColors.info,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
