import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_dimensions.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';

class AppButton extends StatefulWidget {
  final String text;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool isOutlined;
  final bool fullWidth;
  final double height;
  final Widget? icon;
  final BorderRadius? borderRadius;

  const AppButton({
    super.key,
    required this.text,
    this.onTap,
    this.isLoading = false,
    this.isOutlined = false,
    this.fullWidth = true,
    this.height = 54.0,
    this.icon,
    this.borderRadius,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null && !widget.isLoading) {
      HapticFeedback.lightImpact();
      setState(() => _scale = 0.97);
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap != null && !widget.isLoading) {
      setState(() => _scale = 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onTap == null || widget.isLoading;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = widget.borderRadius ?? AppDim.radiusLg;

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
          height: widget.height,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: AppDim.md),
          decoration: BoxDecoration(
            color: widget.isOutlined
                ? Colors.transparent
                : (isDisabled ? (isDark ? AppColors.neutral800 : AppColors.neutral200) : AppColors.primary),
            borderRadius: radius,
            border: widget.isOutlined
                ? Border.all(color: AppColors.primary, width: 1.5)
                : null,
          ),
          child: widget.isLoading
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      widget.icon!,
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.text,
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        color: widget.isOutlined
                            ? AppColors.primary
                            : (isDisabled ? (isDark ? AppColors.neutral600 : AppColors.neutral400) : Colors.white),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
