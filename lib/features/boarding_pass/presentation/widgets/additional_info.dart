import 'package:app/features/boarding_pass/presentation/providers/connection_status_provider.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class AdditionalInfo extends HookConsumerWidget {
  const AdditionalInfo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(connectionStatusProvider);
    final additionalInfo = ref.watch(connectionStatusAdditionalInfoProvider);

    // Only show if status requires additional info and there are items
    if (!status.showAdditionalInfo || additionalInfo.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: additionalInfo
          .map(
            (text) => Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 12,
                  color: status.secondaryTextColor, // Use sealed class property
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
