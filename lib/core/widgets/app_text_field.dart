import 'package:flutter/material.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_dimensions.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';

class AppTextField extends StatelessWidget {
  final String label;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final bool obscureText;
  final String? hintText;
  final Widget? prefix;
  final Widget? suffix;
  final int? maxLength;
  final String? errorText;
  final ValueChanged<String>? onChanged;

  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.hintText,
    this.prefix,
    this.suffix,
    this.maxLength,
    this.errorText,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral400)),
        const SizedBox(height: AppDim.sm),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLength: maxLength,
          onChanged: onChanged,
          style: AppTextStyles.bodyLarge.copyWith(color: AppColors.neutral900),
          decoration: InputDecoration(
            counterText: "",
            hintText: hintText,
            prefixIcon: prefix,
            suffixIcon: suffix,
            filled: true,
            fillColor: AppColors.neutral100,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: AppDim.radiusMd,
              borderSide: BorderSide(color: AppColors.neutral200, width: AppDim.borderThin),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppDim.radiusMd,
              borderSide: BorderSide(color: AppColors.neutral200, width: AppDim.borderThin),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppDim.radiusMd,
              borderSide: BorderSide(color: AppColors.primary, width: AppDim.borderMedium),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: AppDim.radiusMd,
              borderSide: BorderSide(color: AppColors.error, width: AppDim.borderMedium),
            ),
            errorText: errorText,
          ),
        ),
      ],
    );
  }
}
