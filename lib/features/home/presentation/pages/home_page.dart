import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pizza_strada/core/services/deep_link_service.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_icons.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/core/utils/variant_localization_helper.dart';
import 'package:pizza_strada/core/widgets/strada_refresh_control.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/checkout/checkout_cubit.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/checkout/checkout_state.dart';
import 'package:pizza_strada/features/cart/presentation/widgets/order_type_bottom_sheet.dart';
import 'package:pizza_strada/features/home/domain/entities/home_entities.dart';
import 'package:pizza_strada/features/home/presentation/bloc/home_cubit.dart';
import 'package:pizza_strada/features/home/presentation/widgets/header_location_pill.dart';
import 'package:pizza_strada/features/home/presentation/widgets/product_card.dart';
import 'package:pizza_strada/features/home/presentation/widgets/product_detail_modal.dart';
import 'package:pizza_strada/core/di/injection.dart';
import 'package:pizza_strada/features/notifications/presentation/bloc/notifications_cubit.dart';
import 'package:shimmer/shimmer.dart';

/// 📱 HomePage powered 100% by Native Flutter UI & BLoC
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  bool _hasSearchText = false;
  bool _isSearchActive = false;
  bool _isProgrammaticScroll = false;
  final ValueNotifier<String?> _activeCategoryNotifier = ValueNotifier<String?>(null);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(_onFocusChanged);
    _scrollController.addListener(_onVerticalScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<HomeCubit>().loadSliders();
      }
    });
  }

  List<ProductEntity> _getProductsForCategory(
    CategoryEntity category,
    List<ProductEntity> allProducts,
  ) {
    final slug = category.slug;
    final id = category.id;
    final isSetCategory = slug == 'set-menus' || id == 999999;

    return allProducts.where((p) {
      if (isSetCategory) {
        return p.isSet || p.category?.slug == 'set-menus' || p.category?.id == 999999;
      }
      if (p.isSet) return false;
      return p.category?.slug == slug || (id != 0 && p.category?.id == id);
    }).toList();
  }

  double _calculateCategoryOffset(String slug, HomeLoaded state, double screenWidth) {
    if (state.categories.isEmpty) return 0.0;
    if (state.categories.first.slug == slug) return 0.0;

    final sliderHeight = state.sliders.isNotEmpty
        ? ((screenWidth * 0.85) / _HomeSliderBanner.aspectRatio + 8.0)
        : 0.0;

    final cardWidth = (screenWidth - 32 - 14) / 2;
    final cardHeight = cardWidth / 0.68;

    double offset = sliderHeight;
    bool isFirstRendered = true;

    for (final cat in state.categories) {
      if (cat.slug == slug) break;

      final products = _getProductsForCategory(cat, state.fullProducts);
      if (products.isEmpty) continue;

      final rows = (products.length + 1) ~/ 2;
      final headerHeight = isFirstRendered ? 14.0 : 87.0;
      final gridHeight = (rows * cardHeight) + (rows > 1 ? (rows - 1) * 14.0 : 0.0);
      offset += headerHeight + gridHeight;
      isFirstRendered = false;
    }

    return offset;
  }

  void _onVerticalScroll() {
    if (_isProgrammaticScroll || !_scrollController.hasClients) return;

    final state = context.read<HomeCubit>().state;
    if (state is! HomeLoaded || state.searchQuery.isNotEmpty) return;

    final currentOffset = _scrollController.offset;
    final screenWidth = MediaQuery.sizeOf(context).width;

    final sliderHeight = state.sliders.isNotEmpty
        ? ((screenWidth * 0.85) / _HomeSliderBanner.aspectRatio + 8.0)
        : 0.0;

    final cardWidth = (screenWidth - 32 - 14) / 2;
    final cardHeight = cardWidth / 0.68;

    double accumulated = sliderHeight;
    String? matchedSlug;
    bool isFirstRendered = true;

    for (final cat in state.categories) {
      final products = _getProductsForCategory(cat, state.fullProducts);
      if (products.isEmpty) continue;

      final rows = (products.length + 1) ~/ 2;
      final headerHeight = isFirstRendered ? 14.0 : 87.0;
      final gridHeight = (rows * cardHeight) + (rows > 1 ? (rows - 1) * 14.0 : 0.0);
      final sectionHeight = headerHeight + gridHeight;

      if (currentOffset >= accumulated - 35 && currentOffset < accumulated + sectionHeight - 35) {
        matchedSlug = cat.slug;
        break;
      }
      accumulated += sectionHeight;
      isFirstRendered = false;
    }

    matchedSlug ??= state.categories.firstOrNull?.slug;

    if (matchedSlug != null && matchedSlug != _activeCategoryNotifier.value) {
      _activeCategoryNotifier.value = matchedSlug;
    }
  }

  void _scrollToCategory(String slug) {
    final state = context.read<HomeCubit>().state;
    if (state is! HomeLoaded || !_scrollController.hasClients) return;

    final screenWidth = MediaQuery.sizeOf(context).width;
    final targetOffset = _calculateCategoryOffset(slug, state, screenWidth);

    _isProgrammaticScroll = true;
    _activeCategoryNotifier.value = slug;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final clampedTarget = targetOffset.clamp(0.0, maxScroll);

    _scrollController.animateTo(
      clampedTarget,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOutCubic,
    ).then((_) {
      _isProgrammaticScroll = false;
    });
  }

  void _onSearchChanged() {
    final hasText = _searchController.text.trim().isNotEmpty;
    if (hasText != _hasSearchText) {
      setState(() => _hasSearchText = hasText);
    }
  }

  void _onFocusChanged() {
    setState(() {
      if (!_searchFocusNode.hasFocus) {
        if (_searchController.text.trim().isEmpty) {
          _isSearchActive = false;
          _hasSearchText = false;
        }
      }
    });
  }

  void _openSearch() {
    HapticFeedback.lightImpact();
    setState(() {
      _isSearchActive = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchFocusNode.removeListener(_onFocusChanged);
    _scrollController.removeListener(_onVerticalScroll);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    _activeCategoryNotifier.dispose();
    super.dispose();
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 16,
      title: BlocBuilder<CheckoutCubit, CheckoutState>(
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
                builder: (_) => const OrderTypeBottomSheet(),
              );
            },
          );
        },
      ),
      actions: [
        IconButton(
          icon: Icon(
            Icons.search_rounded,
            color: isDark ? Colors.white : AppColors.neutral900,
            size: 24,
          ),
          tooltip: 'home.search_hint'.tr(),
          onPressed: _openSearch,
        ),
        IconButton(
          icon: Builder(
            builder: (context) {
              NotificationsCubit? notifCubit;
              try {
                notifCubit = context.watch<NotificationsCubit>();
              } catch (_) {
                try {
                  notifCubit = getIt<NotificationsCubit>();
                } catch (_) {}
              }

              final unreadCount = (notifCubit?.state is NotificationsLoaded)
                  ? (notifCubit!.state as NotificationsLoaded).unreadCount
                  : 0;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    color: isDark ? Colors.white : AppColors.neutral900,
                    size: 24,
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          onPressed: () async {
            HapticFeedback.lightImpact();
            await context.push('/notifications');
            if (context.mounted) {
              try {
                context.read<NotificationsCubit>().refresh();
              } catch (_) {
                try {
                  getIt<NotificationsCubit>().refresh();
                } catch (_) {}
              }
            }
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildFloatingSearchInput(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : const Color(0xFFE9ECEF),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: SafeArea(
        top: false,
        bottom: !_searchFocusNode.hasFocus,
        child: SizedBox(
          height: 44,
          child: TextField(
            key: const Key('home_search_input'),
            controller: _searchController,
            focusNode: _searchFocusNode,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.search,
            onChanged: (val) {
              context.read<HomeCubit>().search(val);
            },
            onSubmitted: (val) {
              context.read<HomeCubit>().search(val);
              _searchFocusNode.unfocus();
            },
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark ? Colors.white : AppColors.neutral900,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'home.search_hint'.tr(),
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.neutral400,
                fontSize: 13.5,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 20,
                color: AppColors.primary,
              ),
              suffixIcon: IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  size: 20,
                  color: AppColors.neutral500,
                ),
                tooltip: _hasSearchText ? 'Tozalash' : 'Yopish',
                onPressed: () {
                  HapticFeedback.lightImpact();
                  if (_hasSearchText) {
                    _searchController.clear();
                    context.read<HomeCubit>().search('');
                    setState(() => _hasSearchText = false);
                  } else {
                    _searchFocusNode.unfocus();
                    setState(() {
                      _isSearchActive = false;
                      _hasSearchText = false;
                    });
                  }
                },
              ),
              filled: true,
              fillColor: isDark ? AppColors.darkCard : const Color(0xFFF1F3F5),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark ? AppColors.darkBorder : const Color(0xFFE9ECEF),
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark ? AppColors.darkBorder : const Color(0xFFE9ECEF),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSliderBanner(List<SliderEntity> sliders, bool isSlidersLoading) {
    if (sliders.isEmpty && isSlidersLoading) {
      return const SliverToBoxAdapter(child: _HomeSliderShimmer());
    }
    if (sliders.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: _HomeSliderBanner(sliders: sliders),
    );
  }

  Widget _buildProductCardItem(BuildContext context, ProductEntity product) {
    return RepaintBoundary(
      child: BlocBuilder<CartCubit, CartState>(
        builder: (context, cartState) {
          final matchingItems = cartState.items.where((ci) => ci.product.slug == product.slug).toList();
          final quantity = matchingItems.fold<int>(0, (sum, ci) => sum + ci.quantity);
          final firstCartItem = matchingItems.firstOrNull;

          return ProductCard(
            product: product,
            quantityInCart: quantity,
            onTap: () {
              if (product.isSet) {
                context.push('/set/${product.slug}', extra: product);
                return;
              }
              final hasMultiple = product.variants.where((v) => VariantLocalizationHelper.localize(v.title).isNotEmpty).length > 1;
              if (hasMultiple) {
                ProductDetailModal.show(context, product);
              } else {
                context.push('/product/${product.slug}', extra: product);
              }
            },
            onAdd: () {
              if (product.isSet) {
                context.push('/set/${product.slug}', extra: product);
                return;
              }
              final hasMultiple = product.variants.where((v) => VariantLocalizationHelper.localize(v.title).isNotEmpty).length > 1;
              if (hasMultiple) {
                ProductDetailModal.show(context, product);
              } else {
                context.read<CartCubit>().addToCart(
                      product,
                      variant: product.variants.firstOrNull,
                    );
              }
            },
            onRemove: () {
              if (firstCartItem != null) {
                context.read<CartCubit>().updateQuantity(firstCartItem, -1);
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildProductGrid(List<ProductEntity> products) {
    if (products.isEmpty) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : const Color(0xFFF1F3F5),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.search_off_rounded,
                      size: 32,
                      color: AppColors.neutral400,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'home.search_empty'.tr(),
                  style: AppTextStyles.h4.copyWith(
                    color: isDark ? Colors.white : AppColors.neutral800,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'home.search_empty_desc'.tr(),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.neutral500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.68,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildProductCardItem(context, products[index]),
          childCount: products.length,
        ),
      ),
    );
  }

  List<Widget> _buildContinuousCatalogSlivers(
    BuildContext context,
    HomeLoaded state,
    bool isDark,
  ) {
    final slivers = <Widget>[
      StradaSliverRefreshControl(
        onRefresh: () async {
          try {
            context.read<NotificationsCubit>().refresh();
          } catch (_) {}
          await context.read<HomeCubit>().init(forceRefresh: true);
          if (context.mounted) {
            context.read<HomeCubit>().loadSliders();
          }
        },
      ),
    ];

    if (state.searchQuery.isNotEmpty) {
      slivers.add(_buildProductGrid(state.products));
      return slivers;
    }

    // 1. Promo Sliders Banner
    slivers.add(_buildSliderBanner(state.sliders, state.isSlidersLoading));

    // 2. Yopishqoq (Sticky) Kategoriya tanlash paneli
    slivers.add(
      SliverPersistentHeader(
        pinned: true,
        delegate: _StickyCategoryHeaderDelegate(
          child: ValueListenableBuilder<String?>(
            valueListenable: _activeCategoryNotifier,
            builder: (context, activeSlug, _) {
              return _HomeCategoryBar(
                categories: state.categories,
                selectedSlug: activeSlug ?? state.categories.firstOrNull?.slug,
                onSelect: (slug) {
                  if (slug != null) {
                    _scrollToCategory(slug);
                  }
                },
              );
            },
          ),
          height: 52.0,
        ),
      ),
    );

    // 3. Uzluksiz barcha kategoriyalar va ularning mahsulotlari (Continuous Catalog)
    bool isFirstCategorySection = true;

    for (final category in state.categories) {
      final categoryProducts = _getProductsForCategory(category, state.fullProducts);

      if (categoryProducts.isEmpty) continue;

      if (isFirstCategorySection) {
        // Eng birinchi kategoriya sarlavhasi chiqmaydi (yuqoridagi chip ko'rsatib turadi)
        slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 14)));
        isFirstCategorySection = false;
      } else {
        // Qolgan kategoriyalar uchun: full row line (ajratuvchi chiziq) + align start sarlavha
        slivers.add(
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: isDark
                        ? AppColors.neutral800
                        : AppColors.neutral200.withValues(alpha: 0.8),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    category.title,
                    style: AppTextStyles.h3.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: isDark ? Colors.white : AppColors.neutral900,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      // Kategoriya mahsulotlar panjarasi
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.68,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildProductCardItem(context, categoryProducts[index]),
              childCount: categoryProducts.length,
            ),
          ),
        ),
      );
    }

    // Pastki bo'sh joy (navigation bar va float tugmalar uchun)
    slivers.add(const SliverToBoxAdapter(child: SizedBox(height: 100)));

    return slivers;
  }

  Widget _buildHomeShimmer(BuildContext context, bool isDark) {
    return CustomScrollView(
      physics: const NeverScrollableScrollPhysics(),
      slivers: [
        const SliverToBoxAdapter(child: _HomeSliderShimmer()),
        const SliverToBoxAdapter(child: _HomeCategoriesShimmer()),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              childAspectRatio: 0.68,
            ),
            delegate: SliverChildBuilderDelegate(
              (_, __) => _ProductCardShimmer(isDark: isDark),
              childCount: 6,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: !_isSearchActive && !_hasSearchText,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_searchFocusNode.hasFocus) {
          _searchFocusNode.unfocus();
        }
        if (_hasSearchText) {
          _searchController.clear();
          context.read<HomeCubit>().search('');
        }
        setState(() {
          _isSearchActive = false;
          _hasSearchText = false;
        });
      },
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
        appBar: _buildAppBar(context),
        body: GestureDetector(
          onTap: () {
            if (_searchFocusNode.hasFocus) {
              _searchFocusNode.unfocus();
            }
          },
          behavior: HitTestBehavior.translucent,
          child: Stack(
            children: [
              Positioned.fill(
                child: BlocBuilder<HomeCubit, HomeState>(
                  builder: (context, state) {
                    if (state is HomeLoading) {
                      return _buildHomeShimmer(context, isDark);
                    }

                    if (state is HomeFailure) {
                      return CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        slivers: [
                          StradaSliverRefreshControl(
                            onRefresh: () async {
                              try {
                                context.read<NotificationsCubit>().refresh();
                              } catch (_) {}
                              await context.read<HomeCubit>().init(forceRefresh: true);
                              if (context.mounted) {
                                context.read<HomeCubit>().loadSliders();
                              }
                            },
                          ),
                          SliverFillRemaining(
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(AppIcons.wifiOff, size: 48, color: AppColors.neutral400),
                                  const SizedBox(height: 12),
                                  Text(
                                    state.message,
                                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral600),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () => context.read<HomeCubit>().init(),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: Text('common.retry'.tr()),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    if (state is HomeLoaded) {
                      return CustomScrollView(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        slivers: _buildContinuousCatalogSlivers(context, state, isDark),
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
              if (_isSearchActive || _hasSearchText)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildFloatingSearchInput(context, isDark),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 🎁 Promotional Slider Banner Carousel (1024x204 - 5:1 panorama format)
class _HomeSliderBanner extends StatefulWidget {
  final List<SliderEntity> sliders;

  const _HomeSliderBanner({required this.sliders});

  static const double aspectRatio = 1024.0 / 204.0;

  @override
  State<_HomeSliderBanner> createState() => _HomeSliderBannerState();
}

class _HomeSliderBannerState extends State<_HomeSliderBanner> {
  PageController? _pageController;
  Timer? _autoScrollTimer;
  static const int _kInfiniteMultiplier = 10000;
  double _lastFraction = 0.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _setupController();
  }

  void _setupController() {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = screenWidth * 0.85;
    const gap = 10.0;
    final targetFraction = ((cardWidth + gap) / screenWidth).clamp(0.80, 0.90);

    if (_pageController == null || (_lastFraction - targetFraction).abs() > 0.01) {
      _pauseAutoScroll();
      _pageController?.dispose();

      _lastFraction = targetFraction;
      final initialPage = widget.sliders.length > 1
          ? (_kInfiniteMultiplier ~/ 2) - ((_kInfiniteMultiplier ~/ 2) % widget.sliders.length)
          : 0;

      _pageController = PageController(
        initialPage: initialPage,
        viewportFraction: targetFraction,
      );

      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    if (widget.sliders.length <= 1) return;
    _autoScrollTimer?.cancel();
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || _pageController == null || !_pageController!.hasClients) return;
      _pageController!.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _pauseAutoScroll() {
    _autoScrollTimer?.cancel();
    _autoScrollTimer = null;
  }

  @override
  void didUpdateWidget(covariant _HomeSliderBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sliders.length != widget.sliders.length) {
      _pauseAutoScroll();
      _pageController?.dispose();
      _pageController = null;
      _setupController();
    }
  }

  @override
  void dispose() {
    _pauseAutoScroll();
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sliders.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = screenWidth * 0.85;
    final cardHeight = cardWidth / _HomeSliderBanner.aspectRatio;

    if (widget.sliders.length == 1) {
      final singleWidth = screenWidth - 32;
      final singleHeight = singleWidth / _HomeSliderBanner.aspectRatio;
      return Container(
        color: isDark ? AppColors.darkSurface : Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
        child: SizedBox(
          width: singleWidth,
          height: singleHeight,
          child: _SliderBannerCard(
            slider: widget.sliders.first,
            width: singleWidth,
            height: singleHeight,
            isDark: isDark,
          ),
        ),
      );
    }

    return Container(
      color: isDark ? AppColors.darkSurface : Colors.white,
      padding: const EdgeInsets.only(top: 2, bottom: 6),
      child: SizedBox(
        height: cardHeight,
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification is ScrollStartNotification) {
              _pauseAutoScroll();
            } else if (notification is ScrollEndNotification) {
              _startAutoScroll();
            }
            return false;
          },
          child: Padding(
            padding: const EdgeInsets.only(left: 16),
            child: PageView.builder(
              controller: _pageController,
              padEnds: false,
              clipBehavior: Clip.none,
              physics: const BouncingScrollPhysics(),
              itemBuilder: (context, index) {
                final sliderIndex = index % widget.sliders.length;
                final slider = widget.sliders[sliderIndex];
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _SliderBannerCard(
                      slider: slider,
                      width: cardWidth,
                      height: cardHeight,
                      isDark: isDark,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _SliderBannerCard extends StatelessWidget {
  final SliderEntity slider;
  final double width;
  final double height;
  final bool isDark;

  const _SliderBannerCard({
    required this.slider,
    required this.width,
    required this.height,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        if (slider.link != null && slider.link!.trim().isNotEmpty) {
          DeepLinkService.instance.handleStringLink(slider.link!);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: width,
        height: height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CachedNetworkImage(
            imageUrl: slider.imageUrl,
            width: width,
            height: height,
            fit: BoxFit.fill,
            placeholder: (_, __) => Container(
              color: isDark ? AppColors.darkCard : const Color(0xFFF1F3F5),
            ),
            errorWidget: (_, __, ___) => Container(
              color: isDark ? AppColors.darkCard : const Color(0xFFF1F3F5),
              alignment: Alignment.center,
              child: const Icon(Icons.image_outlined, color: AppColors.neutral400, size: 28),
            ),
          ),
        ),
      ),
    );
  }
}

/// 🏷️ Native Sticky Category Bar
class _HomeCategoryBar extends StatefulWidget {
  final List<CategoryEntity> categories;
  final String? selectedSlug;
  final ValueChanged<String?> onSelect;

  const _HomeCategoryBar({
    required this.categories,
    required this.selectedSlug,
    required this.onSelect,
  });

  @override
  State<_HomeCategoryBar> createState() => _HomeCategoryBarState();
}

class _HomeCategoryBarState extends State<_HomeCategoryBar> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant _HomeCategoryBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedSlug != widget.selectedSlug && widget.selectedSlug != null) {
      _scrollToActiveChip();
    }
  }

  void _scrollToActiveChip() {
    if (!_scrollController.hasClients) return;
    final index = widget.categories.indexWhere((c) => c.slug == widget.selectedSlug);
    if (index >= 0) {
      final screenWidth = MediaQuery.sizeOf(context).width;
      final targetOffset = (index * 96.0) - (screenWidth / 2) + 48.0;
      final maxScroll = _scrollController.position.maxScrollExtent;
      _scrollController.animateTo(
        targetOffset.clamp(0.0, maxScroll),
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.neutral800 : AppColors.neutral200.withValues(alpha: 0.6),
            width: 0.5,
          ),
        ),
      ),
      height: 52,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: widget.categories.length,
        itemBuilder: (ctx, i) {
          final cat = widget.categories[i];
          final isSelected = widget.selectedSlug == cat.slug;

          return Center(
            child: Padding(
              padding: EdgeInsets.only(right: i == widget.categories.length - 1 ? 0 : 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.onSelect(cat.slug);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 38,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? AppColors.darkCard : const Color(0xFFF1F3F5)),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      cat.title,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: isSelected
                            ? Colors.white
                            : (isDark ? AppColors.neutral300 : AppColors.neutral800),
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 13,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StickyCategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;

  _StickyCategoryHeaderDelegate({
    required this.child,
    required this.height,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => child;

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(covariant _StickyCategoryHeaderDelegate oldDelegate) =>
      oldDelegate.child != child || oldDelegate.height != height;
}

/// 💫 Banner Slider Shimmer Skeleton
class _HomeSliderShimmer extends StatelessWidget {
  const _HomeSliderShimmer();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE8ECEF);
    final highlightColor = isDark ? const Color(0xFF3D3D3D) : const Color(0xFFF8F9FA);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final cardWidth = screenWidth * 0.85;
    final cardHeight = cardWidth / _HomeSliderBanner.aspectRatio;

    return Container(
      color: isDark ? AppColors.darkSurface : Colors.white,
      padding: const EdgeInsets.only(top: 2, bottom: 6),
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: SizedBox(
          height: cardHeight,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 2,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (ctx, i) => Container(
              width: cardWidth,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 🏷️ Categories Shimmer Skeleton
class _HomeCategoriesShimmer extends StatelessWidget {
  const _HomeCategoriesShimmer();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE8ECEF);
    final highlightColor = isDark ? const Color(0xFF3D3D3D) : const Color(0xFFF8F9FA);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: List.generate(
            4,
            (i) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Container(
                width: 76 + (i * 14.0),
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 🍕 Product Card Shimmer Skeleton
class _ProductCardShimmer extends StatelessWidget {
  final bool isDark;
  const _ProductCardShimmer({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final baseColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE8ECEF);
    final highlightColor = isDark ? const Color(0xFF3D3D3D) : const Color(0xFFF8F9FA);

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: 110,
              height: 14,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7),
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 70,
              height: 12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 60,
                  height: 16,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

