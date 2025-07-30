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

  static const Map<String, int> pagePositions = {
    boardingPass: 0, // Leftmost
    qrScanner: 1, // Middle
    memberAuth: 2, // Rightmost (same position as profile)
    memberProfile: 2, // Rightmost (same position as auth)
    splash: -1, // Special case, no animation needed
  };

  // Get tab index for route
  static int getTabIndex(String route) {
    if (pagePositions.containsKey(route)) {
      return pagePositions[route]!;
    }
    return 0;
  }
}
