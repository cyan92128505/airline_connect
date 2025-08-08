class AppConstants {
  // QR Code validation
  static const int qrCodeValidityHours = 2;
  static const int maxQRRetries = 3;

  // Camera settings
  static const Duration cameraInitTimeout = Duration(seconds: 10);
  static const Duration permissionRequestTimeout = Duration(seconds: 5);

  // UI constants
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration loadingMinDuration = Duration(milliseconds: 500);

  static const appDefaultLocation = 'Asia/Taipei';
}
