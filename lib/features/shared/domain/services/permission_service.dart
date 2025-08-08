import 'package:permission_handler/permission_handler.dart';

/// Abstract service for handling system permissions
abstract class PermissionService {
  /// Check current status of a permission
  Future<PermissionStatus> checkPermission(Permission permission);

  /// Request a permission from user
  Future<PermissionStatus> requestPermission(Permission permission);

  /// Open app settings page
  Future<bool> openAppSettings();

  /// Check if permission is granted
  Future<bool> isPermissionGranted(Permission permission);

  /// Check if permission is denied
  Future<bool> isPermissionDenied(Permission permission);

  /// Check if permission is permanently denied
  Future<bool> isPermissionPermanentlyDenied(Permission permission);
}