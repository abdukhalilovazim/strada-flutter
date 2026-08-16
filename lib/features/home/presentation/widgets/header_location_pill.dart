import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';

/// Header Location Pill widget matching pizzastrada.uz location selector.
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

    final String modeLabel = orderType == 0
        ? 'checkout.delivery'.tr()
        : 'checkout.pickup'.tr();

    final String displayTitle = orderType == 0
        ? (addressName != null && addressName!.isNotEmpty
            ? addressName!
            : 'checkout.select_address'.tr())
        : (branchTitle != null && branchTitle!.isNotEmpty
            ? branchTitle!
            : 'checkout.select_branch'.tr());

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        constraints: const BoxConstraints(maxWidth: 200),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : AppColors.neutral100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.neutral800 : AppColors.neutral200,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.location_on_rounded,
              color: AppColors.primary,
              size: 16,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    modeLabel,
                    style: AppTextStyles.bodyExtraSmall.copyWith(
                      fontSize: 9,
                      color: isDark ? AppColors.neutral400 : AppColors.neutral600,
                      height: 1.1,
                    ),
                  ),
                  Text(
                    displayTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSmall.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: theme.textTheme.bodyLarge?.color,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: isDark ? AppColors.neutral400 : AppColors.neutral600,
            ),
          ],
        ),
      ),
    );
  }
}
