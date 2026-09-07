import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_icons.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/checkout/checkout_cubit.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/checkout/checkout_state.dart';
import 'package:pizza_strada/features/cart/presentation/widgets/order_type_bottom_sheet.dart';
import 'package:pizza_strada/features/home/domain/entities/home_entities.dart';
import 'package:pizza_strada/features/home/presentation/bloc/home_cubit.dart';
import 'package:pizza_strada/features/home/presentation/widgets/product_card.dart';
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

  // Search
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearchActive = false;
  Timer? _debounce;

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
    _searchController.dispose();
    _debounce?.cancel();
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

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => _searchQuery = query.trim().toLowerCase());
      }
    });
  }

  void _openSearch() => setState(() => _isSearchActive = true);

  void _closeSearch() {
    _debounce?.cancel();
    _searchController.clear();
    setState(() {
      _isSearchActive = false;
      _searchQuery = '';
    });
  }

  /// Mahsulot kartasiga tegish: variant > 1 bo'lsa tanlash sheetini ochish,
  /// 1 ta (yoki variantsiz) bo'lsa ProductDetailPage ga o'tish.
  void _handleProductTap(ProductEntity product) {
    if (product.variants.length > 1) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => VariantPickerSheet(
          product: product,
          onPick: (variant) {
            context.read<CartCubit>().addToCart(product, variant: variant);
          },
        ),
      );
    } else {
      // Variantsiz yoki 1 ta variant: to'g'ridan-to'g'ri detail sahifaga
      context.push('/product/${product.slug}', extra: product);
    }
  }

  /// `+` tugmasi: variantsiz/1 ta variant → to'g'ridan-to'g'ri savatga,
  /// > 1 variant → variant sheet.
  void _handleAddToCart(ProductEntity product) {
    if (product.variants.length > 1) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => VariantPickerSheet(
          product: product,
          onPick: (variant) {
            context.read<CartCubit>().addToCart(product, variant: variant);
          },
        ),
      );
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
    double currentOffset = 0.0;
    final double gridItemWidth = (screenWidth - 48) / 2;
    final double rowHeight = (gridItemWidth / 0.62) + 16;

    for (final cat in categories) {
      if (cat.slug == targetSlug) return currentOffset;
      final catProducts = allProducts
          .where((p) =>
              (p.category?.id != 0 && p.category?.id == cat.id) ||
              (p.category?.slug == cat.slug))
          .toList();
      if (catProducts.isEmpty) continue;
      final int rows = (catProducts.length / 2).ceil();
      final double sectionHeight = 56.0 + (rows * rowHeight) + 16.0;
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
    double currentOffset = 0.0;
    if (scrollOffset < currentOffset) {
      return categories.firstOrNull?.slug ?? '';
    }

    final double gridItemWidth = (screenWidth - 48) / 2;
    final double rowHeight = (gridItemWidth / 0.62) + 16;

    for (final cat in categories) {
      final catProducts = allProducts
          .where((p) =>
              (p.category?.id != 0 && p.category?.id == cat.id) ||
              (p.category?.slug == cat.slug))
          .toList();
      if (catProducts.isEmpty) continue;

      final int rows = (catProducts.length / 2).ceil();
      final double sectionHeight = 56.0 + (rows * rowHeight) + 16.0;

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
                // ── AppBar ──
                SliverAppBar(
                  pinned: true,
                  toolbarHeight: 60,
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
                          : AppColors.neutral200,
                    ),
                  ),
                  titleSpacing: 16,
                  title: Image.asset(
                    'assets/icons/logo.png',
                    height: 38,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Text(
                      'Pizza strada',
                      style: AppTextStyles.h3.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  actions: [
                    // Search toggle
                    if (_isSearchActive)
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: isDark ? Colors.white : AppColors.neutral900,
                        ),
                        onPressed: _closeSearch,
                      )
                    else
                      IconButton(
                        icon: Icon(
                          Icons.search_rounded,
                          color: isDark ? Colors.white : AppColors.neutral900,
                        ),
                        onPressed: _openSearch,
                      ),
                    // Cart badge (AppBar)
                    BlocBuilder<CartCubit, CartState>(
                      builder: (ctx, cartState) {
                        final count = cartState.items.length;
                        return Stack(
                          children: [
                            IconButton(
                              icon: Icon(
                                AppIcons.cart,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.neutral900,
                              ),
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
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700),
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
                  // Search bar (AppBar bottom da)
                  flexibleSpace: _isSearchActive
                      ? FlexibleSpaceBar(
                          background: Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 0, 16, 8),
                              child: TextField(
                                controller: _searchController,
                                autofocus: true,
                                onChanged: _onSearchChanged,
                                decoration: InputDecoration(
                                  hintText: 'home.search_hint'.tr(),
                                  prefixIcon: const Icon(
                                      Icons.search_rounded,
                                      color: AppColors.neutral400,
                                      size: 20),
                                ),
                              ),
                            ),
                          ),
                        )
                      : null,
                  expandedHeight: _isSearchActive ? 116 : null,
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

                  // ── Yetkazib berish / Manzil tanlash paneli ──
                  if (!_isSearchActive)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                        child: BlocBuilder<CheckoutCubit, CheckoutState>(
                          builder: (context, checkoutState) {
                            final isDelivery = checkoutState.isDelivery;
                            final String modeLabel = isDelivery
                                ? 'checkout.delivery'.tr()
                                : 'checkout.pickup'.tr();
                            final String displayTitle = isDelivery
                                ? (checkoutState.address != null &&
                                        checkoutState.address!.isNotEmpty
                                    ? checkoutState.address!
                                    : 'checkout.select_address'.tr())
                                : (checkoutState.branchTitle != null &&
                                        checkoutState.branchTitle!.isNotEmpty
                                    ? checkoutState.branchTitle!
                                    : 'checkout.select_branch'.tr());

                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: Colors.transparent,
                                    builder: (_) =>
                                        const OrderTypeBottomSheet(),
                                  );
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.darkSurface
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDark
                                          ? AppColors.neutral800
                                          : AppColors.neutral200,
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                            alpha: isDark ? 0.2 : 0.04),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: isDelivery
                                              ? AppColors.primary
                                                  .withValues(alpha: 0.1)
                                              : AppColors.secondary
                                                  .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          isDelivery
                                              ? Icons.delivery_dining_rounded
                                              : Icons.storefront_rounded,
                                          color: isDelivery
                                              ? AppColors.primary
                                              : AppColors.secondary,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  width: 7,
                                                  height: 7,
                                                  decoration: BoxDecoration(
                                                    color: isDelivery
                                                        ? AppColors.primary
                                                        : AppColors.secondary,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  modeLabel,
                                                  style: AppTextStyles
                                                      .bodyExtraSmall
                                                      .copyWith(
                                                    fontSize: 11,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    color: isDelivery
                                                        ? AppColors.primary
                                                        : AppColors.secondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              displayTitle,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppTextStyles.labelMedium
                                                  .copyWith(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: Theme.of(context)
                                                    .textTheme
                                                    .bodyLarge
                                                    ?.color,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? AppColors.neutral800
                                              : AppColors.neutral100,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'common.change'.tr(),
                                              style: AppTextStyles
                                                  .bodyExtraSmall
                                                  .copyWith(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                            const SizedBox(width: 2),
                                            const Icon(
                                              Icons.keyboard_arrow_down_rounded,
                                              size: 16,
                                              color: AppColors.primary,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                  // ── Banner Carousel ──
                  if (state.sliders.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _BannerCarousel(
                        sliders: state.sliders,
                        controller: _carouselController,
                        currentIndex: _carouselIndex,
                        onPageChanged: (i) {
                          setState(() => _carouselIndex = i);
                        },
                      ),
                    ),

                  // ── Sticky kategoriya chiplari (Pill uslubi) ──
                  if (!_isSearchActive)
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
                                      horizontal: 12, vertical: 8),
                                  itemCount: state.categories.length,
                                  itemBuilder: (_, i) {
                                    final cat = state.categories[i];
                                    final selected =
                                        _activeCategory == cat.slug;
                                    return _CategoryPillChip(
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
                                    : AppColors.neutral200,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                  // ── Search natijalari ──
                  if (_isSearchActive) ...[
                    Builder(builder: (context) {
                      final query = _searchQuery;
                      final results = query.isEmpty
                          ? state.fullProducts
                          : state.fullProducts
                              .where((p) {
                                final t = p.title.toLowerCase();
                                final d =
                                    (p.description ?? '').toLowerCase();
                                return t.contains(query) ||
                                    d.contains(query);
                              })
                              .toList();

                      if (results.isEmpty) {
                        return SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.search_off_rounded,
                                    size: 56,
                                    color: AppColors.neutral300),
                                const SizedBox(height: 16),
                                Text('home.search_empty'.tr(),
                                    style: AppTextStyles.bodyMedium
                                        .copyWith(
                                            color: AppColors.neutral500)),
                              ],
                            ),
                          ),
                        );
                      }

                      return SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.62,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) {
                              final product = results[i];
                              return BlocBuilder<CartCubit, CartState>(
                                builder: (context, cartState) {
                                  final qty = cartState.items
                                      .where((item) =>
                                          item.product.slug ==
                                          product.slug)
                                      .fold<int>(
                                          0, (s, item) => s + item.quantity);
                                  return ProductCard(
                                    product: product,
                                    quantityInCart: qty,
                                    onTap: () =>
                                        _handleProductTap(product),
                                    onAdd: () => _handleAddToCart(product),
                                    onRemove: () {
                                      final cartItem = cartState.items
                                          .where((item) =>
                                              item.product.slug ==
                                              product.slug)
                                          .firstOrNull;
                                      if (cartItem != null) {
                                        context
                                            .read<CartCubit>()
                                            .updateQuantity(cartItem, -1);
                                      }
                                    },
                                  );
                                },
                              );
                            },
                            childCount: results.length,
                          ),
                        ),
                      );
                    }),
                  ]

                  // ── Kategoriyali mahsulot bo'limlari ──
                  else ...[
                    for (final cat in state.categories) ...[
                      SliverPadding(
                        padding:
                            const EdgeInsets.fromLTRB(16, 24, 16, 12),
                        sliver: SliverToBoxAdapter(
                          child: Text(
                            cat.title,
                            style: AppTextStyles.h3.copyWith(
                              color: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.color,
                              fontWeight: FontWeight.bold,
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
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 0.62,
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
      child: Column(
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
                    borderRadius: BorderRadius.circular(12),
                    child: CachedNetworkImage(
                      imageUrl: slider.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.neutral800
                            : const Color(0xFFF1F5F9),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: AppColors.neutral100,
                        child: const Icon(Icons.image_outlined,
                            color: AppColors.neutral400, size: 48),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (sliders.length > 1) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(sliders.length, (i) {
                final isActive = i == currentIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: isActive ? 20 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : AppColors.neutral300,
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

/// Pill uslubidagi kategoriya chip (Uzum Tezkor uslubi)
class _CategoryPillChip extends StatelessWidget {
  final String title;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _CategoryPillChip({
    required this.title,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.neutral800 : AppColors.neutral100),
          borderRadius: BorderRadius.circular(999),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Color(0x22D32F2F),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          title,
          style: AppTextStyles.labelSmall.copyWith(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.neutral300 : AppColors.neutral700),
          ),
        ),
      ),
    );
  }
}

class _StickyCategoryDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  const _StickyCategoryDelegate({required this.child});

  @override
  double get minExtent => 52;
  @override
  double get maxExtent => 52;

  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      child;

  @override
  bool shouldRebuild(_StickyCategoryDelegate oldDelegate) => true;
}
