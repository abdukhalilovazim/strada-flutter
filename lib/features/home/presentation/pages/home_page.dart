import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/core/theme/app_icons.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:pizza_strada/features/home/domain/entities/home_entities.dart';
import 'package:pizza_strada/features/home/presentation/bloc/home_cubit.dart';
import 'package:pizza_strada/features/home/presentation/widgets/product_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () => context.read<HomeCubit>().init(),
            color: AppColors.primary,
            child: CustomScrollView(
              slivers: [
                // App Bar
                SliverAppBar(
                  pinned: true,
                  backgroundColor: Colors.white,
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
                ),

                if (state is HomeLoading)
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  )
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
                  // Sliders - 100% width and support for text/button
                  if (state.sliders.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: SizedBox(
                          height: 200,
                          child: PageView.builder(
                            itemCount: state.sliders.length,
                            controller: PageController(viewportFraction: 0.92),
                            itemBuilder: (_, i) {
                              final slider = state.sliders[i];
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      CachedNetworkImage(
                                        imageUrl: slider.image,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => Container(color: AppColors.neutral100),
                                        errorWidget: (_, __, ___) => Container(
                                          color: AppColors.neutral100,
                                          child: const Icon(Icons.image_not_supported_outlined),
                                        ),
                                      ),
                                      // Dark overlay for text readability
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                            colors: [
                                              Colors.transparent,
                                              Colors.black.withOpacity(0.6),
                                            ],
                                          ),
                                        ),
                                      ),
                                      if (slider.caption != null)
                                        Positioned(
                                          left: 20,
                                          bottom: 20,
                                          right: 20,
                                          child: Text(
                                            slider.caption!,
                                            style: AppTextStyles.h3.copyWith(color: Colors.white),
                                          ),
                                        ),
                                      // InkWell for navigation if URL exists
                                      if (slider.buttonUrl != null && slider.buttonUrl!.isNotEmpty)
                                        Positioned.fill(
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: () async {
                                                final uri = Uri.tryParse(slider.buttonUrl!);
                                                if (uri != null && await canLaunchUrl(uri)) {
                                                  await launchUrl(uri);
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                  // Sticky Category chips (Removed categories title)


                  // Sticky Category chips
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _StickyCategoryDelegate(
                      child: Container(
                        color: Colors.white,
                        alignment: Alignment.centerLeft,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: state.categories.length,
                          itemBuilder: (_, i) {
                            final cat = state.categories[i];
                            final selected = state.selectedCategory == cat.slug;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(cat.title),
                                selected: selected,
                                onSelected: (_) => context.read<HomeCubit>().selectCategory(cat.slug),
                                selectedColor: AppColors.primary,
                                backgroundColor: Colors.white,
                                disabledColor: Colors.white,
                                showCheckmark: false,
                                side: BorderSide(
                                  color: selected ? AppColors.primary : AppColors.neutral200,
                                  width: 1,
                                ),
                                labelStyle: AppTextStyles.labelSmall.copyWith(
                                  color: selected ? Colors.white : AppColors.neutral700,
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

                  // Section title: Selected category name
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        state.categories
                            .cast<CategoryEntity>()
                            .firstWhere((c) => c.slug == state.selectedCategory, orElse: () => state.categories.first)
                            .title,
                        style: AppTextStyles.h3.copyWith(color: AppColors.neutral900),
                      ),
                    ),
                  ),

                  // Product grid
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.68,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) {
                          final product = state.products[i];
                          return BlocBuilder<CartCubit, CartState>(
                            builder: (context, cartState) {
                              // Calculate total quantity of this product (across all variants) in the cart
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
                        childCount: state.products.length,
                      ),
                    ),
                  ),
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
