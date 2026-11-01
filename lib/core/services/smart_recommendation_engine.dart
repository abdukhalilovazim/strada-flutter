import 'package:pizza_strada/features/cart/domain/entities/cart_item_entity.dart';
import 'package:pizza_strada/features/home/domain/entities/home_entities.dart';

/// 🎯 Model representing an individual cross-sell recommendation rule.
class RecommendationRuleEntity {
  final int id;
  final String name;
  final String titleUz;
  final String titleRu;
  final String? titleEn;
  final List<int> triggerCategoryIds;
  final List<String> triggerCategorySlugs;
  final List<int> excludeCategoryIds;
  final List<String> excludeCategorySlugs;
  final List<int> targetCategoryIds;
  final List<String> targetCategorySlugs;
  final int priority;

  const RecommendationRuleEntity({
    required this.id,
    required this.name,
    required this.titleUz,
    required this.titleRu,
    this.titleEn,
    this.triggerCategoryIds = const [],
    this.triggerCategorySlugs = const [],
    this.excludeCategoryIds = const [],
    this.excludeCategorySlugs = const [],
    this.targetCategoryIds = const [],
    this.targetCategorySlugs = const [],
    this.priority = 10,
  });

  String getTitle(String localeCode) {
    switch (localeCode) {
      case 'ru':
        return titleRu;
      case 'en':
        return titleEn ?? titleUz;
      default:
        return titleUz;
    }
  }

