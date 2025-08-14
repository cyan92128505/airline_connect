import 'package:app/features/shared/presentation/providers/qr_scanner_provider.dart';
import 'package:logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:app/features/boarding_pass/application/dtos/boarding_pass_dto.dart';
import 'package:app/features/boarding_pass/application/dtos/boarding_pass_operation_dto.dart';
import 'package:app/features/boarding_pass/presentation/providers/boarding_pass_provider.dart';
import 'package:app/features/member/presentation/notifiers/member_auth_notifier.dart';
import 'package:app/features/shared/presentation/providers/network_connectivity_provider.dart';

part 'boarding_pass_notifier.freezed.dart';
part 'boarding_pass_notifier.g.dart';

final Logger _logger = Logger();

/// State for boarding pass management with network awareness
@freezed
abstract class BoardingPassState with _$BoardingPassState {
  const factory BoardingPassState({
    @Default(false) bool isLoading,
    @Default([]) List<BoardingPassDTO> boardingPasses,
    BoardingPassDTO? selectedPass,
    String? errorMessage,
    @Default(false) bool isActivating,
    @Default(false) bool isScanning,
    QRCodeValidationResponseDTO? scanResult,
    @Default(false) bool hasPendingSync,
    DateTime? lastSyncAttempt,
    @Default([]) List<String> pendingOperations,
  }) = _BoardingPassState;

  const BoardingPassState._();

  /// Whether has any boarding passes
  bool get hasBoardingPasses => boardingPasses.isNotEmpty;

  /// Active boarding passes only
  List<BoardingPassDTO> get activePasses =>
      boardingPasses.where((pass) => pass.isActive == true).toList();

  /// Whether has active boarding passes
  bool get hasActivePasses => activePasses.isNotEmpty;

  /// Today's boarding passes
  List<BoardingPassDTO> get todayPasses {
    final today = DateTime.now();
    return boardingPasses.where((pass) {
      final departureTime = DateTime.parse(pass.scheduleSnapshot.departureTime);
      return departureTime.year == today.year &&
          departureTime.month == today.month &&
          departureTime.day == today.day;
    }).toList();
  }

  /// Whether has error
  bool get hasError => errorMessage != null;

  /// Next departure pass
  BoardingPassDTO? get nextDeparture {
    if (activePasses.isEmpty) return null;

    final now = DateTime.now();
    final futurePasses = activePasses.where((pass) {
      final departureTime = DateTime.parse(pass.scheduleSnapshot.departureTime);
      return departureTime.isAfter(now);
    }).toList();

    if (futurePasses.isEmpty) return null;

    futurePasses.sort((a, b) {
      final timeA = DateTime.parse(a.scheduleSnapshot.departureTime);
      final timeB = DateTime.parse(b.scheduleSnapshot.departureTime);
      return timeA.compareTo(timeB);
    });

    return futurePasses.first;
  }

  /// Whether sync is needed
  bool get needsSync => hasPendingSync || pendingOperations.isNotEmpty;
}

/// Provider for BoardingPassNotifier with network awareness
@riverpod
class BoardingPassNotifier extends _$BoardingPassNotifier {
  @override
  BoardingPassState build() {
    // Listen to network state changes and trigger sync when connection is restored
    ref.listen(networkConnectivityProvider, (previous, current) {
      _handleNetworkStateChange(previous, current);
    });

    // Listen to sync triggers
    ref.listen(syncTriggerProvider, (previous, current) {
      if (current != previous) {
        _handleSyncTrigger();
      }
    });

    return const BoardingPassState();
  }

  /// Handle network state changes
  void _handleNetworkStateChange(
    NetworkConnectivityState? previous,
    NetworkConnectivityState current,
  ) {
    // Connection restored
    if (previous != null && !previous.isOnline && current.isOnline) {
      _performAutoSync();
    }

    // Connection quality improved
    if (previous != null &&
        previous.quality == NetworkQuality.poor &&
        current.quality == NetworkQuality.good) {
      _retryPendingOperations();
    }

    // Connection became unstable
    if (current.isPoorConnection && state.isLoading) {
      _logger.w(
        'Poor network detected during operation, may switch to offline mode',
      );
    }
  }

  /// Handle sync trigger events
  void _handleSyncTrigger() {
    if (_shouldPerformSync()) {
      _performAutoSync();
    }
  }

  /// Check if sync should be performed
  bool _shouldPerformSync() {
    final networkState = ref.read(networkConnectivityProvider);

    // Don't sync if offline
    if (!networkState.isOnline) return false;

    // Don't sync if network is poor and we have pending operations
    if (networkState.isPoorConnection && state.pendingOperations.isNotEmpty) {
      return false;
    }

    // Don't sync too frequently
    final lastSync = state.lastSyncAttempt;
    if (lastSync != null) {
      final timeSinceLastSync = DateTime.now().difference(lastSync);
      if (timeSinceLastSync.inMinutes < 1) return false;
    }

    return state.needsSync;
  }

