import 'package:flutter/material.dart';
import '../models/sdui_section_model.dart';
import '../registry/sdui_action_dispatcher.dart';
import '../registry/sdui_error_boundary.dart';
import '../widgets/components/sdui_announcement_component.dart';
import '../widgets/components/sdui_cart_components.dart';
import '../widgets/components/sdui_category_bar_component.dart';
import '../widgets/components/sdui_checkout_components.dart';
import '../widgets/components/sdui_delivery_bar_component.dart';
import '../widgets/components/sdui_product_grid_component.dart';
import '../widgets/components/sdui_profile_components.dart';
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
    // =========================================================================
    // 🏠 HOME COMPONENTS
    // =========================================================================

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

    // =========================================================================
    // 🛒 CART COMPONENTS
    // =========================================================================

    registerSliver('cart_delivery_info_card', (context, section, onAction, _) {
      return SliverToBoxAdapter(
        child: SDUISafeErrorBoundary(
          type: 'cart_delivery_info_card',
          child: SDUICartDeliveryInfoComponent(section: section, onAction: onAction),
        ),
      );
    });

    registerSliver('cart_item_list', (context, section, onAction, _) {
      return SliverToBoxAdapter(
        child: SDUISafeErrorBoundary(
          type: 'cart_item_list',
          child: SDUICartItemListComponent(section: section, onAction: onAction),
        ),
      );
    });

    registerSliver('empty_cart_card', (context, section, onAction, _) {
      return SliverToBoxAdapter(
        child: SDUISafeErrorBoundary(
          type: 'empty_cart_card',
          child: SDUIEmptyCartComponent(section: section, onAction: onAction),
        ),
      );
    });

    registerSliver('upsell_recommendation_slider', (context, section, onAction, _) {
      return SliverToBoxAdapter(
        child: SDUISafeErrorBoundary(
          type: 'upsell_recommendation_slider',
          child: SDUIUpsellSliderComponent(section: section, onAction: onAction),
        ),
      );
    });

    registerSliver('promo_code_card', (context, section, onAction, _) {
      return SliverToBoxAdapter(
        child: SDUISafeErrorBoundary(
          type: 'promo_code_card',
          child: SDUIPromoCodeComponent(section: section, onAction: onAction),
        ),
      );
    });

    registerSliver('cart_summary_card', (context, section, onAction, _) {
      return SliverToBoxAdapter(
        child: SDUISafeErrorBoundary(
          type: 'cart_summary_card',
          child: SDUICartSummaryComponent(section: section, onAction: onAction),
        ),
      );
    });

    registerSliver('cart_checkout_button', (context, section, onAction, _) {
      return SliverToBoxAdapter(
        child: SDUISafeErrorBoundary(
          type: 'cart_checkout_button',
          child: SDUICartCheckoutButtonComponent(section: section, onAction: onAction),
        ),
      );
    });

    // =========================================================================
    // 💳 CHECKOUT COMPONENTS
    // =========================================================================

    registerSliver('order_type_selector_card', (context, section, onAction, _) {
      return SliverToBoxAdapter(
        child: SDUISafeErrorBoundary(
          type: 'order_type_selector_card',
          child: SDUIOrderTypeComponent(section: section, onAction: onAction),
        ),
      );
    });

    registerSliver('address_selector_card', (context, section, onAction, _) {
      return SliverToBoxAdapter(
        child: SDUISafeErrorBoundary(
          type: 'address_selector_card',
          child: SDUIAddressSelectorComponent(section: section, onAction: onAction),
        ),
      );
    });

    registerSliver('pickup_branch_card', (context, section, onAction, _) {
      return SliverToBoxAdapter(
        child: SDUISafeErrorBoundary(
          type: 'pickup_branch_card',
          child: SDUIPickupBranchComponent(section: section, onAction: onAction),
        ),
      );
    });

    registerSliver('delivery_time_slot_card', (context, section, onAction, _) {
      return SliverToBoxAdapter(
        child: SDUISafeErrorBoundary(
          type: 'delivery_time_slot_card',
          child: SDUIDeliveryTimeSlotComponent(section: section, onAction: onAction),
        ),
      );
    });

    registerSliver('customer_info_card', (context, section, onAction, _) {
      return SliverToBoxAdapter(
        child: SDUISafeErrorBoundary(
          type: 'customer_info_card',
          child: SDUICustomerInfoComponent(section: section, onAction: onAction),
        ),
      );
    });

    registerSliver('payment_method_selector_card', (context, section, onAction, _) {
      return SliverToBoxAdapter(
        child: SDUISafeErrorBoundary(
          type: 'payment_method_selector_card',
          child: SDUIPaymentMethodComponent(section: section, onAction: onAction),
        ),
      );
    });

    registerSliver('courier_notes_card', (context, section, onAction, _) {
      return SliverToBoxAdapter(
        child: SDUISafeErrorBoundary(
          type: 'courier_notes_card',
          child: SDUICourierNotesComponent(section: section, onAction: onAction),
        ),
      );
    });

    registerSliver('checkout_summary_card', (context, section, onAction, _) {
      return SliverToBoxAdapter(
        child: SDUISafeErrorBoundary(
          type: 'checkout_summary_card',
          child: SDUICheckoutSummaryComponent(section: section, onAction: onAction),
        ),
      );
    });

    registerSliver('submit_order_cta_card', (context, section, onAction, _) {
      return SliverToBoxAdapter(
        child: SDUISafeErrorBoundary(
          type: 'submit_order_cta_card',
          child: SDUISubmitOrderCtaComponent(section: section, onAction: onAction),
        ),
      );
    });

    // =========================================================================
    // 👤 PROFILE COMPONENTS
    // =========================================================================

    registerSliver('profile_header_card', (context, section, onAction, _) {
      return SliverToBoxAdapter(
        child: SDUISafeErrorBoundary(
          type: 'profile_header_card',
          child: SDUIProfileHeaderComponent(section: section, onAction: onAction),
        ),
      );
    });

    registerSliver('loyalty_card', (context, section, onAction, _) {
      return SliverToBoxAdapter(
        child: SDUISafeErrorBoundary(
          type: 'loyalty_card',
          child: SDUILoyaltyComponent(section: section, onAction: onAction),
        ),
      );
    });

    registerSliver('profile_menu_group', (context, section, onAction, _) {
      return SliverToBoxAdapter(
        child: SDUISafeErrorBoundary(
          type: 'profile_menu_group',
          child: SDUIProfileMenuGroupComponent(section: section, onAction: onAction),
        ),
      );
    });

    registerSliver('app_settings_card', (context, section, onAction, _) {
      return SliverToBoxAdapter(
        child: SDUISafeErrorBoundary(
          type: 'app_settings_card',
          child: SDUIAppSettingsComponent(section: section, onAction: onAction),
        ),
      );
    });

    registerSliver('support_contacts_card', (context, section, onAction, _) {
      return SliverToBoxAdapter(
        child: SDUISafeErrorBoundary(
          type: 'support_contacts_card',
          child: SDUISupportContactsComponent(section: section, onAction: onAction),
        ),
      );
    });

    registerSliver('logout_delete_card', (context, section, onAction, _) {
      return SliverToBoxAdapter(
        child: SDUISafeErrorBoundary(
          type: 'logout_delete_card',
          child: SDUILogoutDeleteComponent(section: section, onAction: onAction),
        ),
      );
    });

    registerSliver('app_version_card', (context, section, onAction, _) {
      return SliverToBoxAdapter(
        child: SDUISafeErrorBoundary(
          type: 'app_version_card',
          child: SDUIAppVersionComponent(section: section, onAction: onAction),
        ),
      );
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
