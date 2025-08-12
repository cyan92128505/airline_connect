import 'package:flutter/material.dart';
import 'package:app/core/presentation/theme/app_colors.dart';

/// Types of errors that can be displayed
enum ErrorType { general, permission, network, validation, camera }

/// Widget for displaying errors with appropriate actions
class ErrorDisplay extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onOpenSettings;
  final ErrorType type;
  final IconData? customIcon;
  final String? retryLabel;
  final String? settingsLabel;

  const ErrorDisplay({
    super.key,
    required this.message,
    this.onRetry,
    this.onOpenSettings,
    this.type = ErrorType.general,
    this.customIcon,
    this.retryLabel,
    this.settingsLabel,
  });

  /// Factory for permission-related errors
  factory ErrorDisplay.permission({
    required String message,
    VoidCallback? onRetry,
    VoidCallback? onOpenSettings,
  }) {
    return ErrorDisplay(
      message: message,
      onRetry: onRetry,
      onOpenSettings: onOpenSettings,
      type: ErrorType.permission,
    );
  }

  /// Factory for camera-related errors
  factory ErrorDisplay.camera({
    required String message,
    VoidCallback? onRetry,
    VoidCallback? onOpenSettings,
  }) {
    return ErrorDisplay(
      message: message,
      onRetry: onRetry,
      onOpenSettings: onOpenSettings,
      type: ErrorType.camera,
    );
  }

  /// Factory for network-related errors
  factory ErrorDisplay.network({
    required String message,
    VoidCallback? onRetry,
  }) {
    return ErrorDisplay(
      message: message,
      onRetry: onRetry,
      type: ErrorType.network,
    );
  }

  @override
  Widget build(BuildContext context) {
    final errorConfig = _getErrorConfig();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: errorConfig.color.withAlpha(25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: errorConfig.color.withAlpha(77),
                  width: 2,
                ),
              ),
              child: Icon(
                customIcon ?? errorConfig.icon,
                size: 40,
                color: errorConfig.color,
              ),
            ),

            const SizedBox(height: 24),

            // Error title
            Text(
              errorConfig.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: errorConfig.color,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Error message
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Action buttons
            _buildActionButtons(context, errorConfig),
          ],
        ),
      ),
    );
  }

  /// Build action buttons based on error type
  Widget _buildActionButtons(BuildContext context, _ErrorConfig config) {
    final buttons = <Widget>[];

    // Add retry button if callback provided
    if (onRetry != null) {
      buttons.add(
        ElevatedButton.icon(
          onPressed: onRetry,
          icon: Icon(config.retryIcon),
          label: Text(retryLabel ?? config.retryLabel),
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: config.color,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      );
    }

    // Add settings button for permission errors
    if (onOpenSettings != null &&
        (type == ErrorType.permission || type == ErrorType.camera)) {
      if (buttons.isNotEmpty) buttons.add(const SizedBox(height: 12));

      buttons.add(
        OutlinedButton.icon(
          onPressed: onOpenSettings,
          icon: const Icon(Icons.settings),
          label: Text(settingsLabel ?? '開啟設定'),
          style: OutlinedButton.styleFrom(
            foregroundColor: config.color,
            side: BorderSide(color: config.color),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      );
    }

    // If no buttons, show a default info message
    if (buttons.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: config.color.withAlpha(25),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: config.color.withAlpha(77)),
        ),
        child: Text(
          config.helpText,
          style: TextStyle(color: config.color, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(mainAxisSize: MainAxisSize.min, children: buttons);
  }

  /// Get error configuration based on type
  _ErrorConfig _getErrorConfig() {
    return switch (type) {
      ErrorType.permission => _ErrorConfig(
        icon: Icons.security,
        color: AppColors.warning,
        title: '權限需求',
        retryIcon: Icons.refresh,
        retryLabel: '重新檢查',
        helpText: '應用程式需要相關權限才能正常運作',
      ),
      ErrorType.camera => _ErrorConfig(
        icon: Icons.camera_alt_outlined,
        color: AppColors.warning,
        title: '相機問題',
        retryIcon: Icons.camera_enhance,
        retryLabel: '重新啟動',
        helpText: '請檢查相機權限或嘗試重新啟動相機',
      ),
      ErrorType.network => _ErrorConfig(
        icon: Icons.wifi_off,
        color: AppColors.info,
        title: '網路問題',
        retryIcon: Icons.refresh,
        retryLabel: '重試',
        helpText: '請檢查網路連線並重新嘗試',
      ),
      ErrorType.validation => _ErrorConfig(
        icon: Icons.warning,
        color: AppColors.warning,
        title: '驗證錯誤',
        retryIcon: Icons.refresh,
        retryLabel: '重試',
        helpText: '資料驗證失敗，請重新嘗試',
      ),
      ErrorType.general => _ErrorConfig(
        icon: Icons.error_outline,
        color: AppColors.error,
        title: '發生錯誤',
        retryIcon: Icons.refresh,
        retryLabel: '重試',
        helpText: '請重新嘗試或聯繫支援',
      ),
    };
  }
}

/// Internal error configuration
class _ErrorConfig {
  final IconData icon;
  final Color color;
  final String title;
  final IconData retryIcon;
  final String retryLabel;
  final String helpText;

  const _ErrorConfig({
    required this.icon,
    required this.color,
    required this.title,
    required this.retryIcon,
    required this.retryLabel,
    required this.helpText,
  });
}
