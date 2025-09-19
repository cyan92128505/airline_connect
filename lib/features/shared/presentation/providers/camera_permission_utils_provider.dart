import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'camera_permission_provider.dart';

part 'camera_permission_utils_provider.g.dart';

/// Convenience provider for checking if camera permission is granted
@riverpod
bool isCameraPermissionGranted(Ref ref) {
  return ref.watch(cameraPermissionProvider).isGranted;
}

/// Convenience provider for checking if camera permission is denied
@riverpod
bool isCameraPermissionDenied(Ref ref) {
  return ref.watch(cameraPermissionProvider).isDenied;
}

/// Convenience provider for checking if camera permission is permanently denied
@riverpod
bool isCameraPermissionPermanentlyDenied(Ref ref) {
  return ref.watch(cameraPermissionProvider).isPermanentlyDenied;
}

/// Convenience provider for checking if we can request camera permission
@riverpod
bool canRequestCameraPermission(Ref ref) {
  return ref.watch(cameraPermissionProvider).canRequest;
}

/// Convenience provider for checking if we should show settings button
@riverpod
bool shouldShowCameraSettings(Ref ref) {
  return ref.watch(cameraPermissionProvider).shouldShowSettings;
}

/// Convenience provider for camera permission status
@riverpod
PermissionStatus cameraPermissionStatus(Ref ref) {
  return ref.watch(cameraPermissionProvider).status;
}

/// Convenience provider for camera permission error message
@riverpod
String? cameraPermissionError(Ref ref) {
  return ref.watch(cameraPermissionProvider).errorMessage;
}

/// Convenience provider for checking if permission request is in progress
@riverpod
bool isCameraPermissionRequesting(Ref ref) {
  return ref.watch(cameraPermissionProvider).isRequesting;
}

/// Convenience provider for camera permission status description
@riverpod
String cameraPermissionDescription(Ref ref) {
  return ref.watch(cameraPermissionProvider).statusDescription;
}
