import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pizza_strada/core/sdui/sdui.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_icons.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/core/utils/number_formatter.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/checkout/checkout_cubit.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/checkout/checkout_state.dart';
import 'package:pizza_strada/features/cart/presentation/widgets/order_type_bottom_sheet.dart';
import 'package:pizza_strada/features/home/presentation/bloc/home_cubit.dart';
import 'package:pizza_strada/features/home/presentation/widgets/header_location_pill.dart';

/// 📱 HomePage powered 100% by Server-Driven UI (SDUI)
/// Benchmarked against Dodo Pizza, Bellissimo, Uzum Tezkor, and Yandex Eats.
/// Compliant with Apple Guideline 2.5.2 & Google Play policies.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Widget _buildAppBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverAppBar(
      pinned: true,
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 16,
      title: Row(
        children: [
          Image.asset(
            'assets/icons/logo.png',
            height: 28,
            errorBuilder: (_, __, ___) => Text(
              'Strada',
              style: AppTextStyles.h3.copyWith(color: AppColors.primary),
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
                      builder: (_) => const OrderTypeBottomSheet(),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      actions: [
        BlocBuilder<CartCubit, CartState>(
          builder: (ctx, cartState) {
            final count = cartState.totalQuantity;
            return Stack(
              children: [
                IconButton(
                  icon: Icon(
                    AppIcons.cart,
                    color: isDark ? Colors.white : AppColors.neutral900,
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
                            fontWeight: FontWeight.w700,
                          ),
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
            return RefreshIndicator(
              onRefresh: () => context.read<HomeCubit>().init(forceRefresh: true),
              color: AppColors.primary,
              child: CustomScrollView(
                slivers: [
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
              ),
            );
          }

          if (state is HomeLoaded) {
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: SDUIRenderer(
                key: ValueKey('sdui_${state.sduiPage.versionUuid}'),
                page: state.sduiPage,
                selectedCategorySlug: state.selectedCategory,
                leadingSlivers: [_buildAppBar(context)],
                onRefresh: () => context.read<HomeCubit>().init(forceRefresh: true),
                onFilterCategory: (slug) => context.read<HomeCubit>().selectCategory(slug),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
      bottomNavigationBar: BlocBuilder<CartCubit, CartState>(
        builder: (context, cartState) {
          if (cartState.items.isEmpty) return const SizedBox.shrink();

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Material(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
                elevation: 4,
                shadowColor: AppColors.primary.withValues(alpha: 0.4),
                child: InkWell(
                  onTap: () => context.push('/cart'),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.shopping_bag_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${'cart.items_suffix'.tr(namedArgs: {'count': cartState.totalQuantity.toString()})} • ${NumberFormatter.formatSum(cartState.subtotal)} ${'common.currency'.tr()}',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'cart.floating_cart'.tr(),
                          style: AppTextStyles.labelMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white,
                          size: 13,
                        ),
                      ],
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
