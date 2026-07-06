import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/core/theme/app_icons.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:pizza_strada/features/home/domain/entities/home_entities.dart';
import 'package:pizza_strada/features/home/presentation/bloc/home_cubit.dart';
import 'package:pizza_strada/features/loyalty/presentation/bloc/loyalty_cubit.dart';
import 'package:pizza_strada/features/home/presentation/widgets/product_card.dart';
import 'package:pizza_strada/core/widgets/app_shimmer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();
  final ScrollController _categoryScrollController = ScrollController();

  // Category sync
  String? _activeCategory;
  bool _isScrollingToCategory = false;

  // Search
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearchActive = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _categoryScrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _searchQuery = query.trim().toLowerCase());
      }
    });
  }

  void _openSearch() {
    setState(() {
      _isSearchActive = true;
    });
  }

  void _closeSearch() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() {
      _isSearchActive = false;
      _searchQuery = '';
    });
  }

  // Ekranda ko'rinib turgan scroll offsetiga qarab aktiv kategoriyani aniqlash
  void _onScroll() {
    if (_isScrollingToCategory) return;
    
    final state = context.read<HomeCubit>().state;
    if (state is! HomeLoaded) return;

    final double screenWidth = MediaQuery.of(context).size.width;
    final double scrollOffset = _scrollController.offset;

    final activeSlug = _getActiveCategory(
      scrollOffset,
      screenWidth,
      state.categories,
      state.fullProducts,
    );

    if (activeSlug != _activeCategory) {
      setState(() {
        _activeCategory = activeSlug;
      });
      _scrollToActiveCategoryChip(state.categories.indexWhere((c) => c.slug == activeSlug));
    }
  }

  // Kategoriya chipiga mos keluvchi scroll offsetini hisoblash
  double _getTargetOffset(
    String targetSlug,
    double screenWidth,
    List<CategoryEntity> categories,
    List<ProductEntity> allProducts,
  ) {
    double currentOffset = 0.0;
    
    final double gridItemWidth = (screenWidth - 48) / 2;
    final double rowHeight = (gridItemWidth / 0.60) + 16; // 0.60 is childAspectRatio, 16 is spacing
    
    for (final cat in categories) {
      if (cat.slug == targetSlug) {
        return currentOffset;
      }
      final catProducts = allProducts.where((p) => p.category?.slug == cat.slug).toList();
      if (catProducts.isEmpty) continue;
      
      final int rows = (catProducts.length / 2).ceil();
      final double sectionHeight = 56.0 + (rows * rowHeight) + 16.0; // 56px header + grid + bottom padding
      currentOffset += sectionHeight;
    }
    
    return currentOffset;
  }

  // Scroll holatiga qarab joriy kategoriyani aniqlash formulasi
  String _getActiveCategory(
    double scrollOffset,
    double screenWidth,
    List<CategoryEntity> categories,
    List<ProductEntity> allProducts,
  ) {
    double currentOffset = 0.0;
    
    if (scrollOffset < currentOffset) {
      return categories.firstOrNull?.slug ?? '';
    }

    final double gridItemWidth = (screenWidth - 48) / 2;
    final double rowHeight = (gridItemWidth / 0.60) + 16;
    
    for (final cat in categories) {
      final catProducts = allProducts.where((p) => p.category?.slug == cat.slug).toList();
      if (catProducts.isEmpty) continue;
      
      final int rows = (catProducts.length / 2).ceil();
      final double sectionHeight = 56.0 + (rows * rowHeight) + 16.0;
      
      if (scrollOffset >= currentOffset && scrollOffset < currentOffset + sectionHeight) {
        return cat.slug;
      }
      currentOffset += sectionHeight;
    }
    
    return categories.lastOrNull?.slug ?? '';
  }

  // Yuqoridagi kategoriya chiplari o'zgarishi bilan gorizontal listni scroll qilish
  void _scrollToActiveCategoryChip(int index) {
    if (index < 0 || !_categoryScrollController.hasClients) return;
    final double targetOffset = index * 100.0; // Taxminiy chip kengligi
    _categoryScrollController.animateTo(
      targetOffset.clamp(0.0, _categoryScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          // Birinchi yuklanganda aktiv kategoriyani belgilash
          if (state is HomeLoaded && _activeCategory == null) {
            _activeCategory = state.categories.firstOrNull?.slug;
          }

          return RefreshIndicator(
            onRefresh: () => context.read<HomeCubit>().init(),
            color: AppColors.primary,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // App Bar
                SliverAppBar(
                  pinned: true,
                  backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  title: Row(
                    children: [
                      Image.asset(
                        'assets/icons/logo.png',
                        height: 32,
                        errorBuilder: (_, __, ___) => Text(
                          'Pizza strada',
                          style: AppTextStyles.h2.copyWith(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                   actions: [
                    // Search toggle
                    if (_isSearchActive)
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.neutral900),
                        onPressed: _closeSearch,
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.search_rounded, color: AppColors.neutral900),
                        onPressed: _openSearch,
                      ),
                    // Cart badge
                    BlocBuilder<CartCubit, CartState>(
                      builder: (ctx, cartState) {
                        final count = cartState.items.length;
                        return Stack(
                          children: [
                            IconButton(
                              icon: const Icon(AppIcons.cart, color: AppColors.neutral900),
                              onPressed: () => context.push('/cart'),
                            ),
                            if (count > 0)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '$count',
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                  // Search bar (bottom of AppBar when active)
                  bottom: _isSearchActive
                      ? PreferredSize(
                          preferredSize: const Size.fromHeight(56),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                            child: TextField(
                              controller: _searchController,
                              autofocus: true,
                              onChanged: _onSearchChanged,
                              decoration: InputDecoration(
                                hintText: 'home.search_hint'.tr(),
                                hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral400),
                                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.neutral400, size: 20),
                                filled: true,
                                fillColor: Theme.of(context).brightness == Brightness.dark
                                    ? AppColors.darkSurface
                                    : AppColors.neutral100,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        )
                      : null,
                ),

                if (state is HomeLoading) ...[
                  // Sticky Category chips Shimmer
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 52,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: 6,
                        itemBuilder: (_, __) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: AppShimmer(
                            width: 80,
                            height: 36,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Mock Categories shimmer
                  for (int section = 0; section < 2; section++) ...[
                    // Category Title Shimmer
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                      sliver: SliverToBoxAdapter(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: AppShimmer(
                            width: 120,
                            height: 24,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                    // Product Card Shimmers Grid
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.68,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Image skeleton
                                  AspectRatio(
                                    aspectRatio: 1.2,
                                    child: AppShimmer(
                                      width: double.infinity,
                                      height: double.infinity,
                                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                    ),
                                  ),
                                  // Content skeleton
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Title Shimmer
                                        AppShimmer(
                                          width: 100,
                                          height: 16,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        const SizedBox(height: 6),
                                        // Description Shimmer
                                        AppShimmer(
                                          width: 130,
                                          height: 12,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        const SizedBox(height: 8),
                                        // Price + Add Button Shimmer
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            AppShimmer(
                                              width: 60,
                                              height: 14,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            AppShimmer(
                                              width: 28,
                                              height: 28,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                          childCount: 4,
                        ),
                      ),
                    ),
                  ],
                  // Bottom spacer
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 120),
                  ),
                ]
                else if (state is HomeFailure)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(AppIcons.wifiOff, size: 48, color: AppColors.neutral400),
                          const SizedBox(height: 12),
                          Text(state.message, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral600), textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  )
                else if (state is HomeLoaded) ...[

                  // Win-back Banners
                  SliverToBoxAdapter(
                    child: BlocBuilder<LoyaltyCubit, LoyaltyState>(
                      builder: (context, loyaltyState) {
                        if (loyaltyState is LoyaltyLoaded && loyaltyState.loyalty.lastOrderDate != null) {
                          final daysSinceLastOrder = DateTime.now().difference(loyaltyState.loyalty.lastOrderDate!).inDays;
                          
                          if (daysSinceLastOrder >= 7) {
                            String message = '';
                            String subMessage = '';
                            
                            if (daysSinceLastOrder >= 30) {
                              message = 'Sog\'indingizmi? Sevimli taomingiz kutmoqda!';
                              subMessage = 'Siz uchun maxsus 20% chegirma. Promo-kod: WINBACK20';
                              if (loyaltyState.loyalty.expiringPoints != null && loyaltyState.loyalty.expiringPoints! > 0) {
                                subMessage += '\nShoshiling, ballaringiz muddati tugayapti!';
                              }
                            } else if (daysSinceLastOrder >= 14) {
                              message = 'Sog\'indingizmi? Sevimli taomingiz kutmoqda!';
                              subMessage = 'Siz uchun maxsus 10% chegirma. Promo-kod: WINBACK10';
                            } else if (daysSinceLastOrder >= 7) {
                              message = 'Sog\'indingizmi? Sevimli taomingiz kutmoqda!';
                            }

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: Dismissible(
                                key: Key('winback_banner_$daysSinceLastOrder'),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.local_pizza_rounded, color: AppColors.primary, size: 36),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(message, style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary)),
                                            if (subMessage.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(subMessage, style: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral700)),
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
                        return const SizedBox.shrink();
                      },
                    ),
                  ),

                  // Search aktiv bo'lganda category chips yashiriladi
                  if (!_isSearchActive)
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: _StickyCategoryDelegate(
                        child: Container(
                          color: Theme.of(context).appBarTheme.backgroundColor,
                          alignment: Alignment.centerLeft,
                          child: ListView.builder(
                            controller: _categoryScrollController,
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: state.categories.length,
                            itemBuilder: (_, i) {
                              final cat = state.categories[i];
                              final selected = _activeCategory == cat.slug;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(cat.title),
                                  selected: selected,
                                  onSelected: (_) {
                                    setState(() {
                                      _activeCategory = cat.slug;
                                      _isScrollingToCategory = true;
                                    });
                                    final targetOffset = _getTargetOffset(
                                      cat.slug,
                                      screenWidth,
                                      state.categories,
                                      state.fullProducts,
                                    );
                                    _scrollController.animateTo(
                                      targetOffset,
                                      duration: const Duration(milliseconds: 350),
                                      curve: Curves.easeInOut,
                                    ).then((_) {
                                      _isScrollingToCategory = false;
                                    });
                                  },
                                  selectedColor: AppColors.primary,
                                  backgroundColor: Theme.of(context).cardColor,
                                  disabledColor: Theme.of(context).cardColor,
                                  showCheckmark: false,
                                  side: BorderSide(
                                    color: selected ? AppColors.primary : (Theme.of(context).brightness == Brightness.dark ? AppColors.neutral800 : AppColors.neutral200),
                                    width: 1,
                                  ),
                                  labelStyle: AppTextStyles.labelSmall.copyWith(
                                    color: selected ? Colors.white : Theme.of(context).textTheme.bodySmall?.color,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                  // Search natijalari (aktiv bo'lganda)
                  if (_isSearchActive) ...[
                    Builder(
                      builder: (context) {
                        final query = _searchQuery;
                        final results = query.isEmpty
                            ? state.fullProducts
                            : state.fullProducts.where((p) {
                                final title = p.title.toLowerCase();
                                final desc = (p.description ?? '').toLowerCase();
                                return title.contains(query) || desc.contains(query);
                              }).toList();

                        if (results.isEmpty) {
                          return SliverFillRemaining(
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.search_off_rounded, size: 56, color: AppColors.neutral300),
                                  const SizedBox(height: 16),
                                  Text(
                                    'home.search_empty'.tr(),
                                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral500),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                          sliver: SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 0.68,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (ctx, i) {
                                final product = results[i];
                                return BlocBuilder<CartCubit, CartState>(
                                  builder: (context, cartState) {
                                    final quantity = cartState.items
                                        .where((item) => item.product.slug == product.slug)
                                        .fold<int>(0, (sum, item) => sum + item.quantity);
                                    return ProductCard(
                                      product: product,
                                      quantityInCart: quantity,
                                      onTap: () => context.push('/product/${product.slug}', extra: product),
                                    );
                                  },
                                );
                              },
                              childCount: results.length,
                            ),
                          ),
                        );
                      },
                    ),
                  ] else ...[
                    // Har bir kategoriya va uning mahsulotlarini alohida ko'rsatish
                    for (final cat in state.categories) ...[
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                        sliver: SliverToBoxAdapter(
                          child: Text(
                            cat.title,
                            style: AppTextStyles.h3.copyWith(
                              color: Theme.of(context).textTheme.headlineMedium?.color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      Builder(
                        builder: (context) {
                          final catProducts = state.fullProducts
                              .where((p) => p.category?.slug == cat.slug)
                              .toList();
                          if (catProducts.isEmpty) {
                            return const SliverToBoxAdapter(child: SizedBox.shrink());
                          }
                          return SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            sliver: SliverGrid(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: 0.68,
                              ),
                              delegate: SliverChildBuilderDelegate(
                                (ctx, i) {
                                  final product = catProducts[i];
                                  return BlocBuilder<CartCubit, CartState>(
                                    builder: (context, cartState) {
                                      final quantity = cartState.items
                                          .where((item) => item.product.slug == product.slug)
                                          .fold<int>(0, (sum, item) => sum + item.quantity);
                                      return ProductCard(
                                        product: product,
                                        quantityInCart: quantity,
                                        onTap: () => context.push('/product/${product.slug}', extra: product),
                                      );
                                    },
                                  );
                                },
                                childCount: catProducts.length,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                    const SliverToBoxAdapter(child: SizedBox(height: 120)),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StickyCategoryDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _StickyCategoryDelegate({required this.child});

  @override
  double get minExtent => 60;
  @override
  double get maxExtent => 60;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  bool shouldRebuild(_StickyCategoryDelegate oldDelegate) => true;
}
