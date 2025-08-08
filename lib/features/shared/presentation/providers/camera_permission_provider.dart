import 'package:app/di/dependency_injection.dart';
import 'package:app/features/shared/application/services/permission_application_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'camera_permission_provider.freezed.dart';
part 'camera_permission_provider.g.dart';

/// State for camera permission management
@freezed
abstract class CameraPermissionState with _$CameraPermissionState {
  const factory CameraPermissionState({
    @Default(PermissionStatus.denied) PermissionStatus status,
    @Default(false) bool isRequesting,
    String? errorMessage,
  }) = _CameraPermissionState;

  const CameraPermissionState._();

  /// Whether camera permission is granted
  bool get isGranted => status == PermissionStatus.granted;

  /// Whether camera permission is denied
  bool get isDenied => status == PermissionStatus.denied;

  /// Whether camera permission is permanently denied
  bool get isPermanentlyDenied => status == PermissionStatus.permanentlyDenied;

  /// Whether camera permission is restricted by system
  bool get isRestricted => status == PermissionStatus.restricted;

  /// Whether we can request permission (not permanently denied)
  bool get canRequest => !isPermanentlyDenied && !isRestricted;

  /// Whether we should show settings button
  bool get shouldShowSettings => isPermanentlyDenied;

  /// Get user-friendly status description
  String get statusDescription {
    return switch (status) {
      PermissionStatus.granted => '相機權限已授權',
      PermissionStatus.denied => '相機權限被拒絕',
      PermissionStatus.permanentlyDenied => '相機權限被永久拒絕',
      PermissionStatus.restricted => '相機權限被系統限制',
      PermissionStatus.limited => '相機權限受限制',
      PermissionStatus.provisional => '相機權限為暫時授權',
    };
  }
}

/// Provider for managing camera permission state and operations
@riverpod
class CameraPermission extends _$CameraPermission {
  static final Logger _logger = Logger();
  late final PermissionApplicationService _permissionAppService;

  @override
  CameraPermissionState build() {
    _setup();

    return const CameraPermissionState();
  }

  Future<void> _setup() async {
    _permissionAppService = ref.watch(permissionApplicationServiceProvider);

    // Auto-check permission status on initialization
    _checkPermissionStatus();
  }

  /// Check current permission status without requesting
  Future<void> checkPermissionStatus() async {
    await _checkPermissionStatus();
  }

  /// Request camera permission from user
  Future<bool> requestPermission() async {
    if (state.isRequesting) {
      _logger.w('Permission request already in progress');
      return state.isGranted;
    }

    _logger.d('Requesting camera permission');

    state = state.copyWith(isRequesting: true, errorMessage: null);

    try {
      final result = await _permissionAppService.ensureCameraPermission();

      return result.when(
        granted: () {
          _logger.i('Camera permission granted');
          state = state.copyWith(
            status: PermissionStatus.granted,
            isRequesting: false,
            errorMessage: null,
          );
          return true;
        },
        denied: () {
          _logger.w('Camera permission denied by user');
          final message = _permissionAppService
              .getCameraPermissionResultMessage(result);
          state = state.copyWith(
            status: PermissionStatus.denied,
            isRequesting: false,
            errorMessage: message,
          );
          return false;
        },
        permanentlyDenied: () {
          _logger.w('Camera permission permanently denied');
          final message = _permissionAppService
              .getCameraPermissionResultMessage(result);
          state = state.copyWith(
            status: PermissionStatus.permanentlyDenied,
            isRequesting: false,
            errorMessage: message,
          );
          return false;
        },
      );
    } catch (e) {
      _logger.e('Error requesting camera permission: $e');
      state = state.copyWith(
        status: PermissionStatus.denied,
        isRequesting: false,
        errorMessage: '無法取得相機權限：$e',
      );
      return false;
    }
  }

  /// Open app settings for user to manually enable permission
  Future<void> openSettings() async {
    try {
      _logger.d('Opening app settings for camera permission');
      final opened = await _permissionAppService.openAppSettings();

      if (!opened) {
        _logger.w('Failed to open app settings');
        state = state.copyWith(errorMessage: '無法開啟設定頁面');
      } else {
        _logger.i('App settings opened successfully');
        // Clear error message as user is going to settings
        state = state.copyWith(errorMessage: null);
      }
    } catch (e) {
      _logger.e('Error opening app settings: $e');
      state = state.copyWith(errorMessage: '開啟設定時發生錯誤');
    }
  }

  /// Clear any error message
  void clearError() {
    if (state.errorMessage != null) {
      _logger.d('Clearing permission error message');
      state = state.copyWith(errorMessage: null);
    }
  }

  /// Reset permission state (useful for testing or refresh)
  void reset() {
    _logger.d('Resetting camera permission state');
    state = const CameraPermissionState();
    _checkPermissionStatus();
  }

  /// Check if we should show permission rationale to user
  Future<bool> shouldShowRationale() async {
    try {
      return await _permissionAppService.shouldShowCameraPermissionRationale();
    } catch (e) {
      _logger.e('Error checking permission rationale: $e');
      return false;
    }
  }

  /// Private method to check permission status
  Future<void> _checkPermissionStatus() async {
    try {
      _logger.d('Checking current camera permission status');

      final status = await Permission.camera.status;

      _logger.i('Current camera permission status: $status');

      // Only update if status actually changed to avoid unnecessary rebuilds
      if (state.status != status) {
        state = state.copyWith(status: status, errorMessage: null);
      }
    } catch (e) {
      _logger.e('Error checking camera permission status: $e');
      state = state.copyWith(errorMessage: '檢查權限狀態時發生錯誤');
    }
  }
}
