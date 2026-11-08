import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_icons.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/core/widgets/strada_refresh_control.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/checkout/checkout_cubit.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/checkout/checkout_state.dart';
import 'package:pizza_strada/features/cart/presentation/widgets/order_type_bottom_sheet.dart';
import 'package:pizza_strada/features/home/domain/entities/home_entities.dart';
import 'package:pizza_strada/features/home/presentation/bloc/home_cubit.dart';
import 'package:pizza_strada/features/home/presentation/pages/story_viewer_page.dart';
import 'package:pizza_strada/features/home/presentation/widgets/header_location_pill.dart';
import 'package:pizza_strada/features/home/presentation/widgets/product_card.dart';
import 'package:pizza_strada/features/home/presentation/widgets/product_detail_modal.dart';
import 'package:pizza_strada/core/di/injection.dart';
import 'package:pizza_strada/features/notifications/presentation/bloc/notifications_cubit.dart';

/// 📱 HomePage powered 100% by Native Flutter UI & BLoC
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _hasSearchText = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(() => setState(() {}));
  }

  void _onSearchChanged() {
    final hasText = _searchController.text.trim().isNotEmpty;
    if (hasText != _hasSearchText) {
      setState(() => _hasSearchText = hasText);
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Widget _buildAppBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverAppBar(
      pinned: true,
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

  Widget _buildSearchBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverToBoxAdapter(
      child: Container(
        color: isDark ? AppColors.darkSurface : Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: SizedBox(
          height: 50,
          child: TextField(
            key: const Key('home_search_input'),
            controller: _searchController,
            focusNode: _searchFocusNode,
            autocorrect: false,
            enableSuggestions: false,
            spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
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
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 22,
                color: _searchFocusNode.hasFocus ? AppColors.primary : AppColors.neutral400,
              ),
              suffixIcon: _hasSearchText
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.neutral500),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _searchController.clear();
                        context.read<HomeCubit>().search('');
                        _searchFocusNode.unfocus();
                      },
                    )
                  : null,
              filled: true,
              fillColor: isDark ? AppColors.darkCard : const Color(0xFFF1F3F5),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark ? AppColors.darkBorder : Colors.transparent,
                  width: 1.2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark ? AppColors.darkBorder : Colors.transparent,
                  width: 1.2,
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

  Widget _buildStories(List<StoryEntity> stories) {
    if (stories.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverToBoxAdapter(
      child: _HomeStoriesBar(
        stories: stories,
        onStoryTap: (story, index) => _openStoryViewer(context, stories, index),
      ),
    );
  }

  void _openStoryViewer(BuildContext context, List<StoryEntity> stories, int index) {
    HapticFeedback.lightImpact();
    Navigator.of(context, rootNavigator: true).push(
      PageRouteBuilder(
        opaque: false,
        fullscreenDialog: true,
        barrierColor: Colors.black,
        pageBuilder: (context, _, __) => StoryViewerPage(
          stories: stories,
          initialStoryIndex: index,
        ),
        transitionsBuilder: (context, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  Widget _buildCategoryBar(List<CategoryEntity> categories, String? selectedSlug) {
    if (categories.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

    return SliverPersistentHeader(
      pinned: true,
      delegate: _StickyCategoryHeaderDelegate(
        child: _HomeCategoryBar(
          categories: categories,
          selectedSlug: selectedSlug,
          onSelect: (slug) {
            context.read<HomeCubit>().selectCategory(slug);
          },
        ),
        height: 52.0,
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
          (context, index) {
            final product = products[index];
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
                      if (product.variants.length > 1) {
                        ProductDetailModal.show(context, product);
                      } else {
                        context.push('/product/${product.slug}', extra: product);
                      }
                    },
                    onAdd: () {
                      if (product.variants.length > 1) {
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
          },
          childCount: products.length,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          if (state is HomeLoading) {
            return CustomScrollView(
              slivers: [
                _buildAppBar(context),
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
              ],
            );
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
                  },
                ),
                _buildAppBar(context),
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
                  },
                ),
                _buildAppBar(context),
                _buildSearchBar(context),
                if (state.searchQuery.isEmpty) ...[
                  _buildStories(state.stories),
                  _buildCategoryBar(state.categories, state.selectedCategory),
                ],
                _buildProductGrid(state.products),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

/// 📱 Native Stories Bar (Instagram / Dodo Pizza uslubidagi Storislar)
class _HomeStoriesBar extends StatelessWidget {
  final List<StoryEntity> stories;
  final void Function(StoryEntity story, int index) onStoryTap;

  const _HomeStoriesBar({
    required this.stories,
    required this.onStoryTap,
  });

  @override
  Widget build(BuildContext context) {
    if (stories.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: SizedBox(
        height: 80,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: stories.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final story = stories[index];
            return _StoryItem(
              story: story,
              isDark: isDark,
              onTap: () => onStoryTap(story, index),
            );
          },
        ),
      ),
    );
  }
}

class _StoryItem extends StatelessWidget {
  final StoryEntity story;
  final bool isDark;
  final VoidCallback onTap;

  const _StoryItem({
    required this.story,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasUnread = !story.isViewed;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(37),
      child: Center(
        child: Container(
          width: 72,
          height: 72,
          padding: const EdgeInsets.all(2.5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: hasUnread
                ? const LinearGradient(
                    colors: [
                      AppColors.primary,
                      Color(0xFFFF7A00),
                      Color(0xFFFFB800),
                    ],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  )
                : null,
            border: !hasUnread
                ? Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.neutral300,
                    width: 1.5,
                  )
                : null,
          ),
          child: Container(
            padding: const EdgeInsets.all(2.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? AppColors.darkSurface : Colors.white,
            ),
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: story.previewImage,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  color: isDark ? AppColors.darkCard : const Color(0xFFF1F3F5),
                ),
                errorWidget: (_, __, ___) => Container(
                  color: isDark ? AppColors.darkCard : const Color(0xFFF1F3F5),
                  child: const Icon(Icons.local_pizza_rounded, color: AppColors.primary, size: 28),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 🏷️ Native Sticky Category Bar
class _HomeCategoryBar extends StatelessWidget {
  final List<CategoryEntity> categories;
  final String? selectedSlug;
  final ValueChanged<String?> onSelect;

  const _HomeCategoryBar({
    required this.categories,
    required this.selectedSlug,
    required this.onSelect,
  });

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
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (ctx, i) {
          final cat = categories[i];
          final isSelected = selectedSlug == cat.slug;

          return Center(
            child: Padding(
              padding: EdgeInsets.only(right: i == categories.length - 1 ? 0 : 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSelect(cat.slug);
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
