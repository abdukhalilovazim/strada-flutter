import 'package:easy_localization/easy_localization.dart';
import '../../../../features/home/domain/entities/home_entities.dart';
import '../models/sdui_action_model.dart';
import '../models/sdui_component_model.dart';
import '../models/sdui_page_model.dart';
import '../models/sdui_section_model.dart';

/// 🏗 SDUI Screen Builder
/// Compiles declarative JSON screen models strictly conforming to Apple 2.5.2 & Google Play.
class SDUIScreenBuilder {
  /// Optimistically filters an existing server-driven SDUI page by category,
  /// preserving the exact section order and non-product components.
  static SDUIPageModel updatePageCategory(
    SDUIPageModel page, {
    required String? selectedCategorySlug,
    required List<ProductEntity> filteredProducts,
    required List<CategoryEntity> categories,
  }) {
    String activeTitle = 'common.menu'.tr();
    if (selectedCategorySlug != null) {
      final matched = categories.where((c) => c.slug == selectedCategorySlug);
      if (matched.isNotEmpty) {
        activeTitle = matched.first.title;
      }
    }

    final updatedSections = page.sections.map((section) {
      if (section.type == 'horizontal_category_bar') {
        final newProps = Map<String, dynamic>.from(section.properties);
        newProps['default_selected'] = selectedCategorySlug ?? 'all';
        return SDUISectionModel(
          id: section.id,
          type: section.type,
          properties: newProps,
          items: section.items,
        );
      } else if (section.type == 'section_header') {
        final newProps = Map<String, dynamic>.from(section.properties);
        newProps['title'] = activeTitle;
        return SDUISectionModel(
          id: section.id,
          type: section.type,
          properties: newProps,
          items: section.items,
        );
      } else if (section.type == 'product_grid') {
        final newItems = filteredProducts.map((product) {
          return SDUIComponentModel(
            id: product.slug,
            type: 'product_card',
            properties: {
              'id': product.id,
              'slug': product.slug,
              'title': product.title,
              'description': product.description,
              'thumbnail': product.thumbnail,
              'photo': product.photo,
              'image_url': product.validImageUrl,
              'price': product.price,
              'old_price': product.oldPrice,
              'badges': product.badges
                  .map((b) => {
                        'text': b.text,
                        'type': b.type,
                        'bg_color': b.bgColor,
                        'text_color': b.textColor,
                      })
                  .toList(),
              'category': product.category != null
                  ? {'slug': product.category!.slug, 'title': product.category!.title}
                  : null,
              'variants': product.variants
                  .map((v) => {
                        'id': v.id,
                        'title': v.title,
                        'price': v.price,
                      })
                  .toList(),
            },
            action: SDUIAction(
              type: 'navigate',
              target: '/product/${product.slug}',
              payload: {
                'slug': product.slug,
                'title': product.title,
              },
            ),
          );
        }).toList();

        return SDUISectionModel(
          id: section.id,
          type: section.type,
          properties: section.properties,
          items: newItems,
        );
      }
      return section;
    }).toList();

    return SDUIPageModel(
      version: page.version,
      versionUuid: page.versionUuid,
      screenId: page.screenId,
      meta: page.meta,
      sections: updatedSections,
    );
  }

