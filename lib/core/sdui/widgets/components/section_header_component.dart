import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../models/section_model.dart';
import '../../registry/action_dispatcher.dart';

class SDUISectionHeaderComponent extends StatelessWidget {
  final SDUISectionModel section;
  final SDUIActionHandler onAction;

  const SDUISectionHeaderComponent({
    super.key,
    required this.section,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = section.properties['title'] as String? ?? '';
    final subtitle = section.properties['subtitle'] as String?;
    final actionLabel = section.properties['action_label'] as String?;

    if (title.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.h2.copyWith(
                    color: isDark ? Colors.white : AppColors.neutral900,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
                if (subtitle != null && subtitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.neutral500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (actionLabel != null && section.action != null)
            GestureDetector(
              onTap: () => onAction(section.action!),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionLabel,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
