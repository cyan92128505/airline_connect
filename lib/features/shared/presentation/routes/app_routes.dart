/// Application route constants and configuration
class AppRoutes {
  // Prevent instantiation
  AppRoutes._();

  // Route paths
  static const String root = '/';
  static const String splash = '/splash';
  static const String boardingPass = '/boarding-pass';
  static const String qrScanner = '/qr-scanner';
  static const String memberAuth = '/member-auth';
  static const String memberProfile = '/member/profile';

  // Route names for type-safe navigation
  static const String splashName = 'splash';
  static const String boardingPassName = 'boarding-pass';
  static const String qrScannerName = 'qr-scanner';
  static const String memberAuthName = 'member-auth';
  static const String memberProfileName = 'member-profile';

  // Protected routes that require authentication
  static const List<String> protectedRoutes = [
    boardingPass,
    qrScanner,
    memberProfile,
  ];

  // Routes that should show splash screen first
  static const List<String> splashRoutes = [root];

  // Get route for tab index based on authentication state
  static String getTabRoute(int index, bool isAuthenticated) {
    switch (index) {
      case 0:
        return boardingPass;
      case 1:
        return qrScanner;
      case 2:
        return isAuthenticated ? memberProfile : memberAuth;
      default:
        return boardingPass;
    }
  }

  // Get tab index for route
  static int getTabIndex(String route) {
    switch (route) {
      case boardingPass:
        return 0;
      case qrScanner:
        return 1;
      case memberAuth:
      case memberProfile:
        return 2;
      default:
        return 0;
    }
  }
}
