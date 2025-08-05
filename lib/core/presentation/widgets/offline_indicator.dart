import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:app/features/shared/presentation/providers/network_connectivity_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Enhanced offline indicator that shows detailed network status
class OfflineIndicator extends ConsumerWidget {
  const OfflineIndicator({
    super.key,
    this.showDetailedStatus = false,
    this.onRetry,
  });

  final bool showDetailedStatus;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networkState = ref.watch(networkConnectivityProvider);

    // Don't show indicator if network is stable and good
    if (networkState.isOnline &&
        networkState.isStable &&
        networkState.quality == NetworkQuality.good) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _getBackgroundColor(networkState),
        border: Border(
          bottom: BorderSide(color: _getBorderColor(networkState), width: 1),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            _buildStatusIcon(networkState),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getStatusTitle(networkState),
                    style: TextStyle(
                      color: _getTextColor(networkState),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (showDetailedStatus) ...[
                    const SizedBox(height: 4),
                    Text(
                      _getDetailedStatus(networkState),
                      style: TextStyle(
                        color: _getTextColor(networkState).withAlpha(178),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (_shouldShowRetryButton(networkState) && onRetry != null)
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  foregroundColor: _getTextColor(networkState),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                ),
                child: Text(
                  _getRetryButtonText(networkState),
                  style: TextStyle(fontSize: 12),
                ),
              ),
            if (networkState.isRetrying)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getTextColor(networkState),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(NetworkConnectivityState networkState) {
    IconData iconData;

    if (networkState.isRetrying) {
      iconData = Icons.sync;
    } else if (!networkState.isOnline) {
      iconData = Icons.wifi_off;
    } else if (networkState.isPoorConnection) {
      iconData = Icons.signal_wifi_bad;
    } else {
      switch (networkState.connectionType) {
        case ConnectivityResult.wifi:
          iconData = Icons.wifi;
          break;
        case ConnectivityResult.mobile:
          iconData = Icons.signal_cellular_alt;
          break;
        case ConnectivityResult.ethernet:
          iconData = Icons.computer;
          break;
        default:
          iconData = Icons.wifi_off;
      }
    }

    Widget icon = Icon(iconData, color: _getTextColor(networkState), size: 20);

    // Add rotation animation for retry state
    if (networkState.isRetrying) {
      return RotatingIcon(child: icon);
    }

    return icon;
  }

  Color _getBackgroundColor(NetworkConnectivityState networkState) {
    if (!networkState.isOnline) {
      return Colors.red[100]!;
    } else if (networkState.isPoorConnection) {
      return Colors.orange[100]!;
    } else if (!networkState.isStable) {
      return Colors.yellow[100]!;
    }
    return Colors.blue[100]!;
  }

  Color _getBorderColor(NetworkConnectivityState networkState) {
    if (!networkState.isOnline) {
      return Colors.red[300]!;
    } else if (networkState.isPoorConnection) {
      return Colors.orange[300]!;
    } else if (!networkState.isStable) {
      return Colors.yellow[300]!;
    }
    return Colors.blue[300]!;
  }

  Color _getTextColor(NetworkConnectivityState networkState) {
    if (!networkState.isOnline) {
      return Colors.red[800]!;
    } else if (networkState.isPoorConnection) {
      return Colors.orange[800]!;
    } else if (!networkState.isStable) {
      return Colors.yellow[800]!;
    }
    return Colors.blue[800]!;
  }

  String _getStatusTitle(NetworkConnectivityState networkState) {
    if (networkState.isRetrying) {
      return '正在重新連線... (${networkState.retryCount}/3)';
    } else if (!networkState.isOnline) {
      return '離線模式';
    } else if (networkState.isPoorConnection) {
      return '網路連線不穩定';
    } else if (!networkState.isStable) {
      return '連線中...';
    }
    return '網路狀態異常';
  }

  String _getDetailedStatus(NetworkConnectivityState networkState) {
    if (!networkState.isOnline) {
      final lastDisconnected = networkState.lastDisconnectedAt;
      if (lastDisconnected != null) {
        final duration = DateTime.now().difference(lastDisconnected);
        return '已離線 ${_formatDuration(duration)}，正在使用本地資料';
      }
      return '目前無網路連線，正在使用本地資料';
    } else if (networkState.isPoorConnection) {
      switch (networkState.quality) {
        case NetworkQuality.poor:
          return '網路延遲較高，部分功能可能受影響';
        case NetworkQuality.fair:
          return '網路速度一般，建議避免大量資料傳輸';
        default:
          return '網路連線品質不佳';
      }
    } else if (!networkState.isStable) {
      return '剛連上網路，正在檢查連線穩定性';
    }
    return networkState.connectionDescription;
  }

  bool _shouldShowRetryButton(NetworkConnectivityState networkState) {
    return !networkState.isOnline &&
        !networkState.isRetrying &&
        networkState.retryCount < 3;
  }

  String _getRetryButtonText(NetworkConnectivityState networkState) {
    if (networkState.retryCount > 0) {
      return '重試 (${networkState.retryCount}/3)';
    }
    return '重試連線';
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      return '${duration.inDays}天${duration.inHours % 24}小時';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}小時${duration.inMinutes % 60}分鐘';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}分鐘';
    } else {
      return '${duration.inSeconds}秒';
    }
  }
}

/// Widget that provides rotating animation for sync icons
class RotatingIcon extends StatefulWidget {
  const RotatingIcon({
    super.key,
    required this.child,
    this.duration = const Duration(seconds: 2),
  });