  factory RecommendationRuleEntity.fromJson(Map<String, dynamic> json) {
    return RecommendationRuleEntity(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      titleUz: json['title_uz']?.toString() ?? '',
      titleRu: json['title_ru']?.toString() ?? '',
      titleEn: json['title_en']?.toString(),
      triggerCategoryIds: (json['trigger_category_ids'] as List?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      triggerCategorySlugs: (json['trigger_category_slugs'] as List?)
              ?.map((e) => e.toString().toLowerCase())
              .toList() ??
          const [],
      excludeCategoryIds: (json['exclude_category_ids'] as List?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      excludeCategorySlugs: (json['exclude_category_slugs'] as List?)
              ?.map((e) => e.toString().toLowerCase())
              .toList() ??
          const [],
      targetCategoryIds: (json['target_category_ids'] as List?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      targetCategorySlugs: (json['target_category_slugs'] as List?)
              ?.map((e) => e.toString().toLowerCase())
              .toList() ??
          const [],
      priority: (json['priority'] as num?)?.toInt() ?? 10,
    );
  }
}

/// 📦 Result of smart recommendation engine evaluation.
class RecommendationMatch {
  final String title;
  final List<ProductEntity> products;

  const RecommendationMatch({
    required this.title,
    required this.products,
  });

  bool get isEmpty => products.isEmpty;
  bool get isNotEmpty => products.isNotEmpty;
}

/// 🧠 Smart Recommendation & Cross-Sell Engine
/// Evaluates context-aware rules in real-time (0ms latency).
/// e.g. If cart contains Pizza -> Recommend Sauce ONLY if sauce is not yet in cart!
/// Once sauce is added, immediately pivots to Drinks or Desserts!
class SmartRecommendationEngine {
  /// Built-in production rules fallback
  static final List<RecommendationRuleEntity> defaultRules = [
    // 1. Pizza in cart & No sauce in cart -> Recommend Sauces
    const RecommendationRuleEntity(
      id: 1,
      name: 'Pizza -> Sauces',
      titleUz: 'Pitsa uchun sous tanlang 🥫',
      titleRu: 'Выберите соус к пицце 🥫',
      titleEn: 'Choose a sauce for your pizza 🥫',
      triggerCategoryIds: [1, 27],
      triggerCategorySlugs: ['pizza', 'pitsa', 'gigant-pizza', 'giant-pizza'],
      excludeCategoryIds: [11],
      excludeCategorySlugs: ['souslar', 'sauces', 'sous'],
      targetCategoryIds: [11],
      targetCategorySlugs: ['souslar', 'sauces', 'sous'],
      priority: 100,
    ),

    // 2. Burger in cart & No drink in cart -> Recommend Drinks
    const RecommendationRuleEntity(
      id: 2,
      name: 'Burger -> Drinks',
      titleUz: 'Burger bilan yaxna ichimlik 🥤',
      titleRu: 'Прохладный напиток к бургеру 🥤',
      titleEn: 'Cool drink with your burger 🥤',
      triggerCategoryIds: [2],
      triggerCategorySlugs: ['burger', 'burgerlar', 'fast-food', 'sendvich'],
      excludeCategoryIds: [5],
      excludeCategorySlugs: ['drinks', 'ichimliklar'],
      targetCategoryIds: [5],
      targetCategorySlugs: ['drinks', 'ichimliklar'],
      priority: 90,
    ),

    // 3. Pizza in cart + Sauce already in cart & No drink in cart -> Recommend Drinks
    const RecommendationRuleEntity(
      id: 3,
      name: 'Pizza + Sauce -> Drinks',
      titleUz: 'Muzdek ichimliklar 🥤',
      titleRu: 'Освежающие напитки 🥤',
      titleEn: 'Refreshing drinks 🥤',
      triggerCategoryIds: [1, 27],
      triggerCategorySlugs: ['pizza', 'pitsa', 'gigant-pizza'],
      excludeCategoryIds: [5],
      excludeCategorySlugs: ['drinks', 'ichimliklar'],
      targetCategoryIds: [5],
      targetCategorySlugs: ['drinks', 'ichimliklar'],
      priority: 80,
    ),

    // 4. Burger in cart & No sauce in cart -> Recommend Sauces
    const RecommendationRuleEntity(
      id: 4,
      name: 'Burger -> Sauces',
      titleUz: 'Mazali souslar 🥫',
      titleRu: 'Вкусные соусы 🥫',
      titleEn: 'Tasty sauces 🥫',
      triggerCategoryIds: [2],
      triggerCategorySlugs: ['burger', 'burgerlar', 'fast-food'],
      excludeCategoryIds: [11],
      excludeCategorySlugs: ['souslar', 'sauces'],
      targetCategoryIds: [11],
      targetCategorySlugs: ['souslar', 'sauces'],
      priority: 70,
    ),

    // 5. Any meal in cart & No drink in cart -> Recommend Drinks
    const RecommendationRuleEntity(
      id: 5,
      name: 'Any Meal -> Drinks',
      titleUz: 'Chanqadingizmi? Ichimlik qo\'shing 🥤',
      titleRu: 'Жажда? Добавьте напиток 🥤',
      titleEn: 'Thirsty? Add a drink 🥤',
      triggerCategoryIds: [1, 2, 4, 27],
      triggerCategorySlugs: ['pizza', 'burger', 'salatlar', 'side-dish'],
      excludeCategoryIds: [5],
      excludeCategorySlugs: ['drinks', 'ichimliklar'],
      targetCategoryIds: [5],
      targetCategorySlugs: ['drinks', 'ichimliklar'],
      priority: 50,
    ),

    // 6. Global Fallback: complementary items not in cart
    const RecommendationRuleEntity(
      id: 6,
      name: 'Global Fallback',
      titleUz: 'Buyurtmaga qo\'shishni tavsiya qilamiz ✨',
      titleRu: 'Рекомендуем добавить к заказу ✨',
      titleEn: 'Recommended with your order ✨',
      triggerCategoryIds: [],
      triggerCategorySlugs: [],
      excludeCategoryIds: [],
      excludeCategorySlugs: [],
      targetCategoryIds: [11, 5],
      targetCategorySlugs: ['souslar', 'drinks', 'side-dish'],
      priority: 10,
    ),
  ];

  /// Resolves the optimal recommendation match for the current cart state.
  static RecommendationMatch resolve({
    required List<CartItemEntity> cartItems,
    required List<ProductEntity> allProducts,
    required String localeCode,
    List<RecommendationRuleEntity>? serverRules,
  }) {
    if (cartItems.isEmpty || allProducts.isEmpty) {
      return const RecommendationMatch(title: '', products: []);
    }

    // 1. Extract active categories and products in current cart
    final cartCategorySlugs = <String>{};
    final cartCategoryIds = <int>{};
    final cartProductSlugs = <String>{};

    for (final item in cartItems) {
      cartProductSlugs.add(item.product.slug);
      final cat = item.product.category;
      if (cat != null) {
        if (cat.slug.isNotEmpty) {
          cartCategorySlugs.add(cat.slug.toLowerCase());
        }
        if (cat.id > 0) {
          cartCategoryIds.add(cat.id);
        }
      }
    }

    // 2. Select rules: Server rules take precedence, defaults act as fallback
    final rules = (serverRules != null && serverRules.isNotEmpty)
        ? serverRules
        : defaultRules;

    final sortedRules = List<RecommendationRuleEntity>.from(rules)
      ..sort((a, b) => b.priority.compareTo(a.priority));

    // 3. Evaluate rules sequentially by priority
    for (final rule in sortedRules) {
      // Check exclusion condition:
      // If ANY excluded category is already present in cart, this rule is invalid!
      final hasExcludedSlug = rule.excludeCategorySlugs.any((s) => cartCategorySlugs.contains(s));
      final hasExcludedId = rule.excludeCategoryIds.any((id) => cartCategoryIds.contains(id));
      if (hasExcludedSlug || hasExcludedId) {
        continue;
      }

      // Check trigger condition:
      // If triggers are defined, at least ONE must be present in cart
      if (rule.triggerCategorySlugs.isNotEmpty || rule.triggerCategoryIds.isNotEmpty) {
        final matchesTriggerSlug = rule.triggerCategorySlugs.any((s) => cartCategorySlugs.contains(s));
        final matchesTriggerId = rule.triggerCategoryIds.any((id) => cartCategoryIds.contains(id));

        if (!matchesTriggerSlug && !matchesTriggerId) {
          continue;
        }
      }

      // Find candidates from target categories not already in cart
      final candidates = allProducts.where((p) {
        if (cartProductSlugs.contains(p.slug)) return false;

        final pCat = p.category;
        if (pCat == null) return false;

        final pSlug = pCat.slug.toLowerCase();
        final matchesTargetSlug = rule.targetCategorySlugs.any((s) => s == pSlug || pSlug.contains(s));
        final matchesTargetId = rule.targetCategoryIds.contains(pCat.id);

        return matchesTargetSlug || matchesTargetId;
      }).take(10).toList();

      if (candidates.isNotEmpty) {
        return RecommendationMatch(
          title: rule.getTitle(localeCode),
          products: candidates,
        );
      }
    }

    return const RecommendationMatch(title: '', products: []);
  }
}
