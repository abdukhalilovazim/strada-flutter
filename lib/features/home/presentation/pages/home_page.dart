import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/core/theme/app_icons.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/cart_cubit.dart';
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
          return CustomScrollView(
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
                                    right: 8, top: 8,
                                    child: Container(
                                      width: 16, height: 16,
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

                      // Sliders - 100% width
                      if (state.sliders.isNotEmpty)
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 200,
                            child: PageView.builder(
                              itemCount: state.sliders.length,
                              itemBuilder: (_, i) {
                                return CachedNetworkImage(
                                  imageUrl: state.sliders[i].image,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  placeholder: (_, __) => Container(color: AppColors.neutral100),
                                );
                              },
                            ),
                          ),
                        ),

                      // Categories title
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                        sliver: SliverToBoxAdapter(
                          child: Text('Kategoriyalar', style: AppTextStyles.h3.copyWith(color: AppColors.neutral900)),
                        ),
                      ),

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
                                    backgroundColor: AppColors.neutral100,
                                    side: BorderSide.none,
                                    labelStyle: AppTextStyles.labelSmall.copyWith(
                                      color: selected ? Colors.white : AppColors.neutral700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),

                      // Section title
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                        sliver: SliverToBoxAdapter(
                          child: Text('Mahsulotlar', style: AppTextStyles.h3.copyWith(color: AppColors.neutral900)),
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
                            childAspectRatio: 0.72,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (ctx, i) {
                              final product = state.products[i];
                              return ProductCard(
                                product: product,
                                onTap: () => context.push('/product/${product.slug}', extra: product),
                                onAddTap: () => context.read<CartCubit>().addToCart(product),
                              );
                            },
                            childCount: state.products.length,
                          ),
                        ),
                      ),
                    ],
                  ],
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
