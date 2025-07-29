import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/bootstrap/bootstrap_config.dart';

void main() {
  group('BootstrapConfig', () {
    test('should create config with all required parameters', () {
      // Arrange & Act
      const config = BootstrapConfig(
        enableDebugMode: true,
        enableDemoData: true,
        enableDetailedLogging: false,
        timezoneName: 'Asia/Taipei',
      );

      // Assert
      expect(config.enableDebugMode, isTrue);
      expect(config.enableDemoData, isTrue);
      expect(config.enableDetailedLogging, isFalse);
      expect(config.timezoneName, equals('Asia/Taipei'));
      expect(
        config.maxInitializationTimeoutSeconds,
        equals(30),
      ); // default value
    });

    test('should allow custom timeout configuration', () {
      // Arrange & Act
      const config = BootstrapConfig(
        enableDebugMode: false,
        enableDemoData: false,
        enableDetailedLogging: true,
        timezoneName: 'UTC',
        maxInitializationTimeoutSeconds: 60,
      );

      // Assert
      expect(config.maxInitializationTimeoutSeconds, equals(60));
    });

    test('should provide meaningful toString representation', () {
      // Arrange
      const config = BootstrapConfig(
        enableDebugMode: true,
        enableDemoData: false,
        enableDetailedLogging: true,
        timezoneName: 'America/New_York',
        maxInitializationTimeoutSeconds: 45,
      );

      // Act
      final stringRepresentation = config.toString();

      // Assert
      expect(stringRepresentation, contains('debugMode: true'));
      expect(stringRepresentation, contains('demoData: false'));
      expect(stringRepresentation, contains('detailedLogging: true'));
      expect(stringRepresentation, contains('timezone: America/New_York'));
      expect(stringRepresentation, contains('timeout: 45s'));
    });

    group('immutability verification', () {
      test('should be immutable once created', () {
        // Arrange
        const config1 = BootstrapConfig(
          enableDebugMode: true,
          enableDemoData: true,
          enableDetailedLogging: true,
          timezoneName: 'Asia/Tokyo',
        );

        const config2 = BootstrapConfig(
          enableDebugMode: true,
          enableDemoData: true,
          enableDetailedLogging: true,
          timezoneName: 'Asia/Tokyo',
        );

        // Assert - properties should be equal
        expect(config1.enableDebugMode, equals(config2.enableDebugMode));
        expect(config1.enableDemoData, equals(config2.enableDemoData));
        expect(
          config1.enableDetailedLogging,
          equals(config2.enableDetailedLogging),
        );
        expect(config1.timezoneName, equals(config2.timezoneName));
        expect(
          config1.maxInitializationTimeoutSeconds,
          equals(config2.maxInitializationTimeoutSeconds),
        );
      });
    });

    group('edge cases', () {
      test('should handle empty timezone name', () {
        // Arrange & Act
        const config = BootstrapConfig(
          enableDebugMode: false,
          enableDemoData: false,
          enableDetailedLogging: false,
          timezoneName: '',
        );

        // Assert
        expect(config.timezoneName, equals(''));
      });

      test('should handle zero timeout', () {
        // Arrange & Act
        const config = BootstrapConfig(
          enableDebugMode: false,
          enableDemoData: false,
          enableDetailedLogging: false,
          timezoneName: 'UTC',
          maxInitializationTimeoutSeconds: 0,
        );

        // Assert
        expect(config.maxInitializationTimeoutSeconds, equals(0));
      });

      test('should handle negative timeout', () {
        // Arrange & Act
        const config = BootstrapConfig(
          enableDebugMode: false,
          enableDemoData: false,
          enableDetailedLogging: false,
          timezoneName: 'UTC',
          maxInitializationTimeoutSeconds: -5,
        );

        // Assert
        expect(config.maxInitializationTimeoutSeconds, equals(-5));
      });
    });
  });
}
