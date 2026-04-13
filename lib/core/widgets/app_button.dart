import 'package:flutter/material.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_dimensions.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';

class AppButton extends StatefulWidget {
  final String text;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool isOutlined;
  final bool fullWidth;

  const AppButton({
    super.key,
    required this.text,
    this.onTap,
    this.isLoading = false,
    this.isOutlined = false,
    this.fullWidth = true,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null) setState(() => _scale = 0.97);
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap != null) setState(() => _scale = 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onTap == null || widget.isLoading;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: () => setState(() => _scale = 1.0),
      onTap: isDisabled ? null : widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: widget.fullWidth ? double.infinity : null,
          height: 56,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppDim.md),
          decoration: BoxDecoration(
            color: widget.isOutlined
                ? Colors.transparent
                : (isDisabled ? AppColors.neutral200 : AppColors.primary),
            borderRadius: AppDim.radiusLg,
            border: widget.isOutlined
                ? Border.all(color: AppColors.primary, width: 1.5)
                : null,
          ),
          child: widget.isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  widget.text,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: widget.isOutlined
                        ? AppColors.primary
                        : (isDisabled ? AppColors.neutral400 : Colors.white),
                  ),
                ),
        ),
      ),
    );
  }
}