  /// Load boarding passes with network awareness
  Future<void> loadBoardingPasses() async {
    final memberAuthState = ref.read(memberAuthNotifierProvider);
    final networkState = ref.read(networkConnectivityProvider);

    if (!memberAuthState.isAuthenticated || memberAuthState.member == null) {
      state = state.copyWith(errorMessage: '請先登入會員', boardingPasses: []);
      return;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final boardingPassService = ref.read(
        boardingPassApplicationServiceRefProvider,
      );

      // If offline, try to load from local cache only
      if (!networkState.isOnline) {
        // Repository will automatically return local data
      } else if (networkState.isPoorConnection) {
        _logger.w('Loading boarding passes with poor network connection');
      }

      final result = await boardingPassService.getBoardingPassesForMember(
        memberAuthState.member!.memberNumber,
        activeOnly: false,
      );

      result.fold(
        (failure) {
          final errorMessage = _mapFailureToMessage(failure.message);

          // If network-related failure and we're online, mark for sync
          if (_isNetworkFailure(failure.message) && networkState.isOnline) {
            state = state.copyWith(
              isLoading: false,
              errorMessage: errorMessage,
              hasPendingSync: true,
            );
          } else {
            state = state.copyWith(
              isLoading: false,
              errorMessage: errorMessage,
            );
          }
        },
        (passes) {
          state = state.copyWith(
            isLoading: false,
            boardingPasses: passes,
            errorMessage: null,
            hasPendingSync: false, // Successful load clears pending sync
          );

          // Reset network retry count on successful operation
          ref.read(networkConnectivityProvider.notifier).resetRetryCount();
        },
      );
    } catch (e) {
      final errorMessage = networkState.isOnline ? '載入登機證時發生錯誤' : '離線模式：顯示本地資料';

      state = state.copyWith(
        isLoading: false,
        errorMessage: errorMessage,
        hasPendingSync: networkState.isOnline, // Mark for sync if online
      );
    }
  }

  /// Activate boarding pass with network awareness
  Future<void> activateBoardingPass(String passId) async {
    final networkState = ref.read(networkConnectivityProvider);

    // Check network requirements for activation
    if (!networkState.isOnline) {
      state = state.copyWith(errorMessage: '啟用登機證需要網路連線');
      return;
    }

    if (networkState.isPoorConnection) {
      _logger.w('Attempting boarding pass activation with poor network');
    }

    state = state.copyWith(isActivating: true, errorMessage: null);

    try {
      final boardingPassService = ref.read(
        boardingPassApplicationServiceRefProvider,
      );

      final result = await boardingPassService.activateBoardingPass(passId);

      result.fold(
        (failure) {
          if (_isNetworkFailure(failure.message)) {
            // Add to pending operations for retry when network improves
            _addPendingOperation('activate:$passId');

            state = state.copyWith(
              isActivating: false,
              errorMessage: '網路不穩定，已加入待處理清單',
              hasPendingSync: true,
            );
          } else {
            state = state.copyWith(
              isActivating: false,
              errorMessage: _mapFailureToMessage(failure.message),
            );
          }
        },
        (response) {
          if (response.success && response.boardingPass != null) {
            final updatedPasses = state.boardingPasses.map((pass) {
              return pass.passId == passId ? response.boardingPass! : pass;
            }).toList();

            state = state.copyWith(
              isActivating: false,
              boardingPasses: updatedPasses,
              selectedPass: response.boardingPass,
              errorMessage: null,
            );

            // Remove from pending operations if it was there
            _removePendingOperation('activate:$passId');
            ref.read(networkConnectivityProvider.notifier).resetRetryCount();
          } else {
            state = state.copyWith(
              isActivating: false,
              errorMessage: response.errorMessage ?? '啟用登機證失敗',
            );
          }
        },
      );
    } catch (e) {
      // Network error - add to pending operations
      _addPendingOperation('activate:$passId');

      state = state.copyWith(
        isActivating: false,
        errorMessage: '網路錯誤，已加入待處理清單',
        hasPendingSync: true,
      );
    }
  }

  Future<void> handleQRScan(String qrCodeString) async {
    return validateQRCode(qrCodeString: qrCodeString);
  }

