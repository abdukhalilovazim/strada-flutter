import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pizza_strada/core/sdui/sdui.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_icons.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:pizza_strada/features/home/presentation/bloc/home_cubit.dart';

/// 📱 HomePage powered 100% by Server-Driven UI (SDUI)
/// Compliant with Apple Guideline 2.5.2 & Google Play policies.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
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
              onRefresh: () => context.read<HomeCubit>().init(),
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
                            child: const Text('Qayta urinish'),
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
            return SDUIRenderer(
              page: state.sduiPage,
              selectedCategorySlug: state.selectedCategory,
              leadingSlivers: [_buildAppBar(context)],
              onRefresh: () => context.read<HomeCubit>().init(),
              onFilterCategory: (slug) => context.read<HomeCubit>().selectCategory(slug),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
