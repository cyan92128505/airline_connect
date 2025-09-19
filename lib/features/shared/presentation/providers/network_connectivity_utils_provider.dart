import 'package:app/features/shared/presentation/providers/network_connectivity_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'network_connectivity_utils_provider.g.dart';

/// Convenience provider for checking if online
@riverpod
bool isOnline(Ref ref) {
  return ref.watch(networkConnectivityProvider).isOnline;
}

/// Convenience provider for connection type
@riverpod
ConnectivityResult connectionType(Ref ref) {
  return ref.watch(networkConnectivityProvider).connectionType;
}

/// Convenience provider for network quality
@riverpod
NetworkQuality networkQuality(Ref ref) {
  return ref.watch(networkConnectivityProvider).quality;
}
