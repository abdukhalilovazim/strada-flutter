import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../models/sdui_section_model.dart';
import '../../registry/sdui_action_dispatcher.dart';

class SDUISliderComponent extends StatefulWidget {
  final SDUISectionModel section;
  final SDUIActionHandler onAction;

  const SDUISliderComponent({
    super.key,
    required this.section,
    required this.onAction,
  });

  @override
  State<SDUISliderComponent> createState() => _SDUISliderComponentState();
}

class _SDUISliderComponentState extends State<SDUISliderComponent> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final viewportFraction = (widget.section.properties['viewport_fraction'] as num?)?.toDouble() ?? 0.92;
    _pageController = PageController(viewportFraction: viewportFraction);

    final autoPlay = widget.section.properties['auto_play'] as bool? ?? true;
    if (autoPlay && widget.section.items.length > 1) {
      _timer = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted || !_pageController.hasClients) return;
        final next = (_currentPage + 1) % widget.section.items.length;
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
        );
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.section.items.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final height = (widget.section.properties['height'] as num?)?.toDouble() ?? 185.0;

    return RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            SizedBox(
              height: height,
              child: PageView.builder(
                itemCount: widget.section.items.length,
                controller: _pageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (ctx, i) {
                  final item = widget.section.items[i];
                  final imageUrl = item.properties['image_url'] as String? ?? item.properties['image'] as String? ?? '';
                  final caption = item.properties['caption'] as String? ?? item.properties['title'] as String?;

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: AppColors.softShadow(isDark),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (imageUrl.isNotEmpty)
                            CachedNetworkImage(
                              imageUrl: imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: isDark ? AppColors.neutral800 : AppColors.neutral100,
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: isDark ? AppColors.neutral800 : AppColors.neutral100,
                                child: const Icon(Icons.image_not_supported_outlined),
                              ),
                            )
                          else
                            Container(
                              color: isDark ? AppColors.neutral800 : AppColors.neutral100,
                            ),

                          // Gradient Overlay for readability
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.65),
                                ],
                              ),
                            ),
                          ),

                          // Caption text
                          if (caption != null && caption.isNotEmpty)
                            Positioned(
                              left: 20,
                              bottom: 18,
                              right: 20,
                              child: Text(
                                caption,
                                style: AppTextStyles.h3.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),

                          // Action click
                          if (item.action != null)
                            Positioned.fill(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => widget.onAction(item.action!),
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

            // Indicator Dots
            if (widget.section.items.length > 1) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.section.items.length, (idx) {
                  final isCurrent = _currentPage == idx;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isCurrent ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? AppColors.primary
                          : (isDark ? AppColors.neutral700 : AppColors.neutral300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  );
                }),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
