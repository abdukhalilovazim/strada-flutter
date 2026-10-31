import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_icons.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/core/theme/theme_cubit.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/checkout/checkout_cubit.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/checkout/checkout_state.dart';
import 'package:pizza_strada/features/cart/presentation/widgets/order_type_bottom_sheet.dart';
import 'package:pizza_strada/features/home/domain/entities/home_entities.dart';
import 'package:pizza_strada/features/home/presentation/bloc/home_cubit.dart';
import 'package:pizza_strada/features/home/presentation/widgets/header_location_pill.dart';
import 'package:pizza_strada/features/home/presentation/widgets/product_card.dart';
import 'package:pizza_strada/features/home/presentation/widgets/product_detail_modal.dart';
import 'package:pizza_strada/core/widgets/app_shimmer.dart';
import 'package:pizza_strada/core/utils/number_formatter.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();
  final ScrollController _categoryScrollController = ScrollController();

  // Kategoriya sync
  String? _activeCategory;
  bool _isScrollingToCategory = false;

  // Carousel
  final PageController _carouselController = PageController();
  int _carouselIndex = 0;
  Timer? _carouselTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _categoryScrollController.dispose();
    _carouselController.dispose();
    _carouselTimer?.cancel();
    super.dispose();
  }

  void _startCarouselTimer(int itemCount) {
    _carouselTimer?.cancel();
    if (itemCount <= 1) return;
    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_carouselController.hasClients) return;
      final next = (_carouselIndex + 1) % itemCount;
      _carouselController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }


  /// Mahsulot kartasiga tegish: dizayn skrinshotidagi to'liq ProductDetailModal dialogini ochish.
  void _handleProductTap(ProductEntity product) {
    ProductDetailModal.show(context, product);
  }

  /// `+` tugmasi: variantsiz/1 ta variant → to'g'ridan-to'g'ri savatga,
  /// > 1 variant → ProductDetailModal dialogi.
  void _handleAddToCart(ProductEntity product) {
    if (product.variants.length > 1) {
      ProductDetailModal.show(context, product);
    } else {
      final variant =
          product.variants.isNotEmpty ? product.variants.first : null;
      context.read<CartCubit>().addToCart(product, variant: variant);
    }
  }

  /// Scroll offsetiga qarab aktiv kategoriyani aniqlash
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
      setState(() => _activeCategory = activeSlug);
      _scrollToActiveCategoryChip(
          state.categories.indexWhere((c) => c.slug == activeSlug));
    }
  }

  /// Kategoriya offsetini hisoblash (grid row balandligi asosida)
  double _getTargetOffset(
    String targetSlug,
    double screenWidth,
    List<CategoryEntity> categories,
    List<ProductEntity> allProducts,
  ) {
    double currentOffset = 175.0; // Banner va padding balandligi
    final double gridItemWidth = (screenWidth - 46) / 2;
    final double rowHeight = (gridItemWidth / 0.61) + 14;

    for (final cat in categories) {
      if (cat.slug == targetSlug) return currentOffset;
      final catProducts = allProducts
          .where((p) =>
              (p.category?.id != 0 && p.category?.id == cat.id) ||
              (p.category?.slug == cat.slug))
          .toList();
      if (catProducts.isEmpty) continue;
      final int rows = (catProducts.length / 2).ceil();
      final double sectionHeight = 56.0 + (rows * rowHeight) + 14.0;
      currentOffset += sectionHeight;
    }
    return currentOffset;
  }

  String _getActiveCategory(
    double scrollOffset,
    double screenWidth,
    List<CategoryEntity> categories,
    List<ProductEntity> allProducts,
  ) {
    double currentOffset = 175.0;
    if (scrollOffset < currentOffset) {
      return categories.firstOrNull?.slug ?? '';
    }

    final double gridItemWidth = (screenWidth - 46) / 2;
    final double rowHeight = (gridItemWidth / 0.61) + 14;

    for (final cat in categories) {
      final catProducts = allProducts
          .where((p) =>
              (p.category?.id != 0 && p.category?.id == cat.id) ||
              (p.category?.slug == cat.slug))
          .toList();
      if (catProducts.isEmpty) continue;

      final int rows = (catProducts.length / 2).ceil();
      final double sectionHeight = 56.0 + (rows * rowHeight) + 14.0;

      if (scrollOffset >= currentOffset &&
          scrollOffset < currentOffset + sectionHeight) {
        return cat.slug;
      }
      currentOffset += sectionHeight;
    }
    return categories.lastOrNull?.slug ?? '';
  }

  void _scrollToActiveCategoryChip(int index) {
    if (index < 0 || !_categoryScrollController.hasClients) return;
    final double targetOffset = index * 100.0;
    _categoryScrollController.animateTo(
      targetOffset.clamp(
          0.0, _categoryScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // ── Uzum Tezkor uslubi: Pastki cart panel ──
      bottomNavigationBar: BlocBuilder<CartCubit, CartState>(
        builder: (context, cartState) {
          if (cartState.items.isEmpty) return const SizedBox.shrink();
          return _CartBottomPanel(
            itemCount: cartState.items.length,
            total: cartState.subtotal,
            isDark: isDark,
            onTap: () => context.push('/cart'),
          );
        },
      ),
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          if (state is HomeLoaded && _activeCategory == null) {
            _activeCategory = state.categories.firstOrNull?.slug;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _startCarouselTimer(state.sliders.length);
            });
          }

          return RefreshIndicator(
            onRefresh: () => context.read<HomeCubit>().init(),
            color: AppColors.primary,
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                // ── Header (Logo + Location + Theme + Language) ──
                SliverAppBar(
                  pinned: true,
                  toolbarHeight: 62,
                  backgroundColor:
                      Theme.of(context).appBarTheme.backgroundColor,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(1),
                    child: Container(
                      height: 1,
                      color: isDark
                          ? AppColors.neutral800
                          : AppColors.neutral200.withValues(alpha: 0.7),
                    ),
                  ),
                  titleSpacing: 12,
                  title: Row(
                    children: [
                      // 1. Logo
                      GestureDetector(
                        onTap: () {
                          _scrollController.animateTo(
                            0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Image.asset(
                          'assets/icons/logo.png',
                          height: 32,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => Text(
                            'Strada',
                            style: AppTextStyles.h3.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // 2. Location Pill
                      Expanded(
                        child: BlocBuilder<CheckoutCubit, CheckoutState>(
                          builder: (context, checkoutState) {
                            return HeaderLocationPill(
                              orderType: checkoutState.isDelivery ? 0 : 1,
                              addressName: checkoutState.address,
                              branchTitle: checkoutState.branchTitle,
                              onTap: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) =>
                                      const OrderTypeBottomSheet(),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),

                      // 3. Theme toggle (Sun / Moon)
                      BlocBuilder<ThemeCubit, ThemeMode>(
                        builder: (context, themeMode) {
                          final isDarkMode = themeMode == ThemeMode.dark;
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => context.read<ThemeCubit>().toggle(),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? AppColors.neutral800
                                      : AppColors.neutral100,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDarkMode
                                        ? AppColors.neutral700
                                        : AppColors.neutral200,
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  isDarkMode
                                      ? Icons.light_mode_rounded
                                      : Icons.dark_mode_rounded,
                                  size: 20,
                                  color: isDarkMode
                                      ? const Color(0xFFFFB800)
                                      : AppColors.neutral800,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // ── Loading skeleti ──
                if (state is HomeLoading) ...[
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 52,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: 6,
                        itemBuilder: (_, __) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: AppShimmer(
                              width: 80,
                              height: 36,
                              borderRadius: BorderRadius.circular(999)),
                        ),
                      ),
                    ),
                  ),
                  for (int section = 0; section < 2; section++) ...[
                    SliverPadding(
                      padding:
                          const EdgeInsets.fromLTRB(16, 24, 16, 12),
                      sliver: SliverToBoxAdapter(
                        child: AppShimmer(
                            width: 120,
                            height: 24,
                            borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                    SliverPadding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.62,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => Container(
                            decoration: BoxDecoration(
                              color: Theme.of(ctx).cardColor,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withValues(alpha: 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Expanded(
                                  flex: 5,
                                  child: AppShimmer(
                                      width: double.infinity,
                                      height: double.infinity,
                                      borderRadius: BorderRadius.circular(
                                          20)),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        AppShimmer(
                                            width: 100,
                                            height: 14,
                                            borderRadius:
                                                BorderRadius.circular(4)),
                                        AppShimmer(
                                            width: 60,
                                            height: 12,
                                            borderRadius:
                                                BorderRadius.circular(4)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          childCount: 4,
                        ),
                      ),
                    ),
                  ],
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ]

                // ── Error holati ──
                else if (state is HomeFailure)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(AppIcons.wifiOff,
                              size: 48, color: AppColors.neutral400),
                          const SizedBox(height: 12),
                          Text(state.message,
                              style: AppTextStyles.bodyMedium
                                  .copyWith(color: AppColors.neutral600),
                              textAlign: TextAlign.center),
                        ],
                      ),
                    ),
                  )

                // ── Loaded holati ──
                else if (state is HomeLoaded) ...[

                  // ── 2. Banner (API dan kelgan sliderlar) ──
                  if (state.sliders.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                        child: _BannerCarousel(
                          sliders: state.sliders,
                          controller: _carouselController,
                          currentIndex: _carouselIndex,
                          onPageChanged: (i) {
                            setState(() => _carouselIndex = i);
                          },
                        ),
                      ),
                    ),

                  // ── 3. Menu (Kategoriyalar gorizontal tablari) ──
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _StickyCategoryDelegate(
                      child: Container(
                        color: Theme.of(context)
                            .appBarTheme
                            .backgroundColor,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Expanded(
                              child: ListView.builder(
                                controller: _categoryScrollController,
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16),
                                itemCount: state.categories.length,
                                itemBuilder: (_, i) {
                                  final cat = state.categories[i];
                                  final selected =
                                      _activeCategory == cat.slug;
                                  return _CategoryUnderlineTab(
                                    title: cat.title,
                                    isSelected: selected,
                                    isDark: isDark,
                                    onTap: () {
                                      setState(() {
                                        _activeCategory = cat.slug;
                                        _isScrollingToCategory = true;
                                      });
                                      final offset = _getTargetOffset(
                                        cat.slug,
                                        screenWidth,
                                        state.categories,
                                        state.fullProducts,
                                      );
                                      _scrollController
                                          .animateTo(
                                        offset,
                                        duration: const Duration(
                                            milliseconds: 350),
                                        curve: Curves.easeInOut,
                                      )
                                          .then((_) {
                                        _isScrollingToCategory = false;
                                      });
                                    },
                                  );
                                },
                              ),
                            ),
                            // Pastki ajratuvchi chiziq
                            Container(
                              height: 1,
                              color: isDark
                                  ? AppColors.neutral800
                                  : AppColors.neutral200.withValues(alpha: 0.7),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── 4. Mahsulotlar (Kategoriyali bo'limlar) ──
                  for (final cat in state.categories) ...[
                    SliverPadding(
                      padding:
                          const EdgeInsets.fromLTRB(16, 24, 16, 12),
                      sliver: SliverToBoxAdapter(
                        child: Text(
                          cat.title,
                          style: AppTextStyles.h3.copyWith(
                            color: isDark ? Colors.white : AppColors.neutral900,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                      ),
                    ),
                    Builder(builder: (context) {
                      final catProducts = state.fullProducts
                          .where((p) =>
                              (p.category?.id != 0 &&
                                  p.category?.id == cat.id) ||
                              (p.category?.slug == cat.slug))
                          .toList();
                      if (catProducts.isEmpty) {
                        return const SliverToBoxAdapter(
                            child: SizedBox.shrink());
                      }
                      return SliverPadding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: 0.61,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) {
                              final product = catProducts[i];
                              return BlocBuilder<CartCubit, CartState>(
                                builder: (context, cartState) {
                                  final qty = cartState.items
                                      .where((item) =>
                                          item.product.slug ==
                                          product.slug)
                                      .fold<int>(
                                          0,
                                          (s, item) =>
                                              s + item.quantity);
                                  return ProductCard(
                                    product: product,
                                    quantityInCart: qty,
                                    onTap: () =>
                                        _handleProductTap(product),
                                    onAdd: () =>
                                        _handleAddToCart(product),
                                    onRemove: () {
                                      final cartItem = cartState.items
                                          .where((item) =>
                                              item.product.slug ==
                                              product.slug)
                                          .firstOrNull;
                                      if (cartItem != null) {
                                        context
                                            .read<CartCubit>()
                                            .updateQuantity(
                                                cartItem, -1);
                                      }
                                    },
                                  );
                                },
                              );
                            },
                            childCount: catProducts.length,
                          ),
                        ),
                      );
                    }),
                  ],
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Pastki savat paneli — Uzum Tezkor uslubi
class _CartBottomPanel extends StatelessWidget {
  final int itemCount;
  final double total;
  final bool isDark;
  final VoidCallback onTap;

  const _CartBottomPanel({
    required this.itemCount,
    required this.total,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.neutral800 : AppColors.neutral100,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(999),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33D32F2F),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Miqdor badge (chapda)
                Container(
                  margin: const EdgeInsets.only(left: 4),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Center(
                    child: Text(
                      '$itemCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                // Matn (markazda)
                Expanded(
                  child: Text(
                    'cart.checkout'.tr(),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                // Summa (o'ngda)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Text(
                    '${NumberFormatter.formatSum(total.toInt())} ${'common.currency'.tr()}',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Banner Carousel widget — PageView + auto-scroll + dots.
class _BannerCarousel extends StatelessWidget {
  final List<SliderEntity> sliders;
  final PageController controller;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;

  const _BannerCarousel({
    required this.sliders,
    required this.controller,
    required this.currentIndex,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (sliders.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 16 / 7,
            child: PageView.builder(
              controller: controller,
              itemCount: sliders.length,
              onPageChanged: onPageChanged,
              itemBuilder: (context, index) {
                final slider = sliders[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: slider.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.neutral800
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        decoration: BoxDecoration(
                          color: AppColors.neutral100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.image_outlined,
                          color: AppColors.neutral400,
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (sliders.length > 1) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(sliders.length, (i) {
                final isActive = i == currentIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 16 : 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF0091FF)
                        : AppColors.neutral300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }
}

/// Kategoriyalar uchun qizil chiziqli gorizontal tab (Uzum / Strada veb uslubi)
class _CategoryUnderlineTab extends StatelessWidget {
  final String title;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _CategoryUnderlineTab({
    required this.title,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.only(right: 20),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: AppTextStyles.labelMedium.copyWith(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.neutral400 : AppColors.neutral700),
              ),
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              width: isSelected ? 30 : 0,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _StickyCategoryDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  const _StickyCategoryDelegate({required this.child});

  @override
  double get minExtent => 48;
  @override
  double get maxExtent => 48;

  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      child;

  @override
  bool shouldRebuild(_StickyCategoryDelegate oldDelegate) => true;
}
