import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../models/sdui_section_model.dart';
import '../../registry/sdui_action_dispatcher.dart';

class SDUISliderComponent extends StatelessWidget {
  final SDUISectionModel section;
  final SDUIActionHandler onAction;

  const SDUISliderComponent({
    super.key,
    required this.section,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    if (section.items.isEmpty) return const SizedBox.shrink();

    final height = (section.properties['height'] as num?)?.toDouble() ?? 200.0;
    final viewportFraction = (section.properties['viewport_fraction'] as num?)?.toDouble() ?? 0.92;

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: SizedBox(
          height: height,
          child: PageView.builder(
            itemCount: section.items.length,
            controller: PageController(viewportFraction: viewportFraction),
            itemBuilder: (ctx, i) {
              final item = section.items[i];
              final imageUrl = item.properties['image_url'] as String? ?? item.properties['image'] as String? ?? '';
              final caption = item.properties['caption'] as String? ?? item.properties['title'] as String?;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (imageUrl.isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(color: AppColors.neutral100),
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.neutral100,
                            child: const Icon(Icons.image_not_supported_outlined),
                          ),
                        )
                      else
                        Container(color: AppColors.neutral100),

                      // Gradient overlay for legibility
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.6),
                            ],
                          ),
                        ),
                      ),

                      if (caption != null && caption.isNotEmpty)
                        Positioned(
                          left: 20,
                          bottom: 20,
                          right: 20,
                          child: Text(
                            caption,
                            style: AppTextStyles.h3.copyWith(color: Colors.white),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                      if (item.action != null)
                        Positioned.fill(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => onAction(item.action!),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
