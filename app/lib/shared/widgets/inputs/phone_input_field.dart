import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import 'app_text_field.dart';

class PhoneInputField extends StatelessWidget {
  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  const PhoneInputField({
    super.key,
    required this.controller,
    this.errorText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: 'Mobile Number',
      hint: '9876543210',
      controller: controller,
      errorText: errorText,
      keyboardType: TextInputType.phone,
      maxLength: 10,
      onChanged: onChanged,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 16, right: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '+91',
              style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(width: 8),
            Container(
              width: 1,
              height: 24,
              color: AppColors.divider,
            ),
          ],
        ),
      ),
    );
  }
}
