import 'package:app/features/boarding_pass/presentation/helpers/network_status_styling_helper.dart';
import 'package:app/features/boarding_pass/presentation/notifiers/boarding_pass_notifier.dart';
import 'package:app/features/shared/presentation/providers/network_connectivity_provider.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class AdditionalInfo extends HookConsumerWidget {
  const AdditionalInfo({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final boardingPassState = ref.watch(boardingPassNotifierProvider);
    final networkState = ref.watch(networkConnectivityProvider);

    final info = <String>[];

    if (!networkState.isOnline) {
      if (networkState.lastDisconnectedAt != null) {
        final timeSince = DateTime.now().difference(
          networkState.lastDisconnectedAt!,
        );
        info.add('離線時間：${formatDuration(timeSince)}');
      }
    } else {
      if (networkState.lastConnectedAt != null) {
        final timeSince = DateTime.now().difference(
          networkState.lastConnectedAt!,
        );
        info.add('連線時間：${formatDuration(timeSince)}');
      }

      final uptime = ref
          .read(networkConnectivityProvider.notifier)
          .getUptimePercentage();
      info.add('網路穩定度：${uptime.toStringAsFixed(1)}%');
    }

    if (boardingPassState.pendingOperations.isNotEmpty) {
      info.add('待處理操作：${boardingPassState.pendingOperations.length} 項');
    }

    if (boardingPassState.lastSyncAttempt != null) {
      final timeSince = DateTime.now().difference(
        boardingPassState.lastSyncAttempt!,
      );
      info.add('上次同步：${formatDuration(timeSince)}前');
    }

    if (info.isEmpty) return SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: info
          .map(
            (text) => Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 12,
                  color: getStatusTextColor(
                    networkState,
                    boardingPassState,
                  ).withAlpha(178),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
