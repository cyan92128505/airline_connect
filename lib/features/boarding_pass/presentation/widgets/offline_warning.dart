import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class OfflineWarning extends StatelessWidget {
  final String message;

  const OfflineWarning(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange[600], size: 16),
            const Gap(8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: Colors.orange[700], fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
