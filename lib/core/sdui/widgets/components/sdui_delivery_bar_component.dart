import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../models/sdui_section_model.dart';
import '../../registry/sdui_action_dispatcher.dart';

/// 📍 Delivery & Branch Location Status Bar
/// Displays active branch, ETA, and resolved delivery zone.
class SDUIDeliveryBarComponent extends StatelessWidget {
  final SDUISectionModel section;
  final SDUIActionHandler onAction;

  const SDUIDeliveryBarComponent({
    super.key,
    required this.section,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final branchTitle = section.properties['branch_title'] as String? ?? 'Pizza Strada';
    final etaMinutes = section.properties['eta_minutes'] as num? ?? 30;
    final address = section.properties['address'] as String? ?? 'Samarqand shahri';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.neutral200.withValues(alpha: 0.7),
          width: 1,
        ),
        boxShadow: AppColors.softShadow(isDark),
      ),
      child: Row(
        children: [
          // Location Badge
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Titles
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  branchTitle,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: isDark ? Colors.white : AppColors.neutral900,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  address,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.neutral500,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // ETA Pill Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.electric_bolt_rounded,
                  size: 14,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 4),
                Text(
                  '~$etaMinutes daq',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
