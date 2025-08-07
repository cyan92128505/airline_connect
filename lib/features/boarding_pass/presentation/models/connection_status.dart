import 'package:app/features/boarding_pass/presentation/notifiers/boarding_pass_notifier.dart';
import 'package:app/features/shared/presentation/providers/network_connectivity_provider.dart';
import 'package:app/features/shared/presentation/utils/date_formatter.dart';
import 'package:flutter/material.dart';

/// Sealed class representing different display states for network/boarding pass status
/// Each status encapsulates its own styling and behavior
sealed class ConnectionStatus {
  const ConnectionStatus();

  // Abstract properties that must be implemented by each status
  Color get backgroundColor;
  Color get borderColor;
  Color get textColor;
  Color get iconColor;
  IconData get icon;
  String get message;
  String get detailMessage;

  // Default behaviors that can be overridden
  bool get showSync => false;
  bool get hasIssue => true;
  bool get showAdditionalInfo => true;

  // Abstract method for generating additional info
  List<String> generateAdditionalInfo(
    NetworkConnectivityState networkState,
    BoardingPassState boardingPassState,
  );

  // Helper for secondary text color
  Color get secondaryTextColor => textColor.withAlpha(178);
}

/// Offline status - highest priority
class OfflineStatus extends ConnectionStatus {
  const OfflineStatus();

  @override
  Color get backgroundColor => Colors.red[50]!;

  @override
  Color get borderColor => Colors.red[200]!;

  @override
  Color get textColor => Colors.red[700]!;

  @override
  Color get iconColor => Colors.red[600]!;

  @override
  IconData get icon => Icons.wifi_off;

  @override
  String get message => '離線模式';

  @override
  String get detailMessage => '離線模式：正在使用本地資料';

  @override
  bool get showSync => false; // Can't sync when offline

  @override
  List<String> generateAdditionalInfo(
    NetworkConnectivityState networkState,
    BoardingPassState boardingPassState,
  ) {
    final info = <String>[];

    if (networkState.lastDisconnectedAt != null) {
      final duration = DateTime.now().difference(
        networkState.lastDisconnectedAt!,
      );
      info.add('離線時間：${DateFormatter.formatDuration(duration)}');
    }

    if (boardingPassState.pendingOperations.isNotEmpty) {
      info.add('待處理操作：${boardingPassState.pendingOperations.length} 項');
    }

    return info;
  }
}

/// Poor connection status - second priority
class PoorConnectionStatus extends ConnectionStatus {
  const PoorConnectionStatus();

  @override
  Color get backgroundColor => Colors.orange[50]!;

  @override
  Color get borderColor => Colors.orange[200]!;

  @override
  Color get textColor => Colors.orange[700]!;

  @override
  Color get iconColor => Colors.orange[600]!;

  @override
  IconData get icon => Icons.network_check;

  @override
  String get message => '網路不穩定';

  @override
  String get detailMessage => '網路連線不穩定：部分功能可能無法使用';

  @override
  bool get showSync => false; // Don't encourage sync with poor connection

  @override
  List<String> generateAdditionalInfo(
    NetworkConnectivityState networkState,
    BoardingPassState boardingPassState,
  ) {
    final info = <String>[];

    if (networkState.lastConnectedAt != null) {
      final duration = DateTime.now().difference(networkState.lastConnectedAt!);
      info.add('連線時間：${DateFormatter.formatDuration(duration)}');
    }

    // Show network quality if available
    if (networkState.quality != NetworkQuality.unknown) {
      info.add('網路品質：${networkState.quality.displayText}');
    }

    return info;
  }
}

/// Sync needed status - third priority
class SyncNeededStatus extends ConnectionStatus {
  const SyncNeededStatus();

  @override
  Color get backgroundColor => Colors.blue[50]!;

  @override
  Color get borderColor => Colors.blue[200]!;

  @override
  Color get textColor => Colors.blue[700]!;

  @override
  Color get iconColor => Colors.blue[600]!;

  @override
  IconData get icon => Icons.sync;

  @override
  String get message => '需要同步';

  @override
  String get detailMessage {
    // Dynamic detail message based on pending operations
    // This would need access to boarding pass state, but for simplicity using default
    return '有資料需要同步';
  }

  @override
  bool get showSync => true; // Show sync button for this status

  @override
  List<String> generateAdditionalInfo(
    NetworkConnectivityState networkState,
    BoardingPassState boardingPassState,
  ) {
    final info = <String>[];

    if (boardingPassState.pendingOperations.isNotEmpty) {
      info.add('待處理操作：${boardingPassState.pendingOperations.length} 項');
    }

    if (boardingPassState.lastSyncAttempt != null) {
      final duration = DateTime.now().difference(
        boardingPassState.lastSyncAttempt!,
      );
      info.add('上次同步：${DateFormatter.formatDuration(duration)}前');
    }

    if (networkState.lastConnectedAt != null) {
      final duration = DateTime.now().difference(networkState.lastConnectedAt!);
      info.add('連線時間：${DateFormatter.formatDuration(duration)}');
    }

    return info;
  }
}

/// Normal status - lowest priority, everything is good
class NormalStatus extends ConnectionStatus {
  const NormalStatus();

  @override
  Color get backgroundColor => Colors.green[50]!;

  @override
  Color get borderColor => Colors.green[200]!;

  @override
  Color get textColor => Colors.green[700]!;

  @override
  Color get iconColor => Colors.green[600]!;

  @override
  IconData get icon => Icons.check_circle;

  @override
  String get message => '網路正常';

  @override
  String get detailMessage => '網路連線正常';

  @override
  bool get hasIssue => false; // No issues for normal status

  @override
  bool get showAdditionalInfo => false; // No additional info needed

  @override
  List<String> generateAdditionalInfo(
    NetworkConnectivityState networkState,
    BoardingPassState boardingPassState,
  ) {
    return []; // No additional info for normal status
  }
}
