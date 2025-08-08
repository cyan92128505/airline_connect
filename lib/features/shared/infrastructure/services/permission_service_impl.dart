import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';
import '../../domain/services/permission_service.dart';

/// Implementation of PermissionService using permission_handler package
class PermissionServiceImpl implements PermissionService {
  static final Logger _logger = Logger();

  @override
  Future<PermissionStatus> checkPermission(Permission permission) async {
    try {
      _logger.d('Checking permission: $permission');
      final status = await permission.status;
      _logger.i('Permission $permission status: $status');
      return status;
    } catch (e) {
      _logger.e('Error checking permission $permission: $e');
      rethrow;
    }
  }

  @override
  Future<PermissionStatus> requestPermission(Permission permission) async {
    try {
      _logger.d('Requesting permission: $permission');
      final status = await permission.request();
      _logger.i('Permission $permission request result: $status');
      return status;
    } catch (e) {
      _logger.e('Error requesting permission $permission: $e');
      rethrow;
    }
  }

  @override
  Future<bool> openAppSettings() async {
    try {
      _logger.d('Opening app settings');
      final result = await openAppSettings();
      _logger.i('App settings opened: $result');
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
