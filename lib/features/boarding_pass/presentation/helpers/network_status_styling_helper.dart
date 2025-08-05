import 'package:app/features/boarding_pass/presentation/notifiers/boarding_pass_notifier.dart';
import 'package:app/features/shared/presentation/providers/network_connectivity_provider.dart';
import 'package:flutter/material.dart';

Color getStatusBackgroundColor(
  NetworkConnectivityState networkState,
  BoardingPassState boardingPassState,
) {
  if (!networkState.isOnline) return Colors.red[50]!;
  if (networkState.isPoorConnection) return Colors.orange[50]!;
  if (boardingPassState.needsSync) return Colors.blue[50]!;
  return Colors.green[50]!;
}

Color getStatusBorderColor(
  NetworkConnectivityState networkState,
  BoardingPassState boardingPassState,
) {
  if (!networkState.isOnline) return Colors.red[200]!;
  if (networkState.isPoorConnection) return Colors.orange[200]!;
  if (boardingPassState.needsSync) return Colors.blue[200]!;
  return Colors.green[200]!;
}

IconData getStatusIcon(
  NetworkConnectivityState networkState,
  BoardingPassState boardingPassState,
) {
  if (!networkState.isOnline) return Icons.wifi_off;
  if (networkState.isPoorConnection) return Icons.network_check;
  if (boardingPassState.needsSync) return Icons.sync;
  return Icons.check_circle;
}

Color getStatusIconColor(
  NetworkConnectivityState networkState,
  BoardingPassState boardingPassState,
) {
  if (!networkState.isOnline) return Colors.red[600]!;
  if (networkState.isPoorConnection) return Colors.orange[600]!;
  if (boardingPassState.needsSync) return Colors.blue[600]!;
  return Colors.green[600]!;
}

Color getStatusTextColor(
  NetworkConnectivityState networkState,
  BoardingPassState boardingPassState,
) {
  if (!networkState.isOnline) return Colors.red[700]!;
  if (networkState.isPoorConnection) return Colors.orange[700]!;
  if (boardingPassState.needsSync) return Colors.blue[700]!;
  return Colors.green[700]!;
}

String getDetailedStatusText(
  NetworkConnectivityState networkState,
  BoardingPassState boardingPassState,
) {
  if (!networkState.isOnline) {
    return '離線模式：正在使用本地資料';
  }
  if (networkState.isPoorConnection) {
    return '網路連線不穩定：部分功能可能無法使用';
  }
  if (boardingPassState.needsSync) {
    return '有資料需要同步：${boardingPassState.pendingOperations.length} 項待處理操作';
  }
  return '網路連線正常';
}

bool shouldShowAdditionalInfo(
  NetworkConnectivityState networkState,
  BoardingPassState boardingPassState,
) {
  return !networkState.isOnline ||
      networkState.isPoorConnection ||
      boardingPassState.needsSync;
}

String formatDuration(Duration duration) {
  if (duration.inDays > 0) return '${duration.inDays}天';
  if (duration.inHours > 0) return '${duration.inHours}小時';
  if (duration.inMinutes > 0) return '${duration.inMinutes}分鐘';
  return '${duration.inSeconds}秒';
}