  static SDUIPageModel buildHomeScreen({
    required List<SliderEntity> sliders,
    required List<CategoryEntity> categories,
    required List<ProductEntity> products,
    SettingsEntity? settings,
    String? selectedCategorySlug,
    String? branchTitle,
    int? etaMinutes,
  }) {
    final sections = <SDUISectionModel>[];

    // 1. 🌟 Hero Carousel Sliders (Banners) - Top of screen right under search bar
    if (sliders.isNotEmpty) {
      sections.add(SDUISectionModel(
        id: 'hero_sliders_section',
        type: 'carousel_slider',
        properties: {
          'height': 190.0,
          'viewport_fraction': 0.92,
          'auto_play': true,
        },
        items: sliders.map((slider) {
          SDUIAction? action;
          if (slider.link != null && slider.link!.isNotEmpty) {
            action = SDUIAction(type: 'open_url', target: slider.link);
          }

          return SDUIComponentModel(
            id: slider.id.toString(),
            type: 'banner_card',
            properties: {
              'image_url': slider.imageUrl,
              'caption': slider.title,
            },
            action: action,
          );
        }).toList(),
      ));
    }

    // 2. 🌟 Horizontal Category Bar (Menu) - Pinned / Sticky under the app bar on scroll
    if (categories.isNotEmpty) {
      sections.add(SDUISectionModel(
        id: 'category_bar_section',
        type: 'horizontal_category_bar',
        properties: {
          'sticky': true,
          'default_selected': selectedCategorySlug ?? categories.first.slug,
        },
        items: categories.map((cat) {
          return SDUIComponentModel(
            id: cat.slug,
            type: 'category_chip',
            properties: {
              'slug': cat.slug,
              'title': cat.title,
            },
            action: SDUIAction(
              type: 'filter_category',
              target: cat.slug,
              payload: {'slug': cat.slug},
            ),
          );
        }).toList(),
      ));
    }

    // 3. Optional Discount Announcement (from server settings)
    if (settings != null && settings.discount > 0) {
      sections.add(SDUISectionModel(
        id: 'promo_announcement',
        type: 'announcement_banner',
        properties: {
          'title': 'Maxsus Chegirma: ${settings.discount}%',
          'message': 'Barcha tanlangan mahsulotlarga amal qiladi',
          'is_warning': false,
          'icon': 'campaign',
        },
      ));
    }

    // 4. 🍕 Product Grid
    sections.add(SDUISectionModel(
      id: 'products_grid_section',
      type: 'product_grid',
      properties: {
        'columns': 2,
        'child_aspect_ratio': 0.68,
        'spacing': 16.0,
        'bottom_padding': 100.0,
      },
      items: products.map((product) {
        return SDUIComponentModel(
          id: product.slug,
          type: 'product_card',
          properties: {
            'id': product.id,
            'slug': product.slug,
            'title': product.title,
            'description': product.description,
            'thumbnail': product.thumbnail,
            'photo': product.photo,
            'image_url': product.validImageUrl,
            'price': product.price,
            'category': product.category != null
                ? {'slug': product.category!.slug, 'title': product.category!.title}
                : null,
            'variants': product.variants
                .map((v) => {
                      'id': v.id,
                      'title': v.title,
                      'price': v.price,
                    })
                .toList(),
          },
          action: SDUIAction(
            type: 'navigate',
            target: '/product/${product.slug}',
            payload: {
              'slug': product.slug,
              'title': product.title,
            },
          ),
        );
      }).toList(),
    ));

    return SDUIPageModel(
      version: '1.2.0',
      versionUuid: 'local_fallback_uuid',
      screenId: 'home',
      meta: {
        'title': 'Pizza Strada',
        'branch_title': branchTitle ?? 'Pizza Strada',
        'cache_ttl_seconds': 300,
        'location_resolved': true,
      },
      sections: sections,
    );
  }

  /// 🛒 Default fallback Cart SDUI Screen
  static SDUIPageModel buildCartScreen() {
    return const SDUIPageModel(
      version: '1.2.0',
      versionUuid: 'cart_default_v1',
      screenId: 'cart',
      meta: {
        'title': 'Savat',
        'cache_ttl_seconds': 300,
      },
      sections: [
        SDUISectionModel(
          id: 'cart_delivery_info_section',
          type: 'cart_delivery_info_card',
          properties: {'title': 'Yetkazib berish', 'show_eta': true, 'eta_minutes': 35},
        ),
        SDUISectionModel(
          id: 'cart_items_list_section',
          type: 'cart_item_list',
          properties: {'show_photos': true, 'allow_stepper': true, 'allow_delete': true},
        ),
        SDUISectionModel(
          id: 'empty_cart_section',
          type: 'empty_cart_card',
          properties: {
            'title': 'Savatingiz bo\'sh',
            'subtitle': 'Menyudan o\'zingizga yoqqan pitsa va ichimliklarni tanlang',
            'button_text': 'Menyuga o\'tish',
          },
        ),
        SDUISectionModel(
          id: 'upsell_recommendation_section',
          type: 'upsell_recommendation_slider',
          properties: {'title': 'Buyurtmaga qo\'shasizmi?'},
        ),
        SDUISectionModel(
          id: 'promo_code_section',
          type: 'promo_code_card',
          properties: {
            'title': 'Promokod',
            'placeholder': 'Promokodni kiriting',
            'button_text': 'Qo\'llash',
          },
        ),
        SDUISectionModel(
          id: 'cart_summary_section',
          type: 'cart_summary_card',
          properties: {'title': 'Buyurtma summasi'},
        ),
        SDUISectionModel(
          id: 'cart_checkout_button_section',
          type: 'cart_checkout_button',
          properties: {'button_text': 'Rasmiylashtirishga o\'tish', 'sticky': true},
        ),
      ],
    );
  }

