import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/cart_cubit.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text("cart.title".tr()),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: BlocBuilder<CartCubit, CartState>(
        builder: (context, state) {
          if (state.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_cart_outlined, size: 80, color: AppColors.neutral200),
                  const SizedBox(height: 16),
                  Text("cart.empty".tr(), style: AppTextStyles.bodyLarge.copyWith(color: AppColors.neutral400)),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: () => context.go('/home'),
                      child: Text("auth.continue".tr()),
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.items.length,
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: item.product.thumbnail,
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(color: AppColors.neutral100),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item.product.title, style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                                if (item.variant != null)
                                  Text(item.variant!.title, style: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral400)),
                                const SizedBox(height: 8),
                                Text("${item.totalPrice.toInt()} so'm", style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w800)),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: AppColors.neutral400),
                                onPressed: () => context.read<CartCubit>().updateQuantity(item, -1),
                              ),
                              Text("${item.quantity}", style: AppTextStyles.labelLarge),
                              IconButton(
                                icon: const Icon(Icons.add_circle_rounded, color: AppColors.primary),
                                onPressed: () => context.read<CartCubit>().updateQuantity(item, 1),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -4)),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("cart.total".tr(), style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700)),
                          Text("${state.subtotal.toInt()} so'm", style: AppTextStyles.h2.copyWith(color: AppColors.primary)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () => context.push('/checkout'),
                          child: Text("cart.checkout".tr()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
