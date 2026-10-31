import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../models/sdui_action_model.dart';
import '../../models/sdui_section_model.dart';
import '../../registry/sdui_action_dispatcher.dart';

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

    final activeSlug = selectedSlug ?? section.properties['default_selected'] as String?;

    return Container(
      color: Colors.white,
      height: 54,
      alignment: Alignment.centerLeft,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        itemCount: section.items.length,
        itemBuilder: (ctx, i) {
          final item = section.items[i];
          final slug = item.properties['slug'] as String? ?? item.id;
          final title = item.properties['title'] as String? ?? slug;
          final isSelected = activeSlug == slug;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(title),
              selected: isSelected,
              onSelected: (_) {
                if (item.action != null) {
                  onAction(item.action!);
                } else {
                  onAction(SDUIAction(type: 'filter_category', target: slug));
                }
              },
              selectedColor: AppColors.primary,
              backgroundColor: Colors.white,
              disabledColor: Colors.white,
              showCheckmark: false,
              side: BorderSide(
                color: isSelected ? AppColors.primary : AppColors.neutral200,
                width: 1,
              ),
              labelStyle: AppTextStyles.labelSmall.copyWith(
                color: isSelected ? Colors.white : AppColors.neutral700,
                fontWeight: FontWeight.w600,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        },
      ),
    );
  }
}
