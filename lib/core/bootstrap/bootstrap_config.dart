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
    this.enableNetworkMonitoring = true,
    this.networkHeartbeatIntervalSeconds = 30,
    this.networkQualityCheckIntervalSeconds = 60,
    this.maxNetworkRetryAttempts = 3,
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

  /// Whether network connectivity monitoring should be enabled
  final bool enableNetworkMonitoring;

  /// Interval for network heartbeat checks (in seconds)
  final int networkHeartbeatIntervalSeconds;

  /// Interval for network quality assessment (in seconds)
  final int networkQualityCheckIntervalSeconds;

  /// Maximum number of network retry attempts
  final int maxNetworkRetryAttempts;

  @override
  String toString() {
    return 'BootstrapConfig('
        'debugMode: $enableDebugMode, '
        'demoData: $enableDemoData, '
        'detailedLogging: $enableDetailedLogging, '
        'timezone: $timezoneName, '
        'timeout: ${maxInitializationTimeoutSeconds}s, '
        'auth: $enableAuthInitialization, '
        'offline: $enableOfflineMode, '
        'networkMonitoring: $enableNetworkMonitoring, '
        'heartbeat: ${networkHeartbeatIntervalSeconds}s, '
        'qualityCheck: ${networkQualityCheckIntervalSeconds}s, '
        'maxRetries: $maxNetworkRetryAttempts'
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
      enableNetworkMonitoring: true,
      networkHeartbeatIntervalSeconds: 60, // Less frequent in production
      networkQualityCheckIntervalSeconds: 120,
      maxNetworkRetryAttempts: 3,
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
      enableNetworkMonitoring: true,
      networkHeartbeatIntervalSeconds: 30,
      networkQualityCheckIntervalSeconds: 60,
      maxNetworkRetryAttempts: 5, // More retries in development
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
      enableNetworkMonitoring: false, // Skip network monitoring in tests
    );
  }

  /// Create configuration with network monitoring disabled
  factory BootstrapConfig.offlineOnly({
    String timezoneName = 'Asia/Taipei',
    bool enableDebugMode = false,
  }) {
    return BootstrapConfig(
      enableDebugMode: enableDebugMode,
      enableDemoData: enableDebugMode,
      enableDetailedLogging: enableDebugMode,
      timezoneName: timezoneName,
      enableOfflineMode: true,
      enableNetworkMonitoring: false,
      maxInitializationTimeoutSeconds: 20,
    );
  }
}
