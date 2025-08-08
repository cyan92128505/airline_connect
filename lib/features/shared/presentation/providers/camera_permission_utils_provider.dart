import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'camera_permission_provider.dart';

part 'camera_permission_utils_provider.g.dart';

/// Convenience provider for checking if camera permission is granted
@riverpod
bool isCameraPermissionGranted(Ref<bool> ref) {
  return ref.watch(cameraPermissionProvider).isGranted;
}

/// Convenience provider for checking if camera permission is denied
@riverpod
bool isCameraPermissionDenied(Ref<bool> ref) {
  return ref.watch(cameraPermissionProvider).isDenied;
}

/// Convenience provider for checking if camera permission is permanently denied
@riverpod
bool isCameraPermissionPermanentlyDenied(Ref<bool> ref) {
  return ref.watch(cameraPermissionProvider).isPermanentlyDenied;
}

/// Convenience provider for checking if we can request camera permission
@riverpod
bool canRequestCameraPermission(Ref<bool> ref) {
  return ref.watch(cameraPermissionProvider).canRequest;
}

/// Convenience provider for checking if we should show settings button
@riverpod
bool shouldShowCameraSettings(Ref<bool> ref) {
  return ref.watch(cameraPermissionProvider).shouldShowSettings;
}

/// Convenience provider for camera permission status
@riverpod
PermissionStatus cameraPermissionStatus(Ref<PermissionStatus> ref) {
  return ref.watch(cameraPermissionProvider).status;
}

/// Convenience provider for camera permission error message
@riverpod
String? cameraPermissionError(Ref<String?> ref) {
  return ref.watch(cameraPermissionProvider).errorMessage;
}

/// Convenience provider for checking if permission request is in progress
@riverpod
bool isCameraPermissionRequesting(Ref<bool> ref) {
  return ref.watch(cameraPermissionProvider).isRequesting;
}

/// Convenience provider for camera permission status description
@riverpod
String cameraPermissionDescription(Ref<String> ref) {
  return ref.watch(cameraPermissionProvider).statusDescription;
}
