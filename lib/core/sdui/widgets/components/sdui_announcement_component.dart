import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../models/sdui_section_model.dart';
import '../../registry/sdui_action_dispatcher.dart';

class SDUIAnnouncementComponent extends StatelessWidget {
  final SDUISectionModel section;
  final SDUIActionHandler onAction;

  const SDUIAnnouncementComponent({
    super.key,
    required this.section,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = section.properties['title'] as String? ?? 'Notice';
    final message = section.properties['message'] as String? ?? '';
    final isWarning = section.properties['is_warning'] as bool? ?? false;

    final bgColor = isDark
        ? (isWarning ? const Color(0xFF2C1608) : const Color(0xFF062817))
        : (isWarning ? const Color(0xFFFFF7ED) : const Color(0xFFF0FDF4));

    final borderColor = isDark
        ? (isWarning ? const Color(0xFF7C2D12) : const Color(0xFF14532D))
        : (isWarning ? const Color(0xFFFED7AA) : const Color(0xFFBBF7D0));

    final iconColor = isWarning
        ? (isDark ? const Color(0xFFFB923C) : const Color(0xFFEA580C))
        : (isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A));

    final titleColor = isWarning
        ? (isDark ? const Color(0xFFFDBA74) : const Color(0xFF9A3412))
        : (isDark ? const Color(0xFF86EFAC) : const Color(0xFF14532D));

    final msgColor = isWarning
        ? (isDark ? const Color(0xFFFED7AA) : const Color(0xFFC2410C))
        : (isDark ? const Color(0xFFBBF7D0) : const Color(0xFF166534));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: AppColors.softShadow(isDark),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: section.action != null ? () => onAction(section.action!) : null,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                isWarning ? Icons.warning_amber_rounded : Icons.campaign_rounded,
                color: iconColor,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: titleColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (message.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        message,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: msgColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
