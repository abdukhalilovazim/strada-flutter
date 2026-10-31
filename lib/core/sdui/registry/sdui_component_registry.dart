import 'package:flutter/material.dart';
import '../models/sdui_section_model.dart';
import '../registry/sdui_action_dispatcher.dart';
import '../registry/sdui_error_boundary.dart';
import '../widgets/components/sdui_announcement_component.dart';
import '../widgets/components/sdui_category_bar_component.dart';
import '../widgets/components/sdui_delivery_bar_component.dart';
import '../widgets/components/sdui_product_grid_component.dart';
import '../widgets/components/sdui_section_header_component.dart';
import '../widgets/components/sdui_slider_component.dart';

typedef SDUISliverBuilder = Widget Function(
  BuildContext context,
  SDUISectionModel section,
  SDUIActionHandler onAction,
  String? selectedCategorySlug,
);

/// 🏛 Central Pre-Compiled SDUI Component Registry
/// Maps declarative JSON component types strictly to pre-compiled Flutter widgets.
/// Complies with Apple Guideline 2.5.2 & Google Play by prohibiting dynamic code compilation.
class SDUIComponentRegistry {
  static final SDUIComponentRegistry _instance = SDUIComponentRegistry._internal();
  factory SDUIComponentRegistry() => _instance;
  SDUIComponentRegistry._internal() {
    _registerDefaultComponents();
  }

  final Map<String, SDUISliverBuilder> _sliverBuilders = {};

  void registerSliver(String type, SDUISliverBuilder builder) {
    _sliverBuilders[type] = builder;
  }

  void _registerDefaultComponents() {
    // 1. Hero Carousel Slider
    registerSliver('carousel_slider', (context, section, onAction, _) {
      return SliverToBoxAdapter(
        child: SDUISafeErrorBoundary(
          type: 'carousel_slider',
          child: SDUISliderComponent(section: section, onAction: onAction),
        ),
      );
    });

    // 2. Horizontal Category Bar
    registerSliver('horizontal_category_bar', (context, section, onAction, selectedCategorySlug) {
      if (section.items.isEmpty) {
        return const SliverToBoxAdapter(child: SizedBox.shrink());
      }
      final categoryWidget = SDUICategoryBarComponent(
        section: section,
        onAction: onAction,
        selectedSlug: selectedCategorySlug,
      );

      return SliverToBoxAdapter(
        child: SDUISafeErrorBoundary(
          type: 'horizontal_category_bar',
          child: categoryWidget,
        ),
      );
    });

    // 3. Section Header
    registerSliver('section_header', (context, section, onAction, _) {
      return SliverToBoxAdapter(
        child: SDUISafeErrorBoundary(
          type: 'section_header',
          child: SDUISectionHeaderComponent(section: section, onAction: onAction),
        ),
      );
    });

    // 4. Product Grid
    registerSliver('product_grid', (context, section, onAction, _) {
      return SDUIProductGridComponent(section: section, onAction: onAction);
    });

    // 5. Announcement Banner
    registerSliver('announcement_banner', (context, section, onAction, _) {
      return SliverToBoxAdapter(
        child: SDUISafeErrorBoundary(
          type: 'announcement_banner',
          child: SDUIAnnouncementComponent(section: section, onAction: onAction),
        ),
      );
    });

    // 6. Delivery Status Bar
    registerSliver('delivery_status_bar', (context, section, onAction, _) {
      return SliverToBoxAdapter(
        child: SDUISafeErrorBoundary(
          type: 'delivery_status_bar',
          child: SDUIDeliveryBarComponent(section: section, onAction: onAction),
        ),
      );
    });

    // 7. Spacer
    registerSliver('spacer_block', (context, section, _, __) {
      final height = (section.properties['height'] as num?)?.toDouble() ?? 16.0;
      return SliverToBoxAdapter(child: SizedBox(height: height));
    });
  }

  /// Builds a sliver widget for the given section model.
  /// Falls back cleanly via SDUIUnknownComponentFallback if type is unrecognized.
  Widget buildSliver(
    BuildContext context,
    SDUISectionModel section,
    SDUIActionHandler onAction,
    String? selectedCategorySlug,
  ) {
    final builder = _sliverBuilders[section.type];
    if (builder == null) {
      return SliverToBoxAdapter(
        child: SDUIUnknownComponentFallback(type: section.type),
      );
    }
    return builder(context, section, onAction, selectedCategorySlug);
  }
}
