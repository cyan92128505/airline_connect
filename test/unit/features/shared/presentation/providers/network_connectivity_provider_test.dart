import 'dart:async';
import 'package:app/di/dependency_injection.dart';
import 'package:app/features/shared/presentation/providers/network_connectivity_utils_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:app/features/shared/presentation/providers/network_connectivity_provider.dart';

import 'network_connectivity_provider_test.mocks.dart';

@GenerateMocks([Connectivity])
void main() {
  late ProviderContainer container;
  late MockConnectivity mockConnectivity;
  late StreamController<List<ConnectivityResult>> connectivityController;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    mockConnectivity = MockConnectivity();
    connectivityController =
        StreamController<List<ConnectivityResult>>.broadcast();

    // Mock connectivity stream
    when(
      mockConnectivity.onConnectivityChanged,
    ).thenAnswer((_) => connectivityController.stream);

    when(
      mockConnectivity.checkConnectivity(),
    ).thenAnswer((_) async => [ConnectivityResult.none]);

    // Initialize container with overrides
    container = ProviderContainer(
      overrides: [connectivityProvider.overrideWithValue(mockConnectivity)],
    );
  });

  tearDown(() {
    container.dispose();
    connectivityController.close();
  });

  group('NetworkConnectivityProvider Tests', () {
    group('Initial State', () {
      test('should start with offline state', () {
        final state = container.read(networkConnectivityProvider);

        expect(state.isOnline, isFalse);
        expect(state.connectionType, equals(ConnectivityResult.none));
        expect(state.quality, equals(NetworkQuality.unknown));
        expect(state.retryCount, equals(0));
        expect(state.isRetrying, isFalse);
        expect(state.recentEvents, isEmpty);
      });

      test('should have correct initial computed properties', () {
        final state = container.read(networkConnectivityProvider);

        expect(state.isStable, isFalse);
        expect(state.isPoorConnection, isFalse);
        expect(state.connectionDescription, equals('離線'));
      });
    });

    group('Connectivity Changes', () {
      test('should handle connection restored', () async {
        // Setup mock responses
        when(
          mockConnectivity.checkConnectivity(),
        ).thenAnswer((_) async => [ConnectivityResult.wifi]);

        // Create a dedicated container for this test to avoid interference
        final testContainer = ProviderContainer(
          overrides: [connectivityProvider.overrideWithValue(mockConnectivity)],
        );

        try {
          // Initialize provider
          testContainer.read(networkConnectivityProvider.notifier);

          // Wait for initial setup
          await Future.delayed(Duration(milliseconds: 100));

          // Simulate connectivity change
          connectivityController.add([ConnectivityResult.wifi]);

          // Wait for all async operations to complete
          // This includes: connectivity change -> connection restored -> quality check
          await Future.delayed(Duration(milliseconds: 500));

          // Read final state
          final state = testContainer.read(networkConnectivityProvider);

          expect(state.isOnline, isTrue);
          expect(state.connectionType, equals(ConnectivityResult.wifi));
          expect(state.retryCount, equals(0));
          expect(state.isRetrying, isFalse);
          expect(state.lastConnectedAt, isNotNull);
          expect(state.recentEvents, isNotEmpty);

          // Check that we have a connected event
          final connectedEvents = state.recentEvents
              .where((e) => e.type == NetworkEventType.connected)
              .toList();
          expect(connectedEvents, isNotEmpty);
        } finally {
          testContainer.dispose();
        }
      });

      test('should handle connection lost', () async {
        final testContainer = ProviderContainer(
          overrides: [connectivityProvider.overrideWithValue(mockConnectivity)],
        );

        try {
          // Start with online state
          when(
            mockConnectivity.checkConnectivity(),
          ).thenAnswer((_) async => [ConnectivityResult.wifi]);

          testContainer.read(networkConnectivityProvider.notifier);

          // Connect first
          connectivityController.add([ConnectivityResult.wifi]);
          await Future.delayed(Duration(milliseconds: 200));

          // Lose connection
          connectivityController.add([ConnectivityResult.none]);
          await Future.delayed(Duration(milliseconds: 200));

          final state = testContainer.read(networkConnectivityProvider);

          expect(state.isOnline, isFalse);
          expect(state.connectionType, equals(ConnectivityResult.none));
          expect(state.quality, equals(NetworkQuality.unknown));
          expect(state.lastDisconnectedAt, isNotNull);

          // Should have disconnected event
          final disconnectedEvents = state.recentEvents
              .where((e) => e.type == NetworkEventType.disconnected)
              .toList();
          expect(disconnectedEvents, isNotEmpty);
        } finally {
          testContainer.dispose();
        }
      });

      test('should handle connection type change', () async {
        final testContainer = ProviderContainer(
          overrides: [connectivityProvider.overrideWithValue(mockConnectivity)],
        );

        try {
          // Start with WiFi
          when(
            mockConnectivity.checkConnectivity(),
          ).thenAnswer((_) async => [ConnectivityResult.wifi]);

          testContainer.read(networkConnectivityProvider.notifier);

          connectivityController.add([ConnectivityResult.wifi]);
          await Future.delayed(Duration(milliseconds: 200));

          // Change to mobile
          connectivityController.add([ConnectivityResult.mobile]);
          await Future.delayed(Duration(milliseconds: 200));

          final state = testContainer.read(networkConnectivityProvider);

          expect(state.isOnline, isTrue);
          expect(state.connectionType, equals(ConnectivityResult.mobile));

          // Should have connectionChanged event
          final changedEvents = state.recentEvents
              .where((e) => e.type == NetworkEventType.connectionChanged)
              .toList();
          expect(changedEvents, isNotEmpty);
        } finally {
          testContainer.dispose();
        }
      });
    });

    group('Retry Logic', () {
      test('should increment retry count on retry', () async {
        final testContainer = ProviderContainer(
          overrides: [connectivityProvider.overrideWithValue(mockConnectivity)],
        );

        try {
          final provider = testContainer.read(
            networkConnectivityProvider.notifier,
          );

          // Mock failed connectivity check
          when(
            mockConnectivity.checkConnectivity(),
          ).thenAnswer((_) async => [ConnectivityResult.none]);

          // Retry connection
          await provider.retryConnection();

          final state = testContainer.read(networkConnectivityProvider);
          expect(state.retryCount, equals(1));

          final retryEvents = state.recentEvents
              .where((e) => e.type == NetworkEventType.retryAttempt)
              .toList();
          expect(retryEvents, isNotEmpty);
        } finally {
          testContainer.dispose();
        }
      });

      test('should not retry beyond max attempts', () async {
        final testContainer = ProviderContainer(
          overrides: [connectivityProvider.overrideWithValue(mockConnectivity)],
        );

        try {
          final provider = testContainer.read(
            networkConnectivityProvider.notifier,
          );

          // Mock failed connectivity checks
          when(
            mockConnectivity.checkConnectivity(),
          ).thenAnswer((_) async => [ConnectivityResult.none]);

          // Retry until max attempts
          await provider.retryConnection(); // 1
          await provider.retryConnection(); // 2
          await provider.retryConnection(); // 3

          expect(
            testContainer.read(networkConnectivityProvider).retryCount,
            equals(3),
          );

          // Should not retry beyond max
          await provider.retryConnection();
          expect(
            testContainer.read(networkConnectivityProvider).retryCount,
            equals(3),
          );
        } finally {
          testContainer.dispose();
        }
      });

      test('should reset retry count when requested', () async {
        final testContainer = ProviderContainer(
          overrides: [connectivityProvider.overrideWithValue(mockConnectivity)],
        );

        try {
          final provider = testContainer.read(
            networkConnectivityProvider.notifier,
          );

          // Set retry count
          when(
            mockConnectivity.checkConnectivity(),
          ).thenAnswer((_) async => [ConnectivityResult.none]);
          await provider.retryConnection();

          expect(
            testContainer.read(networkConnectivityProvider).retryCount,
            equals(1),
          );

          // Reset retry count
          provider.resetRetryCount();

          expect(
            testContainer.read(networkConnectivityProvider).retryCount,
            equals(0),
          );
        } finally {
          testContainer.dispose();
        }
      });
    });

    group('State Computed Properties', () {
      test('should provide correct connection descriptions', () {
        const testCases = [
          (ConnectivityResult.none, false, NetworkQuality.unknown, '離線'),
          (ConnectivityResult.wifi, true, NetworkQuality.good, 'WiFi (良好)'),
          (ConnectivityResult.wifi, true, NetworkQuality.poor, 'WiFi (訊號弱)'),
          (ConnectivityResult.mobile, true, NetworkQuality.good, '行動網路 (良好)'),
          (ConnectivityResult.mobile, true, NetworkQuality.poor, '行動網路 (訊號弱)'),
          (ConnectivityResult.ethernet, true, NetworkQuality.good, '有線網路'),
        ];

        for (final (connectionType, isOnline, quality, expectedDescription)
            in testCases) {
          final state = NetworkConnectivityState(
            isOnline: isOnline,
            connectionType: connectionType,
            quality: quality,
          );

          expect(state.connectionDescription, equals(expectedDescription));
        }
      });

      test('should identify poor connection correctly', () {
        // Test poor quality connection
        final poorQualityState = NetworkConnectivityState(
          isOnline: true,
          connectionType: ConnectivityResult.wifi,
          quality: NetworkQuality.poor,
        );
        expect(poorQualityState.isPoorConnection, isTrue);

        // Test high retry count
        final highRetryState = NetworkConnectivityState(
          isOnline: true,
          connectionType: ConnectivityResult.wifi,
          quality: NetworkQuality.good,
          retryCount: 2,
        );
        expect(highRetryState.isPoorConnection, isTrue);
      });
    });

    group('Event Management', () {
      test('should limit recent events to maximum', () async {
        final testContainer = ProviderContainer(
          overrides: [connectivityProvider.overrideWithValue(mockConnectivity)],
        );

        try {
          testContainer.read(networkConnectivityProvider.notifier);

          // Generate many events by toggling connection
          for (int i = 0; i < 55; i++) {
            final connectionType = i.isEven
                ? ConnectivityResult.wifi
                : ConnectivityResult.none;
            connectivityController.add([connectionType]);
            await Future.delayed(Duration(milliseconds: 20));
          }

          // Wait for all events to process
          await Future.delayed(Duration(milliseconds: 500));

          final state = testContainer.read(networkConnectivityProvider);

          // Should not exceed maximum
          expect(state.recentEvents.length, lessThanOrEqualTo(50));

          // Most recent event should be first if there are multiple events
          if (state.recentEvents.length > 1) {
            expect(
              state.recentEvents.first.timestamp.isAfter(
                state.recentEvents.last.timestamp,
              ),
              isTrue,
            );
          }
        } finally {
          testContainer.dispose();
        }
      });

      test('should filter events by time range', () async {
        final testContainer = ProviderContainer(
          overrides: [connectivityProvider.overrideWithValue(mockConnectivity)],
        );

        try {
          final provider = testContainer.read(
            networkConnectivityProvider.notifier,
          );

          final now = DateTime.now();
          final oneHourAgo = now.subtract(Duration(hours: 1));

          // Connect to generate events
          connectivityController.add([ConnectivityResult.wifi]);
          await Future.delayed(Duration(milliseconds: 200));

          final events = provider.getEventsInRange(
            oneHourAgo,
            now.add(Duration(minutes: 1)),
          );

          // All events should be within range
          for (final event in events) {
            expect(event.timestamp.isAfter(oneHourAgo), isTrue);
            expect(
              event.timestamp.isBefore(now.add(Duration(minutes: 1))),
              isTrue,
            );
          }
        } finally {
          testContainer.dispose();
        }
      });
    });

    group('Convenience Providers', () {
      test('isOnline provider should reflect connectivity state', () async {
        final testContainer = ProviderContainer(
          overrides: [connectivityProvider.overrideWithValue(mockConnectivity)],
        );

        try {
          // Start offline
          expect(testContainer.read(isOnlineProvider), isFalse);

          // Initialize provider
          testContainer.read(networkConnectivityProvider.notifier);

          // Connect
          connectivityController.add([ConnectivityResult.wifi]);
          await Future.delayed(Duration(milliseconds: 300));

          expect(testContainer.read(isOnlineProvider), isTrue);
        } finally {
          testContainer.dispose();
        }
      });

      test(
        'connectionType provider should reflect current connection',
        () async {
          final testContainer = ProviderContainer(
            overrides: [
              connectivityProvider.overrideWithValue(mockConnectivity),
            ],
          );

          try {
            // Start with no connection
            expect(
              testContainer.read(connectionTypeProvider),
              equals(ConnectivityResult.none),
            );

            // Initialize provider
            testContainer.read(networkConnectivityProvider.notifier);

            // Connect with WiFi
            connectivityController.add([ConnectivityResult.wifi]);
            await Future.delayed(Duration(milliseconds: 200));

            expect(
              testContainer.read(connectionTypeProvider),
              equals(ConnectivityResult.wifi),
            );

            // Change to mobile
            connectivityController.add([ConnectivityResult.mobile]);
            await Future.delayed(Duration(milliseconds: 200));

            expect(
              testContainer.read(connectionTypeProvider),
              equals(ConnectivityResult.mobile),
            );
          } finally {
            testContainer.dispose();
          }
        },
      );
    });

    group('Error Handling', () {
      test('should handle connectivity stream errors gracefully', () async {
        final testContainer = ProviderContainer(
          overrides: [connectivityProvider.overrideWithValue(mockConnectivity)],
        );

        try {
          testContainer.read(networkConnectivityProvider.notifier);

          // Emit error on connectivity stream
          connectivityController.addError('Network service unavailable');
          await Future.delayed(Duration(milliseconds: 100));

          final state = testContainer.read(networkConnectivityProvider);

          expect(state.lastError, isNotNull);
          expect(state.lastError, contains('Network service unavailable'));
        } finally {
          testContainer.dispose();
        }
      });

      test('should handle connectivity check failures', () async {
        final testContainer = ProviderContainer(
          overrides: [connectivityProvider.overrideWithValue(mockConnectivity)],
        );

        try {
          final provider = testContainer.read(
            networkConnectivityProvider.notifier,
          );

          // Mock connectivity check failure
          when(
            mockConnectivity.checkConnectivity(),
          ).thenThrow(Exception('Connectivity check failed'));

          // Attempt refresh
          await provider.refresh();

          final state = testContainer.read(networkConnectivityProvider);

          expect(state.lastError, isNotNull);
          expect(state.lastError, contains('Connectivity check failed'));
        } finally {
          testContainer.dispose();
        }
      });
    });
  });

  group('NetworkEvent Tests', () {
    test('should create network event with correct properties', () {
      final now = DateTime.now();
      final event = NetworkEvent(
        timestamp: now,
        type: NetworkEventType.connected,
        connectionType: ConnectivityResult.wifi,
        details: 'Connected to WiFi network',
        latencyMs: 150,
      );

      expect(event.timestamp, equals(now));
      expect(event.type, equals(NetworkEventType.connected));
      expect(event.connectionType, equals(ConnectivityResult.wifi));
      expect(event.details, equals('Connected to WiFi network'));
      expect(event.latencyMs, equals(150));
    });
  });

  group('NetworkQuality Tests', () {
    test('should have correct enum values', () {
      expect(NetworkQuality.values.length, equals(4));
      expect(NetworkQuality.values, contains(NetworkQuality.unknown));
      expect(NetworkQuality.values, contains(NetworkQuality.poor));
      expect(NetworkQuality.values, contains(NetworkQuality.fair));
      expect(NetworkQuality.values, contains(NetworkQuality.good));
    });
  });
}
