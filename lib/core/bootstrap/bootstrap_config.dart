class BootstrapConfig {
  const BootstrapConfig({
    required this.enableDebugMode,
    required this.enableDemoData,
    required this.enableDetailedLogging,
    required this.timezoneName,
    this.maxInitializationTimeoutSeconds = 30,
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

  @override
  String toString() {
    return 'BootstrapConfig('
        'debugMode: $enableDebugMode, '
        'demoData: $enableDemoData, '
        'detailedLogging: $enableDetailedLogging, '
        'timezone: $timezoneName, '
        'timeout: ${maxInitializationTimeoutSeconds}s'
        ')';
  }
}
