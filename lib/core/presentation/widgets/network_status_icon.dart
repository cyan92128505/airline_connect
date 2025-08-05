import 'package:app/features/shared/presentation/providers/network_connectivity_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class NetworkStatusIcon extends StatelessWidget {
  final NetworkConnectivityState networkState;

  const NetworkStatusIcon(this.networkState, {super.key});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    if (!networkState.isOnline) {
      icon = Icons.wifi_off;
      color = Colors.red[300]!;
    } else if (networkState.isPoorConnection) {
      icon = Icons.wifi_1_bar;
      color = Colors.orange[300]!;
    } else {
      switch (networkState.connectionType) {
        case ConnectivityResult.wifi:
          icon = Icons.wifi;
          color = Colors.green[300]!;
          break;
        case ConnectivityResult.mobile:
          icon = Icons.signal_cellular_4_bar;
          color = Colors.green[300]!;
          break;
        case ConnectivityResult.ethernet:
          icon = Icons.computer;
          color = Colors.green[300]!;
          break;
        default:
          icon = Icons.wifi_off;
          color = Colors.red[300]!;
      }
    }

    return Icon(icon, color: color, size: 20);
  }
}
