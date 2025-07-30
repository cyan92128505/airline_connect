/// Bootstrap configuration for application initialization
/// Centralizes all initialization parameters in a type-safe manner
class BootstrapConfig {
  const BootstrapConfig({
    required this.enableDebugMode,
    required this.enableDemoData,
    required this.enableDetailedLogging,
    required this.timezoneName,
    this.maxInitializationTimeoutSeconds = 30,
    this.enableAuthInitialization = true,
    this.enableOfflineMode = false,
  });

  /// Whether debug features should be enabled
  final bool enableDebugMode;

  /// Whether demo data should be seeded
  final bool enableDemoData;

  /// Whether detailed logging should be enabled
  final bool enableDetailedLogging;

  /// Timezone name for the application
  final String timezoneName;

  /// Maximum time to wait for initialization before timeout
  final int maxInitializationTimeoutSeconds;

  /// Whether authentication initialization should be performed
  final bool enableAuthInitialization;

  /// Whether offline mode support should be enabled
  final bool enableOfflineMode;

  @override
  String toString() {
    return 'BootstrapConfig('
        'debugMode: $enableDebugMode, '
        'demoData: $enableDemoData, '
        'detailedLogging: $enableDetailedLogging, '
        'timezone: $timezoneName, '
        'timeout: ${maxInitializationTimeoutSeconds}s, '
        'auth: $enableAuthInitialization, '
        'offline: $enableOfflineMode'
        ')';
  }

  /// Create configuration for production environment
  factory BootstrapConfig.production({String timezoneName = 'Asia/Taipei'}) {
    return BootstrapConfig(
      enableDebugMode: false,
      enableDemoData: false,
      enableDetailedLogging: false,
      timezoneName: timezoneName,
      maxInitializationTimeoutSeconds: 15,
    );
  }

  /// Create configuration for development environment
  factory BootstrapConfig.development({String timezoneName = 'Asia/Taipei'}) {
    return BootstrapConfig(
      enableDebugMode: true,
      enableDemoData: true,
      enableDetailedLogging: true,
      timezoneName: timezoneName,
      maxInitializationTimeoutSeconds: 60,
    );
  }

  /// Create configuration for testing environment
  factory BootstrapConfig.testing({String timezoneName = 'Asia/Taipei'}) {
    return BootstrapConfig(
      enableDebugMode: true,
      enableDemoData: true,
      enableDetailedLogging: true,
      timezoneName: timezoneName,
      maxInitializationTimeoutSeconds: 10,
      enableAuthInitialization: false, // Skip auth in tests
    );
  }
}
