import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_dimensions.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/core/widgets/app_button.dart';
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
    if (widget.product != null && widget.product!.variants.isNotEmpty) {
      _selectedVariant = widget.product!.variants.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.product == null) {
      return const Scaffold(body: Center(child: Text("Product not found")));
    }

    final product = widget.product!;

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
                  
                  // Variants (Size selection)
                  if (product.variants.isNotEmpty) ...[
                    Text("O'lchamni tanlang", style: AppTextStyles.labelLarge),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      children: product.variants.map((v) {
                        final isSelected = _selectedVariant?.id == v.id;
                        return ChoiceChip(
                          label: Text("${v.title} - ${v.price.toInt()} UZS"),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedVariant = v);
                          },
                          selectedColor: AppColors.primary,
                          labelStyle: AppTextStyles.labelMedium.copyWith(
                            color: isSelected ? Colors.white : AppColors.neutral900,
                          ),
                          backgroundColor: AppColors.neutral100,
                          shape: RoundedRectangleBorder(borderRadius: AppDim.radiusMd),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Additional info
                  if (product.values.isNotEmpty) ...[
                    Text("Ma'lumot", style: AppTextStyles.labelLarge),
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
        padding: const EdgeInsets.all(AppDim.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          child: AppButton(
            text: "Savatga qo'shish - ${(_selectedVariant?.price ?? product.price).toInt()} UZS",
            onTap: () {
              context.read<CartCubit>().addToCart(product, variant: _selectedVariant);
              context.pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Savatga qo'shildi")),
              );
            },
          ),
        ),
      ),
    );
  }
}