  /// 💳 Default fallback Checkout SDUI Screen
  static SDUIPageModel buildCheckoutScreen() {
    return const SDUIPageModel(
      version: '1.2.0',
      versionUuid: 'checkout_default_v1',
      screenId: 'checkout',
      meta: {
        'title': 'Buyurtma rasmiylashtirish',
        'cache_ttl_seconds': 300,
      },
      sections: [
        SDUISectionModel(
          id: 'order_type_selector_section',
          type: 'order_type_selector_card',
          properties: {'delivery_title': 'Yetkazib berish', 'pickup_title': 'Olib ketish'},
        ),
        SDUISectionModel(
          id: 'address_selector_section',
          type: 'address_selector_card',
          properties: {'title': 'Yetkazib berish manzili', 'map_button_text': 'Xaritadan tanlash'},
        ),
        SDUISectionModel(
          id: 'pickup_branch_section',
          type: 'pickup_branch_card',
          properties: {'title': 'Filialni tanlang'},
        ),
        SDUISectionModel(
          id: 'delivery_time_slot_section',
          type: 'delivery_time_slot_card',
          properties: {'title': 'Yetkazish vaqti', 'asap_text': 'Iloji boricha tezroq (~35 daqiqa)'},
        ),
        SDUISectionModel(
          id: 'customer_info_section',
          type: 'customer_info_card',
          properties: {'title': 'Qabul qiluvchi ma\'lumotlari'},
        ),
        SDUISectionModel(
          id: 'payment_method_selector_section',
          type: 'payment_method_selector_card',
          properties: {'title': 'To\'lov usuli'},
        ),
        SDUISectionModel(
          id: 'courier_notes_section',
          type: 'courier_notes_card',
          properties: {'title': 'Kuryer uchun izoh', 'utensils_label': 'Qoshiq va salfetka kerak emas'},
        ),
        SDUISectionModel(
          id: 'checkout_summary_section',
          type: 'checkout_summary_card',
          properties: {'title': 'Yakuniy to\'lov'},
        ),
        SDUISectionModel(
          id: 'submit_order_cta_section',
          type: 'submit_order_cta_card',
          properties: {'button_text': 'Buyurtmani tasdiqlash'},
        ),
      ],
    );
  }

  /// 👤 Default fallback Profile SDUI Screen
  static SDUIPageModel buildProfileScreen() {
    return const SDUIPageModel(
      version: '1.2.0',
      versionUuid: 'profile_default_v1',
      screenId: 'profile',
      meta: {
        'title': 'Profil',
        'cache_ttl_seconds': 300,
      },
      sections: [
        SDUISectionModel(
          id: 'profile_header_section',
          type: 'profile_header_card',
          properties: {'show_avatar': true, 'show_phone': true},
        ),
        SDUISectionModel(
          id: 'profile_menu_group_section',
          type: 'profile_menu_group',
          properties: {'title': 'Asosiy'},
        ),
        SDUISectionModel(
          id: 'app_settings_section',
          type: 'app_settings_card',
          properties: {'title': 'Ilova sozlamalari'},
        ),
        SDUISectionModel(
          id: 'support_contacts_section',
          type: 'support_contacts_card',
          properties: {'title': 'Qo\'llab-quvvatlash va aloqa'},
        ),
        SDUISectionModel(
          id: 'logout_delete_section',
          type: 'logout_delete_card',
          properties: {'logout_text': 'Hisobdan chiqish'},
        ),
        SDUISectionModel(
          id: 'app_version_section',
          type: 'app_version_card',
          properties: {},
        ),
      ],
    );
  }

