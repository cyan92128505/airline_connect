import 'dart:async';
import 'package:app/di/dependency_injection.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;

part 'network_connectivity_provider.freezed.dart';
part 'network_connectivity_provider.g.dart';

/// Network connectivity state with enterprise-grade features
@freezed
abstract class NetworkConnectivityState with _$NetworkConnectivityState {
  const factory NetworkConnectivityState({
    @Default(false) bool isOnline,
    @Default(ConnectivityResult.none) ConnectivityResult connectionType,
    @Default(NetworkQuality.unknown) NetworkQuality quality,
    @Default(0) int retryCount,
    @Default(false) bool isRetrying,
    DateTime? lastConnectedAt,
    DateTime? lastDisconnectedAt,
    String? lastError,
    @Default([]) List<NetworkEvent> recentEvents,
  }) = _NetworkConnectivityState;

  const NetworkConnectivityState._();

  /// Whether connection is stable (online for > 5 seconds)
  bool get isStable {
    if (!isOnline || lastConnectedAt == null) return false;
    final now = DateTime.now();
    return now.difference(lastConnectedAt!).inSeconds > 5;
  }

  /// Whether currently in poor network conditions
  bool get isPoorConnection {
    return isOnline && (quality == NetworkQuality.poor || retryCount > 1);
  }

  /// Get connection strength description
  String get connectionDescription {
    if (!isOnline) return '離線';

    switch (connectionType) {
      case ConnectivityResult.wifi:
        return quality == NetworkQuality.good ? 'WiFi (良好)' : 'WiFi (訊號弱)';
      case ConnectivityResult.mobile:
        return quality == NetworkQuality.good ? '行動網路 (良好)' : '行動網路 (訊號弱)';
      case ConnectivityResult.ethernet:
        return '有線網路';
      default:
        return '未知連線';
    }
  }
}

/// Network quality assessment
enum NetworkQuality {
  unknown,
  poor, // > 1000ms latency
  fair, // 500-1000ms latency
  good; // < 500ms latency

  String get displayText {
    return switch (this) {
      NetworkQuality.good => '良好',
      NetworkQuality.fair => '普通',
      NetworkQuality.poor => '差',
      NetworkQuality.unknown => '未知',
    };
  }
}

/// Network event for history tracking
@freezed
abstract class NetworkEvent with _$NetworkEvent {
  const factory NetworkEvent({
    required DateTime timestamp,
    required NetworkEventType type,
    required ConnectivityResult connectionType,
    String? details,
    int? latencyMs,
  }) = _NetworkEvent;
}

/// Types of network events
enum NetworkEventType {
  connected,
  disconnected,
  connectionChanged,
  qualityChanged,
  retryAttempt,
  syncTriggered,
}

@riverpod
int syncTrigger(Ref<int> ref) {
  return DateTime.now().millisecondsSinceEpoch;
}

/// Enterprise-grade network connectivity provider
@Riverpod(keepAlive: true)
class NetworkConnectivity extends _$NetworkConnectivity {
  static final Logger _logger = Logger();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  Timer? _qualityCheckTimer;
  Timer? _heartbeatTimer;
  late Connectivity _connectivity;

  // Concurrent operation control
  bool _isQualityCheckInProgress = false;
  final Completer<void> _initializationCompleter = Completer<void>();

  static const Duration _heartbeatInterval = Duration(seconds: 30);
  static const Duration _qualityCheckInterval = Duration(seconds: 60);
  static const Duration _qualityCheckTimeout = Duration(seconds: 10);
  static const int _maxRetryCount = 3;
  static const int _maxRecentEvents = 50;

  @override
  NetworkConnectivityState build() {
    _connectivity = ref.watch(connectivityProvider);

    ref.onDispose(() {
      _cleanup();
    });

    _initializeConnectivityMonitoring();
    return const NetworkConnectivityState();
  }

