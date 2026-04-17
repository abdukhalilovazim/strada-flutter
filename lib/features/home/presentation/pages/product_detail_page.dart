import 'package:easy_localization/easy_localization.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_dimensions.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/core/utils/number_formatter.dart';
import 'package:pizza_strada/core/widgets/app_button.dart';
import 'package:pizza_strada/core/theme/app_icons.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:pizza_strada/features/home/domain/entities/home_entities.dart';

class ProductDetailPage extends StatefulWidget {
  final String slug;
  final ProductEntity? product;

  const ProductDetailPage({super.key, required this.slug, this.product});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  VariantEntity? _selectedVariant;

  @override
  void initState() {
    super.initState();
    // Point 7: default tanlanmagan bo'lishi kerak.
    // Point 5: agar option 1 ta bo'lsa uni ko'rsatish shart emas.
    if (widget.product != null && widget.product!.variants.length == 1) {
      _selectedVariant = widget.product!.variants.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.product == null) {
      return Scaffold(body: Center(child: Text('error.not_found'.tr())));
    }

    final product = widget.product!;
    final hasVariants = product.variants.length > 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: CachedNetworkImage(
                imageUrl: product.photo,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: AppColors.neutral100),
                errorWidget: (_, __, ___) => const Icon(AppIcons.pizza, size: 64, color: AppColors.neutral200),
              ),
            ),
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => context.pop(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppDim.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.title, style: AppTextStyles.h2),
                  const SizedBox(height: 8),
                  if (product.description != null)
                    Text(
                      product.description!,
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral600),
                    ),
                  const SizedBox(height: 24),
                  
                  // Variants (Size selection) - Point 5: 1 tadan ko'p bo'lsa ko'rsatamiz
                  if (hasVariants) ...[
                    Text('product.size'.tr(), style: AppTextStyles.labelLarge),
                    const SizedBox(height: 12),
                    // Point 1 & 7: Scroll bo'lmasligi kerak va kichikroq UI
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: product.variants.map((v) {
                        final isSelected = _selectedVariant?.id == v.id;
                        return InkWell(
                          onTap: () => setState(() => _selectedVariant = v),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : AppColors.neutral100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.neutral200,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  v.title,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: isSelected ? Colors.white : AppColors.neutral900,
                                  ),
                                ),
                                Text(
                                  "${NumberFormatter.formatSum(v.price)} ${'product.price_suffix'.tr()}",
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: isSelected ? Colors.white70 : AppColors.neutral400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Additional info
                  if (product.values.isNotEmpty) ...[
                    Text('product.info'.tr(), style: AppTextStyles.labelLarge),
                    const SizedBox(height: 12),
                    ...product.values.map((kv) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(kv.key, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral400)),
                          Text(kv.value, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral900)),
                        ],
                      ),
                    )),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppDim.lg, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          child: AppButton(
            text: _selectedVariant != null 
                ? "${'product.add_to_cart'.tr()} - ${NumberFormatter.formatSum(_selectedVariant!.price)} UZS"
                : 'product.add_to_cart'.tr(),
            onTap: () {
              // Point 2 & 7: Savatga qo'shish uchun tanlash shart
              if (hasVariants && _selectedVariant == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('product.select_variant_error'.tr()),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }

              context.read<CartCubit>().addToCart(product, variant: _selectedVariant);
              context.pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('product.added'.tr())),
              );
            },
          ),
        ),
      ),
    );
  }
}
