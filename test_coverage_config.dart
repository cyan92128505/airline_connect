// Configure test coverage exclusions
// Place this file in your project root directory

// Coverage configuration for Flutter tests
//
// This file defines which files should be excluded from test coverage
// calculations to provide more accurate coverage metrics.

const coverageIgnorePatterns = [
  // Generated files
  '**/*.g.dart',
  '**/*.freezed.dart',
  '**/*.gr.dart',
  '**/objectbox.g.dart',

  // Main entry points
  'lib/main.dart',
  'lib/main_*.dart',

  // Generated plugin registrants
  '**/generated_plugin_registrant.dart',

  // ObjectBox model files
  'lib/objectbox-model.json',

  // Test files (should not be included in coverage)
  'test/**',
  'integration_test/**',

  // Third-party or external libraries
  'lib/**/external/**',

  // Configuration files
  'lib/**/config/**',

  // Platform-specific code that's hard to test
  'lib/**/platform/**',
];

/// Minimum coverage threshold (percentage)
const int minimumCoverageThreshold = 80;

/// Generate lcov exclude patterns for use with flutter test --coverage
String generateLcovExcludePattern() {
  return coverageIgnorePatterns.map((pattern) => 'SF:$pattern').join('\n');
}