  final Widget child;
  final Duration duration;

  @override
  State<RotatingIcon> createState() => _RotatingIconState();
}

class _RotatingIconState extends State<RotatingIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        return Transform.rotate(
          angle: _controller.value * 2.0 * 3.14159,
          child: child,
        );
      },
    );
  }
}

/// Compact version of offline indicator for use in app bars
class CompactOfflineIndicator extends ConsumerWidget {
  const CompactOfflineIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networkState = ref.watch(networkConnectivityProvider);

    // Don't show if network is good
    if (networkState.isOnline &&
        networkState.isStable &&
        networkState.quality == NetworkQuality.good) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getCompactBackgroundColor(networkState),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getCompactIcon(networkState), size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            _getCompactText(networkState),
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCompactBackgroundColor(NetworkConnectivityState networkState) {
    if (!networkState.isOnline) {
      return Colors.red[600]!;
    } else if (networkState.isPoorConnection) {
      return Colors.orange[600]!;
    }
    return Colors.blue[600]!;
  }

  IconData _getCompactIcon(NetworkConnectivityState networkState) {
    if (!networkState.isOnline) {
      return Icons.wifi_off;
    } else if (networkState.isPoorConnection) {
      return Icons.signal_wifi_bad;
    }
    return Icons.wifi;
  }

  String _getCompactText(NetworkConnectivityState networkState) {
    if (!networkState.isOnline) {
      return '離線';
    } else if (networkState.isPoorConnection) {
      return '訊號弱';
    }
    return '連線中';
  }
}

/// Network status badge for showing in lists or cards
class NetworkStatusBadge extends ConsumerWidget {
  const NetworkStatusBadge({super.key, this.showLabel = true});

  final bool showLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final networkState = ref.watch(networkConnectivityProvider);

    Color badgeColor;
    IconData badgeIcon;
    String badgeLabel;

    if (!networkState.isOnline) {
      badgeColor = Colors.red;
      badgeIcon = Icons.wifi_off;
      badgeLabel = '離線';
    } else if (networkState.isPoorConnection) {
      badgeColor = Colors.orange;
      badgeIcon = Icons.signal_wifi_bad;
      badgeLabel = '訊號弱';
    } else if (!networkState.isStable) {
      badgeColor = Colors.yellow[700]!;
      badgeIcon = Icons.wifi;
      badgeLabel = '連線中';
    } else {
      badgeColor = Colors.green;
      badgeIcon = Icons.wifi;
      badgeLabel = '良好';
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: showLabel ? 8 : 4, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor.withAlpha(76)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 14, color: badgeColor),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              badgeLabel,
              style: TextStyle(
                color: badgeColor,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