  /// Validate QR code with network awareness
  Future<void> validateQRCode({required String qrCodeString}) async {
    final networkState = ref.read(networkConnectivityProvider);

    state = state.copyWith(
      isScanning: true,
      scanResult: null,
      errorMessage: null,
    );

    try {
      final boardingPassService = ref.read(
        boardingPassApplicationServiceRefProvider,
      );

      // QR code validation can work offline with local validation
      final result = await boardingPassService.validateQRCode(
        qrCodeString: qrCodeString,
      );

      result.fold(
        (failure) {
          var errorMessage = _mapFailureToMessage(failure.message);

          // Add network context to error message
          if (!networkState.isOnline) {
            errorMessage += ' (離線驗證)';
          } else if (networkState.isPoorConnection) {
            errorMessage += ' (網路不穩定)';
          }

          state = state.copyWith(isScanning: false, errorMessage: errorMessage);
        },
        (validationResult) {
          state = state.copyWith(
            isScanning: false,
            scanResult: validationResult,
            errorMessage: null,
          );
        },
      );
    } catch (e) {
      final errorMessage = networkState.isOnline
          ? 'QR Code 驗證時發生錯誤'
          : 'QR Code 離線驗證失敗';

      state = state.copyWith(isScanning: false, errorMessage: errorMessage);
    }
  }

  Future<void> handleClearAction() async {
    clearScanResult();
    clearError();
    ref.read(qRScannerProvider.notifier).clearResult();
  }

  /// Perform automatic sync when network is available
  Future<void> _performAutoSync() async {
    if (!state.needsSync) return;

    final networkState = ref.read(networkConnectivityProvider);
    if (!networkState.isOnline || networkState.isPoorConnection) {
      return;
    }

    state = state.copyWith(lastSyncAttempt: DateTime.now());

    try {
      // Refresh data from server
      await loadBoardingPasses();

      // Process pending operations
      await _retryPendingOperations();
    } catch (e) {
      _logger.e('Auto sync failed: $e');
    }
  }

  /// Retry pending operations
  Future<void> _retryPendingOperations() async {
    if (state.pendingOperations.isEmpty) return;

    final networkState = ref.read(networkConnectivityProvider);
    if (!networkState.isOnline || networkState.isPoorConnection) {
      return;
    }

    final operations = List<String>.from(state.pendingOperations);

    for (final operation in operations) {
      try {
        await _executePendingOperation(operation);
      } catch (e) {
        _logger.e('Failed to retry operation $operation: $e');
      }
    }
  }

  /// Execute a pending operation
  Future<void> _executePendingOperation(String operation) async {
    final parts = operation.split(':');
    if (parts.length != 2) return;

    final action = parts[0];
    final passId = parts[1];

    switch (action) {
      case 'activate':
        await activateBoardingPass(passId);
        break;
      // Add other operations as needed
    }
  }

  /// Add operation to pending list
  void _addPendingOperation(String operation) {
    if (!state.pendingOperations.contains(operation)) {
      final operations = List<String>.from(state.pendingOperations);
      operations.add(operation);
      state = state.copyWith(pendingOperations: operations);
    }
  }

  /// Remove operation from pending list
  void _removePendingOperation(String operation) {
    final operations = List<String>.from(state.pendingOperations);
    operations.remove(operation);
    state = state.copyWith(pendingOperations: operations);
  }

  /// Check if failure is network-related
  bool _isNetworkFailure(String failureMessage) {
    final message = failureMessage.toLowerCase();
    return message.contains('network') ||
        message.contains('connection') ||
        message.contains('timeout') ||
        message.contains('unreachable') ||
        message.contains('no internet');
  }

  /// Manual sync trigger
  Future<void> forceSync() async {
    final networkState = ref.read(networkConnectivityProvider);

    if (!networkState.isOnline) {
      state = state.copyWith(errorMessage: '需要網路連線才能同步');
      return;
    }

    state = state.copyWith(hasPendingSync: true);
    await _performAutoSync();
  }

  /// Get network status description for UI
  String getNetworkStatusDescription() {
    final networkState = ref.read(networkConnectivityProvider);

    if (!networkState.isOnline) {
      return '離線模式';
    }

    if (networkState.isPoorConnection) {
      return '網路不穩定';
    }

    if (state.needsSync) {
      return '等待同步';
    }

    return networkState.connectionDescription;
  }

  // Existing methods remain unchanged...
  void selectBoardingPass(BoardingPassDTO pass) {
    state = state.copyWith(selectedPass: pass);
  }

  void clearScanResult() {
    state = state.copyWith(scanResult: null);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  Future<void> refresh() async {
    await loadBoardingPasses();
  }

  String _mapFailureToMessage(String failureMessage) {
    final message = failureMessage.toLowerCase();

    if (message.contains('not found') || message.contains('不存在')) {
      return '找不到登機證';
    }

    if (message.contains('expired') || message.contains('已過期')) {
      return '登機證已過期';
    }

    if (message.contains('used') || message.contains('已使用')) {
      return '登機證已使用';
    }

    if (message.contains('invalid') || message.contains('無效')) {
      return '登機證資料無效';
    }

    if (message.contains('network') || message.contains('connection')) {
      return '網路連線異常，請檢查網路設定';
    }

    if (message.contains('timeout')) {
      return '連線逾時，請稍後再試';
    }

    return failureMessage;
  }
}
