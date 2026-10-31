import 'package:flutter/material.dart';
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
    final title = section.properties['title'] as String? ?? 'Notice';
    final message = section.properties['message'] as String? ?? '';
    final isWarning = section.properties['is_warning'] as bool? ?? false;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isWarning ? const Color(0xFFFFF7ED) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isWarning ? const Color(0xFFFDBA74) : const Color(0xFF86EFAC),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: section.action != null ? () => onAction(section.action!) : null,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              isWarning ? Icons.warning_amber_rounded : Icons.campaign_rounded,
              color: isWarning ? const Color(0xFFC2410C) : const Color(0xFF15803D),
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
                      color: isWarning ? const Color(0xFF9A3412) : const Color(0xFF166534),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (message.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isWarning ? const Color(0xFFC2410C) : const Color(0xFF15803D),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (section.action != null)
              Icon(
                Icons.chevron_right_rounded,
                color: isWarning ? const Color(0xFFC2410C) : const Color(0xFF15803D),
              ),
          ],
        ),
      ),
    );
  }
}
