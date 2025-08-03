import 'package:flutter/material.dart';
import 'package:app/core/presentation/theme/app_colors.dart';

/// Loading indicator widget with optional message
class LoadingIndicator extends StatelessWidget {
  final String? message;
  final bool isCompact;

  const LoadingIndicator({super.key, this.message, this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          if (message != null) ...[
            const SizedBox(width: 12),
            Text(
              message!,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
        if (message != null) ...[
          const SizedBox(height: 16),
          Text(
            message!,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}
