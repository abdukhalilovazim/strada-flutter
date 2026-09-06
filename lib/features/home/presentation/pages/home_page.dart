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
import 'package:pizza_strada/features/home/presentation/widgets/header_location_pill.dart';
import 'package:pizza_strada/features/home/presentation/widgets/home_loyalty_card.dart';
import 'package:pizza_strada/features/home/presentation/widgets/product_card.dart';
import 'package:pizza_strada/features/loyalty/presentation/bloc/loyalty_cubit.dart';
import 'package:pizza_strada/core/widgets/app_shimmer.dart';

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
    _carouselTimer =
        Timer.periodic(const Duration(seconds: 5), (_) {
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
    final double rowHeight = (gridItemWidth / 0.60) + 16;

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
    final double rowHeight = (gridItemWidth / 0.60) + 16;

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

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          if (state is HomeLoaded && _activeCategory == null) {
            _activeCategory = state.categories.firstOrNull?.slug;
            // Carousel timerni sliderlar bilan boshlash
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
                  backgroundColor:
                      Theme.of(context).appBarTheme.backgroundColor,
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(1),
                    child: Container(
                      height: 1,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.neutral800
                          : AppColors.neutral200,
                    ),
                  ),
                  title: Row(
                    children: [
                      Image.asset(
                        'assets/icons/logo.png',
                        height: 30,
                        errorBuilder: (_, __, ___) => Text(
                          'Pizza strada',
                          style: AppTextStyles.h3.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
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
                    ],
                  ),
                  actions: [
                    // Search toggle
                    if (_isSearchActive)
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: Theme.of(context).brightness ==
                                  Brightness.dark
                              ? Colors.white
                              : AppColors.neutral900,
                        ),
                        onPressed: _closeSearch,
                      )
                    else
                      IconButton(
                        icon: Icon(
                          Icons.search_rounded,
                          color: Theme.of(context).brightness ==
                                  Brightness.dark
                              ? Colors.white
                              : AppColors.neutral900,
                        ),
                        onPressed: _openSearch,
                      ),
                    // Cart badge (AppBar da ham ko'rsatiladi)
                    BlocBuilder<CartCubit, CartState>(
                      builder: (ctx, cartState) {
                        final count = cartState.items.length;
                        return Stack(
                          children: [
                            IconButton(
                              icon: Icon(
                                AppIcons.cart,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
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
                              borderRadius: BorderRadius.circular(12)),
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
                          childAspectRatio: 0.68,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => Container(
                            decoration: BoxDecoration(
                              color: Theme.of(ctx).cardColor,
                              borderRadius: BorderRadius.circular(16),
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
                                AppShimmer(
                                    width: double.infinity,
                                    height: double.infinity,
                                    borderRadius:
                                        const BorderRadius.vertical(
                                            top: Radius.circular(16))),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    children: [
                                      AppShimmer(
                                          width: 100,
                                          height: 16,
                                          borderRadius:
                                              BorderRadius.circular(4)),
                                      const SizedBox(height: 6),
                                      AppShimmer(
                                          width: 60,
                                          height: 14,
                                          borderRadius:
                                              BorderRadius.circular(4)),
                                    ],
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

                  // Loyalty karta
                  const SliverToBoxAdapter(child: HomeLoyaltyCard()),

                  // Win-back bannerlar
                  SliverToBoxAdapter(
                    child: BlocBuilder<LoyaltyCubit, LoyaltyState>(
                      builder: (context, loyaltyState) {
                        if (loyaltyState is LoyaltyLoaded &&
                            loyaltyState.loyalty.lastOrderDate != null) {
                          final days = DateTime.now()
                              .difference(
                                  loyaltyState.loyalty.lastOrderDate!)
                              .inDays;
                          if (days >= 7) {
                            String msg = '';
                            String sub = '';
                            if (days >= 30) {
                              msg =
                                  "Sog'indingizmi? Sevimli taomingiz kutmoqda!";
                              sub =
                                  'Siz uchun maxsus 20% chegirma. Promo-kod: WINBACK20';
                              if (loyaltyState.loyalty.expiringPoints !=
                                      null &&
                                  loyaltyState.loyalty.expiringPoints! >
                                      0) {
                                sub +=
                                    '\nShoshiling, ballaringiz muddati tugayapti!';
                              }
                            } else if (days >= 14) {
                              msg =
                                  "Sog'indingizmi? Sevimli taomingiz kutmoqda!";
                              sub =
                                  'Siz uchun maxsus 10% chegirma. Promo-kod: WINBACK10';
                            } else {
                              msg =
                                  "Sog'indingizmi? Sevimli taomingiz kutmoqda!";
                            }

                            return Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  16, 8, 16, 0),
                              child: Dismissible(
                                key: Key('winback_$days'),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLight,
                                    borderRadius:
                                        BorderRadius.circular(16),
                                    border: Border.all(
                                        color: AppColors.primary
                                            .withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                          Icons.local_pizza_rounded,
                                          color: AppColors.primary,
                                          size: 36),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(msg,
                                                style: AppTextStyles
                                                    .labelMedium
                                                    .copyWith(
                                                        color: AppColors
                                                            .primary)),
                                            if (sub.isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(sub,
                                                  style: AppTextStyles
                                                      .bodySmall
                                                      .copyWith(
                                                          color: AppColors
                                                              .neutral700)),
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

                  // ── Banner Carousel (Swiper) ──
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

                  // ── Sticky kategoriya chiplari ──
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
                                  controller:
                                      _categoryScrollController,
                                  scrollDirection: Axis.horizontal,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8),
                                  itemCount: state.categories.length,
                                  itemBuilder: (_, i) {
                                    final cat =
                                        state.categories[i];
                                    final selected =
                                        _activeCategory == cat.slug;
                                    return _CategoryTab(
                                      title: cat.title,
                                      isSelected: selected,
                                      onTap: () {
                                        setState(() {
                                          _activeCategory = cat.slug;
                                          _isScrollingToCategory =
                                              true;
                                        });
                                        final offset =
                                            _getTargetOffset(
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
                                          _isScrollingToCategory =
                                              false;
                                        });
                                      },
                                    );
                                  },
                                ),
                              ),
                              // Pastki ajratuvchi chiziq
                              Container(
                                height: 1,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
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
                                const Icon(
                                    Icons.search_off_rounded,
                                    size: 56,
                                    color: AppColors.neutral300),
                                const SizedBox(height: 16),
                                Text('home.search_empty'.tr(),
                                    style: AppTextStyles.bodyMedium
                                        .copyWith(
                                            color:
                                                AppColors.neutral500)),
                              ],
                            ),
                          ),
                        );
                      }

                      return SliverPadding(
                        padding: const EdgeInsets.fromLTRB(
                            16, 16, 16, 120),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 0.68,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) {
                              final product = results[i];
                              return BlocBuilder<CartCubit,
                                  CartState>(
                                builder: (context, cartState) {
                                  final qty = cartState.items
                                      .where((item) =>
                                          item.product.slug ==
                                          product.slug)
                                      .fold<int>(0,
                                          (s, item) => s + item.quantity);
                                  return ProductCard(
                                    product: product,
                                    quantityInCart: qty,
                                    onTap: () => context.push(
                                        '/product/${product.slug}',
                                        extra: product),
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
                              childAspectRatio: 0.68,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (ctx, i) {
                                final product = catProducts[i];
                                return BlocBuilder<CartCubit,
                                    CartState>(
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
                                      onTap: () => context.push(
                                          '/product/${product.slug}',
                                          extra: product),
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
                    const SliverToBoxAdapter(
                        child: SizedBox(height: 120)),
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
                        color: Theme.of(context).brightness ==
                                Brightness.dark
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
                    color: isActive
                        ? AppColors.primary
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

/// Kategoriya tab — Laravel `nav-link-tab` stilida:
/// matn + pastki qizil chiziq (active), transition animatsiya.
class _CategoryTab extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryTab({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppColors.primary : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          title,
          style: AppTextStyles.labelSmall.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.neutral400 : AppColors.neutral600),
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
