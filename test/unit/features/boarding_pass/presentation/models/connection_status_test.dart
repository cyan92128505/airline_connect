import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/boarding_pass/presentation/models/connection_status.dart';
import 'package:app/features/boarding_pass/presentation/notifiers/boarding_pass_notifier.dart';
import 'package:app/features/shared/presentation/providers/network_connectivity_provider.dart';

void main() {
  group('ConnectionStatus Tests', () {
    group('OfflineStatus', () {
      test('should have correct styling properties', () {
        // Arrange
        const status = OfflineStatus();

        // Assert
        expect(status.backgroundColor, Colors.red[50]);
        expect(status.icon, Icons.wifi_off);
        expect(status.message, '離線模式');
        expect(status.showSync, false);
        expect(status.hasIssue, true);
      });

      test('should generate correct additional info when disconnected', () {
        // Arrange
        const status = OfflineStatus();
        final disconnectedAt = DateTime.now().subtract(Duration(hours: 2));
        final networkState = NetworkConnectivityState(
          isOnline: false,
          lastDisconnectedAt: disconnectedAt,
        );
        final boardingPassState = BoardingPassState(
          pendingOperations: ['activate:BP123'],
        );

        // Act
        final additionalInfo = status.generateAdditionalInfo(
          networkState,
          boardingPassState,
        );

        // Assert
        expect(additionalInfo.length, 2);
        expect(additionalInfo[0], contains('離線時間：2小時'));
        expect(additionalInfo[1], contains('待處理操作：1 項'));
      });
    });

    group('SyncNeededStatus', () {
      test('should have correct styling properties', () {
        // Arrange
        const status = SyncNeededStatus();

        // Assert
        expect(status.backgroundColor, Colors.blue[50]);
        expect(status.icon, Icons.sync);
        expect(status.message, '需要同步');
        expect(status.showSync, true);
        expect(status.hasIssue, true);
      });

      test('should generate additional info for pending operations', () {
        // Arrange
        const status = SyncNeededStatus();
        final networkState = NetworkConnectivityState(isOnline: true);
        final lastSync = DateTime.now().subtract(Duration(minutes: 30));
        final boardingPassState = BoardingPassState(
          pendingOperations: ['activate:BP123', 'refresh:BP456'],
          lastSyncAttempt: lastSync,
        );

        // Act
        final additionalInfo = status.generateAdditionalInfo(
          networkState,
          boardingPassState,
        );

        // Assert
        expect(additionalInfo, contains(contains('待處理操作：2 項')));
        expect(additionalInfo, contains(contains('上次同步：30分鐘前')));
      });
    });

    group('NormalStatus', () {
      test('should have correct styling properties', () {
        // Arrange
        const status = NormalStatus();

        // Assert
        expect(status.backgroundColor, Colors.green[50]);
        expect(status.icon, Icons.check_circle);
        expect(status.message, '網路正常');
        expect(status.showSync, false);
        expect(status.hasIssue, false); // Key difference from other statuses
        expect(status.showAdditionalInfo, false);
      });

      test('should return empty additional info', () {
        // Arrange
        const status = NormalStatus();
        final networkState = NetworkConnectivityState(isOnline: true);
        final boardingPassState = BoardingPassState();

        // Act
        final additionalInfo = status.generateAdditionalInfo(
          networkState,
          boardingPassState,
        );

        // Assert
        expect(additionalInfo, isEmpty);
      });
    });

    group('Sealed class pattern matching', () {
      test('should handle all status types in switch expression', () {
        // Arrange
        const statuses = [
          OfflineStatus(),
          PoorConnectionStatus(),
          SyncNeededStatus(),
          NormalStatus(),
        ];

        for (final status in statuses) {
          // Act - This would fail to compile if any status is missing
          final description = switch (status) {
            OfflineStatus() => 'User is offline',
            PoorConnectionStatus() => 'Connection issues',
            SyncNeededStatus() => 'Sync required',
            NormalStatus() => 'All good',
          };

          // Assert
          expect(description, isNotEmpty);
        }
      });

      test('should provide consistent interface across all statuses', () {
        // Arrange
        const statuses = [
          OfflineStatus(),
          PoorConnectionStatus(),
          SyncNeededStatus(),
          NormalStatus(),
        ];

        for (final status in statuses) {
          // Assert - All statuses should have these properties
          expect(status.backgroundColor, isA<Color>());
          expect(status.icon, isA<IconData>());
          expect(status.message, isA<String>());
          expect(status.message, isNotEmpty);
          expect(status.showSync, isA<bool>());
          expect(status.hasIssue, isA<bool>());

          // All statuses should be able to generate additional info
          final networkState = NetworkConnectivityState(isOnline: true);
          final boardingPassState = BoardingPassState();
          final info = status.generateAdditionalInfo(
            networkState,
            boardingPassState,
          );
          expect(info, isA<List<String>>());
        }
      });
    });

    group('Color consistency', () {
      test('should maintain consistent color schemes', () {
        // Test that each status uses consistent color family
        const testCases = [
          (OfflineStatus(), 'red'),
          (PoorConnectionStatus(), 'orange'),
          (SyncNeededStatus(), 'blue'),
          (NormalStatus(), 'green'),
        ];

        for (final (status, colorFamily) in testCases) {
          // All colors should be from the same family
          final bgLuminance = status.backgroundColor.computeLuminance();
          final textLuminance = status.textColor.computeLuminance();

          // Light background, dark text for accessibility
          expect(
            bgLuminance,
            greaterThan(0.5),
            reason: '$colorFamily background should be light',
          );
          expect(
            textLuminance,
            lessThan(0.5),
            reason: '$colorFamily text should be dark',
          );

          // Sufficient contrast
          expect(
            bgLuminance - textLuminance,
            greaterThan(0.3),
            reason: '$colorFamily should have good contrast',
          );
        }
      });
    });
  });
}
