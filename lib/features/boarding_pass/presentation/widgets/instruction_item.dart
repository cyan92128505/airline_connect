import 'package:app/core/presentation/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class InstructionItem extends StatelessWidget {
  final String item;
  const InstructionItem(this.item, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: AppColors.success, size: 16),
          const Gap(12),
          Expanded(
            child: Text(
              item,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
