import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';

/// Header Location widget displaying address/branch text with a chevron icon,
/// matching Yandex Eats clean typography without button capsule styling.
class HeaderLocationPill extends StatelessWidget {
  final int orderType; // 0 = Delivery, 1 = Pickup
  final String? addressName;
  final String? branchTitle;
  final VoidCallback onTap;

  const HeaderLocationPill({
    super.key,
    required this.orderType,
    this.addressName,
    this.branchTitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final String displayTitle = orderType == 0
        ? (addressName != null && addressName!.isNotEmpty
            ? addressName!
            : 'checkout.select_address'.tr())
        : (branchTitle != null && branchTitle!.isNotEmpty
            ? branchTitle!
            : 'checkout.select_branch'.tr());

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                displayTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : AppColors.neutral900,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: isDark ? AppColors.neutral300 : AppColors.neutral700,
            ),
          ],
        ),
      ),
    );
  }
}
