import 'package:flutter/material.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';

/// Reusable Pizza image placeholder widget.
///
/// Displays the stylized pizza brand illustration with a graceful icon fallback.
class PizzaImagePlaceholder extends StatelessWidget {
  final double? width;
  final double? height;
  final BoxFit fit;

  const PizzaImagePlaceholder({
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: width,
      height: height,
      color: isDark ? AppColors.neutral800 : const Color(0xFFF8F9FA),
      alignment: Alignment.center,
      child: Image.asset(
        'assets/icons/pizza_placeholder.jpg',
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (_, __, ___) => Image.asset(
          'assets/icons/pizza_placeholder.png',
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (_, __, ___) => Center(
            child: Icon(
              Icons.local_pizza_rounded,
              color: isDark ? AppColors.neutral600 : AppColors.neutral400,
              size: (width != null && width! < 60) ? 28 : 44,
            ),
          ),
        ),
      ),
    );
  }
}
