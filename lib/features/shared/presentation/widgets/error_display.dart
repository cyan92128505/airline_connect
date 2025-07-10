import 'package:flutter/material.dart';
import 'package:app/features/shared/presentation/theme/app_colors.dart';

/// Error display widget with retry option
class ErrorDisplay extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final bool isCompact;

  const ErrorDisplay({
    super.key,
    required this.message,
    this.onRetry,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.error.withAlpha(25),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.error.withAlpha(77)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.error, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: AppColors.error, fontSize: 14),
              ),
            ),
            if (onRetry != null)
              TextButton(
                onPressed: onRetry,
                child: Text(
                  '重試',
                  style: TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ),
          ],
        ),
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline, color: AppColors.error, size: 64),
        const SizedBox(height: 16),
        Text(
          '發生錯誤',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(color: AppColors.error),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('重試'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ],
    );
  }
}
