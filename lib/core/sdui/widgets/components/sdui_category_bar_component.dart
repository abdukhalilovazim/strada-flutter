import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../models/sdui_action_model.dart';
import '../../models/sdui_section_model.dart';
import '../../registry/sdui_action_dispatcher.dart';

/// 🏷 Modern Category Scrollable Pill Bar
/// Supports smooth horizontal scrolling, high-contrast active tabs,
/// and instant tactile feedback.
class SDUICategoryBarComponent extends StatelessWidget {
  final SDUISectionModel section;
  final SDUIActionHandler onAction;
  final String? selectedSlug;

  const SDUICategoryBarComponent({
    super.key,
    required this.section,
    required this.onAction,
    this.selectedSlug,
  });

  @override
  Widget build(BuildContext context) {
    if (section.items.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeSlug = selectedSlug ?? section.properties['default_selected'] as String?;

    return Container(
      color: isDark ? AppColors.darkSurface : Colors.white,
      height: 52,
      alignment: Alignment.centerLeft,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: section.items.length,
        itemBuilder: (ctx, i) {
          final item = section.items[i];
          final slug = item.properties['slug'] as String? ?? item.id;
          final title = item.properties['title'] as String? ?? slug;
          final isSelected = activeSlug == slug;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (item.action != null) {
                    onAction(item.action!);
                  } else {
                    onAction(SDUIAction(type: 'filter_category', target: slug));
                  }
                },
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? AppColors.neutral800 : AppColors.neutral100),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? AppColors.darkBorder : AppColors.neutral200.withValues(alpha: 0.6)),
                      width: 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.28),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      title,
                      style: AppTextStyles.labelSmall.copyWith(
                        fontSize: 13,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white : AppColors.neutral800),
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