  /// Initialize connectivity monitoring
  Future<void> _initializeConnectivityMonitoring() async {
    try {
      _logger.d('Initializing network connectivity monitoring');

      // Start monitoring connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _handleConnectivityChange,
        onError: (error) {
          _logger.e('Connectivity monitoring error: $error');
          _updateState(lastError: error.toString());
        },
      );

      // Start periodic quality checks
      _qualityCheckTimer = Timer.periodic(_qualityCheckInterval, (_) {
        _scheduleQualityCheck();
      });

      // Start heartbeat monitoring
      _heartbeatTimer = Timer.periodic(_heartbeatInterval, (_) {
        _performHeartbeat();
      });

      // Initial connectivity check
      await _performInitialConnectivityCheck();

      _initializationCompleter.complete();
      _logger.d('Network connectivity monitoring initialized successfully');
    } catch (e) {
      _logger.e('Failed to initialize network connectivity monitoring: $e');
      _updateState(lastError: 'Initialization failed: $e');
      if (!_initializationCompleter.isCompleted) {
        _initializationCompleter.completeError(e);
      }
    }
  }

  /// Handle connectivity changes from system
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    if (results.isEmpty) return;

    final primaryResult = results.first;
    final wasOnline = state.isOnline;
    final isNowOnline = primaryResult != ConnectivityResult.none;

    _logger.i(
      'Connectivity changed: $primaryResult (was online: $wasOnline, now online: $isNowOnline)',
    );

    if (!wasOnline && isNowOnline) {
      _handleConnectionRestored(primaryResult);
    } else if (wasOnline && !isNowOnline) {
      _handleConnectionLost();
    } else if (primaryResult != state.connectionType) {
      _handleConnectionTypeChanged(primaryResult);
    }
  }

  /// Handle connection restoration
  void _handleConnectionRestored(ConnectivityResult connectionType) {
    _logger.i('Connection restored: $connectionType');

    final event = NetworkEvent(
      timestamp: DateTime.now(),
      type: NetworkEventType.connected,
      connectionType: connectionType,
    );

    _updateState(
      isOnline: true,
      connectionType: connectionType,
      retryCount: 0,
      isRetrying: false,
      lastConnectedAt: DateTime.now(),
      lastError: null,
    );

    _addEvent(event);
    _triggerSync('connection_restored');

    // Schedule quality check for restored connection
    _scheduleQualityCheck();
  }

  /// Handle connection loss
  void _handleConnectionLost() {
    _logger.w('Connection lost');

    final event = NetworkEvent(
      timestamp: DateTime.now(),
      type: NetworkEventType.disconnected,
      connectionType: ConnectivityResult.none,
    );

    _updateState(
      isOnline: false,
      connectionType: ConnectivityResult.none,
      quality: NetworkQuality.unknown,
      lastDisconnectedAt: DateTime.now(),
    );

    _addEvent(event);
  }

  /// Handle connection type change
  void _handleConnectionTypeChanged(ConnectivityResult newType) {
    _logger.i('Connection type changed: ${state.connectionType} → $newType');

    final event = NetworkEvent(
      timestamp: DateTime.now(),
      type: NetworkEventType.connectionChanged,
      connectionType: newType,
      details: 'Changed from ${state.connectionType} to $newType',
    );

    _updateState(
      connectionType: newType,
      quality: NetworkQuality.unknown, // Reset quality for new connection
    );

    _addEvent(event);
    _scheduleQualityCheck();
  }

  /// Perform initial connectivity check
  Future<void> _performInitialConnectivityCheck() async {
    try {
      final results = await _connectivity.checkConnectivity();
      if (results.isNotEmpty) {
        _handleConnectivityChange(results);
      }
    } catch (e) {
      _logger.e('Initial connectivity check failed: $e');
      _updateState(lastError: e.toString());
    }
  }

  /// Schedule network quality check with concurrency control
  void _scheduleQualityCheck() {
    if (!state.isOnline || _isQualityCheckInProgress) {
      return;
    }

    // Use microtask to avoid blocking current execution
    scheduleMicrotask(() => _checkNetworkQuality());
  }

  /// Check network quality through ping test with proper resource management
  Future<void> _checkNetworkQuality() async {
    if (!state.isOnline || _isQualityCheckInProgress) {
      return;
    }

    _isQualityCheckInProgress = true;

    try {
      _logger.d('Checking network quality...');

      // Create a fresh HTTP client for this specific request
      final client = http.Client();
      final stopwatch = Stopwatch()..start();

      try {
        // Use timeout to prevent hanging requests
        await client
            .head(
              Uri.parse('https://www.google.com'),
              headers: {'User-Agent': 'AirlineConnect/1.0'},
            )
            .timeout(_qualityCheckTimeout);

        stopwatch.stop();
        final latency = stopwatch.elapsedMilliseconds;

        final quality = _assessNetworkQuality(latency);

        if (quality != state.quality) {
          _logger.i(
            'Network quality changed: ${state.quality} → $quality (${latency}ms)',
          );

          final event = NetworkEvent(
            timestamp: DateTime.now(),
            type: NetworkEventType.qualityChanged,
            connectionType: state.connectionType,
            latencyMs: latency,
            details: 'Quality: $quality, Latency: ${latency}ms',
          );

          _updateState(quality: quality);
          _addEvent(event);
        }
      } finally {
        // Always close the client we created
        client.close();
      }
    } catch (e) {
      _logger.w('Network quality check failed: $e');
      _updateState(
        quality: NetworkQuality.poor,
        lastError: 'Quality check failed: $e',
      );
    } finally {
      _isQualityCheckInProgress = false;
    }
  }

  /// Assess network quality based on latency
  NetworkQuality _assessNetworkQuality(int latencyMs) {
    if (latencyMs < 500) return NetworkQuality.good;
    if (latencyMs < 1000) return NetworkQuality.fair;
    return NetworkQuality.poor;
  }

  /// Perform heartbeat check
  void _performHeartbeat() {
    if (state.isOnline) {
      _scheduleQualityCheck();
    } else {
      // Try to detect if connection is back
      _performInitialConnectivityCheck();
    }
  }

  /// Retry connection with exponential backoff
  Future<void> retryConnection() async {
    if (state.isRetrying || state.retryCount >= _maxRetryCount) {
      return;
    }

    final retryCount = state.retryCount + 1;
    _logger.i('Retrying connection (attempt $retryCount/$_maxRetryCount)');

    _updateState(isRetrying: true, retryCount: retryCount);

    final event = NetworkEvent(
      timestamp: DateTime.now(),
      type: NetworkEventType.retryAttempt,
      connectionType: state.connectionType,
      details: 'Retry attempt $retryCount/$_maxRetryCount',
    );
    _addEvent(event);

    // Exponential backoff: 1s, 2s, 4s
    final delayMs = (1000 * (1 << (retryCount - 1))).clamp(1000, 8000);
    await Future.delayed(Duration(milliseconds: delayMs));

    try {
      await _performInitialConnectivityCheck();
    } finally {
      _updateState(isRetrying: false);
    }
  }

  /// Reset retry count (call when connection is stable)
  void resetRetryCount() {
    if (state.retryCount > 0) {
      _updateState(retryCount: 0);
    }
  }

  /// Trigger sync notification
  void _triggerSync(String reason) {
    _logger.i('Triggering sync due to: $reason');

    final event = NetworkEvent(
      timestamp: DateTime.now(),
      type: NetworkEventType.syncTriggered,
      connectionType: state.connectionType,
      details: 'Sync triggered: $reason',
    );
    _addEvent(event);

    // Notify other providers that sync should occur
    ref.invalidate(syncTriggerProvider);
  }

  /// Add event to recent events list
  void _addEvent(NetworkEvent event) {
    final events = List<NetworkEvent>.from(state.recentEvents);
    events.insert(0, event);

    // Keep only recent events
    if (events.length > _maxRecentEvents) {
      events.removeRange(_maxRecentEvents, events.length);
    }

    _updateState(recentEvents: events);
  }

  /// Update state with new values
  void _updateState({
    bool? isOnline,
    ConnectivityResult? connectionType,
    NetworkQuality? quality,
    int? retryCount,
    bool? isRetrying,
    DateTime? lastConnectedAt,
    DateTime? lastDisconnectedAt,
    String? lastError,
    List<NetworkEvent>? recentEvents,
  }) {
    state = state.copyWith(
      isOnline: isOnline ?? state.isOnline,
      connectionType: connectionType ?? state.connectionType,
      quality: quality ?? state.quality,
      retryCount: retryCount ?? state.retryCount,
      isRetrying: isRetrying ?? state.isRetrying,
      lastConnectedAt: lastConnectedAt ?? state.lastConnectedAt,
      lastDisconnectedAt: lastDisconnectedAt ?? state.lastDisconnectedAt,
      lastError: lastError ?? state.lastError,
      recentEvents: recentEvents ?? state.recentEvents,
    );
  }

  /// Cleanup resources
  void _cleanup() {
    _logger.d('Cleaning up network connectivity monitoring');
    _connectivitySubscription?.cancel();
    _qualityCheckTimer?.cancel();
    _heartbeatTimer?.cancel();

    // Note: We don't close _httpClient here as it's provided by DI
    // and may be used by other parts of the application
  }

  /// Force refresh network status
  Future<void> refresh() async {
    _logger.d('Force refreshing network status');

    // Wait for initialization if still in progress
    if (!_initializationCompleter.isCompleted) {
      try {
        await _initializationCompleter.future.timeout(Duration(seconds: 5));
      } catch (e) {
        _logger.w('Initialization timeout during refresh: $e');
      }
    }

    await _performInitialConnectivityCheck();
    if (state.isOnline) {
      _scheduleQualityCheck();
    }
  }

  /// Get network events within time range
  List<NetworkEvent> getEventsInRange(DateTime start, DateTime end) {
    return state.recentEvents
        .where(
          (event) =>
              event.timestamp.isAfter(start) && event.timestamp.isBefore(end),
        )
        .toList();
  }

  /// Get network uptime percentage in last hour
  double getUptimePercentage() {
    final now = DateTime.now();
    final oneHourAgo = now.subtract(Duration(hours: 1));
    final events = getEventsInRange(oneHourAgo, now);

    if (events.isEmpty) return state.isOnline ? 100.0 : 0.0;

    int onlineTimeMs = 0;
    int totalTimeMs = Duration(hours: 1).inMilliseconds;

    bool wasOnline = false;
    DateTime? lastEventTime;

    for (final event in events.reversed) {
      if (lastEventTime != null && wasOnline) {
        onlineTimeMs += event.timestamp
            .difference(lastEventTime)
            .inMilliseconds;
      }

      wasOnline =
          event.type == NetworkEventType.connected ||
          event.type == NetworkEventType.connectionChanged;
      lastEventTime = event.timestamp;
    }

    // Add time from last event to now if online
    if (lastEventTime != null && wasOnline) {
      onlineTimeMs += now.difference(lastEventTime).inMilliseconds;
    }

    return (onlineTimeMs / totalTimeMs * 100).clamp(0.0, 100.0);
  }
}
