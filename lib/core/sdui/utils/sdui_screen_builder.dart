import '../../../../features/home/domain/entities/home_entities.dart';
import '../models/sdui_action_model.dart';
import '../models/sdui_component_model.dart';
import '../models/sdui_page_model.dart';
import '../models/sdui_section_model.dart';

/// 🏗 SDUI Screen Builder
/// Compiles declarative JSON screen models strictly conforming to Apple 2.5.2 & Google Play.
class SDUIScreenBuilder {
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

    // 1. Delivery & Branch Status Bar
    sections.add(SDUISectionModel(
      id: 'delivery_status_section',
      type: 'delivery_status_bar',
      properties: {
        'branch_title': branchTitle ?? 'Pizza Strada',
        'address': 'Delivery',
        'eta_minutes': etaMinutes ?? 35,
      },
    ));

    // 2. Hero Carousel Sliders
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

    // 4. Sticky Category Bar
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

    // 5. Section Header for active category
    String activeTitle = 'Menyu';
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

    // 6. Product Grid
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
            'slug': product.slug,
            'title': product.title,
            'description': product.description,
            'thumbnail': product.thumbnail,
            'photo': product.photo,
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
      screenId: 'home_feed',
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
