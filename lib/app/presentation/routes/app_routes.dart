/// Application route constants and configuration
class AppRoutes {
  // Prevent instantiation
  AppRoutes._();

  // Route paths
  static const String root = '/';
  static const String boardingPass = '/boarding-pass';
  static const String qrScanner = '/qr-scanner';
  static const String memberAuth = '/member-auth';

  // Route names for type-safe navigation
  static const String boardingPassName = 'boarding-pass';
  static const String qrScannerName = 'qr-scanner';
  static const String memberAuthName = 'member-auth';

  // Protected routes that require authentication
  static const List<String> protectedRoutes = [boardingPass, qrScanner];

  // Navigation tab mapping
  static const Map<String, int> routeToTabIndex = {
    boardingPass: 0,
    qrScanner: 1,
    memberAuth: 2,
  };

  static const List<String> tabIndexToRoute = [
    boardingPass,
    qrScanner,
    memberAuth,
  ];
}
