import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';
import '../../domain/services/permission_service.dart';

/// Implementation of PermissionService using permission_handler package
class PermissionServiceImpl implements PermissionService {
  static final Logger _logger = Logger();

  @override
  Future<PermissionStatus> checkPermission(Permission permission) async {
    try {
      final status = await permission.status;
      return status;
    } catch (e) {
      _logger.e('Error checking permission $permission: $e');
      rethrow;
    }
  }

  @override
  Future<PermissionStatus> requestPermission(Permission permission) async {
    try {
      final status = await permission.request();
      return status;
    } catch (e) {
      _logger.e('Error requesting permission $permission: $e');
      rethrow;
    }
  }

  @override
  Future<bool> openAppSettings() async {
    try {
      final result = await openAppSettings();
      return result;
    } catch (e) {
      _logger.e('Error opening app settings: $e');
      rethrow;
    }
  }

  @override
  Future<bool> isPermissionGranted(Permission permission) async {
    final status = await checkPermission(permission);
    return status.isGranted;
  }

  @override
  Future<bool> isPermissionDenied(Permission permission) async {
    final status = await checkPermission(permission);
    return status.isDenied;
  }

  @override
  Future<bool> isPermissionPermanentlyDenied(Permission permission) async {
    final status = await checkPermission(permission);
    return status.isPermanentlyDenied;
  }
}
