import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ExtractedDataChip extends StatelessWidget {
  final Map<String, dynamic> data;

  const ExtractedDataChip({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    // Collect specific highlighted values to show in chip
    String displayText = "Data Extracted \u2713";
    
    if (data.containsKey('id_number')) {
      final String idStr = data['id_number'].toString();
      displayText = idStr.length > 4 
          ? "Ended in ...${idStr.substring(idStr.length - 4)}" 
          : "ID: $idStr";
    }

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.verifiedLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.verified, size: 14),
          const SizedBox(width: 6),
          Text(
            displayText,
            style: AppTypography.chip.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2, end: 0);
  }
}
