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

    // 1. Horizontal Category Bar
    if (categories.isNotEmpty) {
      sections.add(SDUISectionModel(
        id: 'category_bar_section',
        type: 'horizontal_category_bar',
        properties: {
          'sticky': false,
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

    // 2. Section Header for active category
    String activeTitle = 'common.menu'.tr();
    if (categories.isNotEmpty) {
      CategoryEntity? matched;
      for (final cat in categories) {
        if (cat.slug == selectedCategorySlug) {
          matched = cat;
          break;
        }
      }
      activeTitle = (matched ?? categories.first).title;
    }

    sections.add(SDUISectionModel(
      id: 'category_title_section',
      type: 'section_header',
      properties: {
        'title': activeTitle,
      },
    ));

    // 3. Delivery & Branch Status Bar
    sections.add(SDUISectionModel(
      id: 'delivery_status_section',
      type: 'delivery_status_bar',
      properties: {
        'branch_title': branchTitle ?? 'Pizza Strada',
        'address': 'Delivery',
        'eta_minutes': etaMinutes ?? 35,
      },
    ));

    // 4. Optional Discount Announcement (from server settings)
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

    // 5. Product Grid
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

    // 6. Hero Carousel Sliders
    if (sliders.isNotEmpty) {
      sections.add(SDUISectionModel(
        id: 'hero_sliders_section',
        type: 'carousel_slider',
        properties: {
          'height': 200.0,
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
}
