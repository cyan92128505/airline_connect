import 'package:app/features/shared/domain/services/permission_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'permission_application_service.freezed.dart';

/// Result of camera permission request
@freezed
class CameraPermissionResult with _$CameraPermissionResult {
  const factory CameraPermissionResult.granted() = _Granted;
  const factory CameraPermissionResult.denied() = _Denied;
  const factory CameraPermissionResult.permanentlyDenied() = _PermanentlyDenied;
}

/// Application service for handling permission business logic
class PermissionApplicationService {
  final PermissionService _permissionService;
  static final Logger _logger = Logger();

  const PermissionApplicationService(this._permissionService);

  /// Ensure camera permission is available for use
  /// Returns result indicating permission status and suggested action
  Future<CameraPermissionResult> ensureCameraPermission() async {
    try {
      _logger.d('Ensuring camera permission...');

      final status = await _permissionService.checkPermission(
        Permission.camera,
      );

      if (status.isGranted) {
        _logger.i('Camera permission already granted');
        return const CameraPermissionResult.granted();
      }

      if (status.isPermanentlyDenied) {
        _logger.w('Camera permission permanently denied');
        return const CameraPermissionResult.permanentlyDenied();
      }

      _logger.d('Requesting camera permission from user');
      final result = await _permissionService.requestPermission(
        Permission.camera,
      );

      if (result.isGranted) {
        _logger.i('Camera permission granted by user');
        return const CameraPermissionResult.granted();
      } else {
        _logger.w('Camera permission denied by user');
        return const CameraPermissionResult.denied();
      }
    } catch (e) {
      _logger.e('Error ensuring camera permission: $e');
      return const CameraPermissionResult.denied();
    }
  }

  /// Get user-friendly message for camera permission status
  String getCameraPermissionMessage(PermissionStatus status) {
    return switch (status) {
      PermissionStatus.denied => '需要相機權限才能掃描 QR Code',
      PermissionStatus.permanentlyDenied => '請前往設定開啟相機權限',
      PermissionStatus.restricted => '此裝置限制使用相機功能',
      PermissionStatus.limited => '相機權限受限制',
      PermissionStatus.provisional => '相機權限為暫時授權',
      PermissionStatus.granted => '相機權限已授權',
    };
  }

  /// Get user-friendly message for camera permission result
  String getCameraPermissionResultMessage(CameraPermissionResult result) {
    return result.when(
      granted: () => '相機權限已授權',
      denied: () => '需要相機權限才能掃描 QR Code',
      permanentlyDenied: () => '請前往設定開啟相機權限',
    );
  }

  /// Check if we should show rationale to user
  /// Returns true when permission was denied but not permanently
  Future<bool> shouldShowCameraPermissionRationale() async {
    try {
      final status = await _permissionService.checkPermission(
        Permission.camera,
      );
      return status.isDenied && !status.isPermanentlyDenied;
    } catch (e) {
      _logger.e('Error checking permission rationale: $e');
      return false;
    }
  }

  /// Open app settings for user to manually enable permissions
  Future<bool> openAppSettings() async {
    try {
      _logger.d('Opening app settings for permission configuration');
      return await _permissionService.openAppSettings();
    } catch (e) {
      _logger.e('Error opening app settings: $e');
      return false;
    }
  }
}