  /// 🎁 Default fallback Promotions SDUI Screen with Coupons and Special Offers
  static SDUIPageModel buildPromotionsScreen({
    List<SliderEntity> sliders = const [],
    List<ProductEntity> products = const [],
  }) {
    return SDUIPageModel(
      version: '1.2.0',
      versionUuid: 'promotions_default_v1',
      screenId: 'promotions',
      meta: const {
        'title': 'Aksiyalar & Kuponlar',
        'cache_ttl_seconds': 300,
      },
      sections: [
        const SDUISectionModel(
          id: 'promos_announcement',
          type: 'announcement_banner',
          properties: {
            'title': 'Maxsus Takliflar va Aksiya',
            'message': 'Strada pitsalaridan eng lazzatli kombolar va chegirmalar',
            'is_warning': false,
            'icon': 'local_offer',
          },
        ),
        if (sliders.isNotEmpty)
          SDUISectionModel(
            id: 'promos_carousel',
            type: 'carousel_slider',
            properties: {
              'height': 190.0,
              'viewport_fraction': 0.92,
              'auto_play': true,
            },
            items: sliders.map((slider) {
              return SDUIComponentModel(
                id: slider.id.toString(),
                type: 'banner_card',
                properties: {
                  'image_url': slider.imageUrl,
                  'caption': slider.title,
                },
              );
            }).toList(),
          ),
        const SDUISectionModel(
          id: 'promos_coupons_grid',
          type: 'coupon_grid',
          properties: {
            'title': 'Mavjud kuponlar va to\'plamlar',
          },
          items: [
            SDUIComponentModel(
              id: 'coupon_strada1',
              type: 'coupon_card',
              properties: {
                'id': 1,
                'code': 'STRADA20',
                'title': 'Pitsa + Ichimlik kombo',
                'description': 'Istalgan o\'rtacha pitsa va 0.5L ichimlikka 20% maxsus chegirma',
                'price': 65000.0,
                'old_price': 85000.0,
                'badges': [
                  {'text': '-20 000 so\'m'},
                ],
              },
              action: SDUIAction(
                type: 'apply_coupon',
                target: 'STRADA20',
                payload: {'code': 'STRADA20'},
              ),
            ),
            SDUIComponentModel(
              id: 'coupon_strada2',
              type: 'coupon_card',
              properties: {
                'id': 2,
                'code': 'COMBO3',
                'title': 'Katta Do\'stlar To\'plami (3 ta pitsa)',
                'description': '3 ta katta pitsa buyurtma bering va uchinchi pitsani 50% chegirma bilan oling',
                'price': 169000.0,
                'old_price': 225000.0,
                'badges': [
                  {'text': '-56 000 so\'m'},
                ],
              },
              action: SDUIAction(
                type: 'apply_coupon',
                target: 'COMBO3',
                payload: {'code': 'COMBO3'},
              ),
            ),
          ],
        ),
        if (products.isNotEmpty)
          SDUISectionModel(
            id: 'promos_products_grid',
            type: 'product_grid',
            properties: {
              'columns': 2,
              'child_aspect_ratio': 0.68,
              'spacing': 16.0,
              'bottom_padding': 100.0,
            },
            items: products.map((product) {
              return SDUIComponentModel(
                id: product.slug,
                type: 'product_card',
                properties: {
                  'id': product.id,
                  'slug': product.slug,
                  'title': product.title,
                  'description': product.description,
                  'thumbnail': product.thumbnail,
                  'photo': product.photo,
                  'image_url': product.validImageUrl,
                  'price': product.price,
                  'old_price': product.oldPrice,
                  'category': product.category != null
                      ? {'slug': product.category!.slug, 'title': product.category!.title}
                      : null,
                  'variants': product.variants
                      .map((v) => {
                            'id': v.id,
                            'title': v.title,
                            'price': v.price,
                          })
                      .toList(),
                },
                action: SDUIAction(
                  type: 'navigate',
                  target: '/product/${product.slug}',
                  payload: {
                    'slug': product.slug,
                    'title': product.title,
                    'description': product.description,
                  },
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}
