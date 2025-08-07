import 'package:app/features/boarding_pass/presentation/models/connection_status.dart';
import 'package:app/features/boarding_pass/presentation/notifiers/boarding_pass_notifier.dart';
import 'package:app/features/shared/presentation/providers/network_connectivity_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connection_status_provider.g.dart';

/// Provider for determining the current display status
/// Pure business logic - no styling concerns
@riverpod
ConnectionStatus connectionStatus(Ref<ConnectionStatus> ref) {
  final networkState = ref.watch(networkConnectivityProvider);
  final boardingPassState = ref.watch(boardingPassNotifierProvider);

  // Priority-based status determination
  // Each condition is checked in order of importance

  // Highest priority: Offline
  if (!networkState.isOnline) {
    return const OfflineStatus();
  }

  // Second priority: Poor connection
  if (_isPoorConnection(networkState)) {
    return const PoorConnectionStatus();
  }

  // Third priority: Sync needed
  if (_needsSync(boardingPassState)) {
    return const SyncNeededStatus();
  }

  // Default: Everything is good
  return const NormalStatus();
}

/// Helper provider for checking if status should be displayed
@riverpod
bool shouldShowStatus(Ref<bool> ref) {
  final status = ref.watch(connectionStatusProvider);
  return status.hasIssue;
}

/// Helper provider for getting additional info with current states
@riverpod
List<String> connectionStatusAdditionalInfo(Ref<List<String>> ref) {
  final status = ref.watch(connectionStatusProvider);
  final networkState = ref.watch(networkConnectivityProvider);
  final boardingPassState = ref.watch(boardingPassNotifierProvider);

  return status.generateAdditionalInfo(networkState, boardingPassState);
}

/// Helper provider for dynamic detail message with operation count
@riverpod
String connectionStatusDetailMessage(Ref<String> ref) {
  final status = ref.watch(connectionStatusProvider);
  final boardingPassState = ref.watch(boardingPassNotifierProvider);

  // For SyncNeededStatus, include pending operations count
  return switch (status) {
    SyncNeededStatus() =>
      '有資料需要同步：${boardingPassState.pendingOperations.length} 項待處理操作',
    _ => status.detailMessage,
  };
}

// Private helper functions for business logic

/// Check if network connection is poor
bool _isPoorConnection(NetworkConnectivityState networkState) {
  return networkState.isPoorConnection ||
      networkState.quality == NetworkQuality.poor ||
      networkState.retryCount > 1;
}

/// Check if sync is needed
bool _needsSync(BoardingPassState boardingPassState) {
  return boardingPassState.needsSync ||
      boardingPassState.hasPendingSync ||
      boardingPassState.pendingOperations.isNotEmpty;
}
