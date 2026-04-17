import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/core/theme/app_icons.dart';
import 'package:pizza_strada/core/utils/number_formatter.dart';
import 'package:pizza_strada/features/home/domain/entities/home_entities.dart';

class ProductCard extends StatelessWidget {
  final ProductEntity product;
  final VoidCallback onTap;
  /// Called with the selected variant (or null if no variants)
  final void Function(VariantEntity? variant) onAddTap;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onAddTap,
  });

  void _handleAdd(BuildContext context) {
    if (product.variants.length <= 1) {
      // No choice needed — add directly (with the single variant if present)
      onAddTap(product.variants.isNotEmpty ? product.variants.first : null);
      return;
    }

    // Multiple variants — show bottom sheet to pick one
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _VariantPickerSheet(product: product, onPick: onAddTap),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // ── Full card content (not tappable by itself)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                CachedNetworkImage(
                  imageUrl: product.photo,
                  height: 130,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: 130,
                    color: AppColors.neutral100,
                  ),
                  errorWidget: (_, __, ___) => Container(
                    height: 130,
                    color: AppColors.neutral100,
                    child: const Icon(AppIcons.pizza, size: 36, color: AppColors.neutral200),
                  ),
                ),

                // Info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Title + description
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.neutral900,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (product.description != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                product.description!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodyExtraSmall
                                    .copyWith(color: AppColors.neutral500),
                              ),
                            ],
                          ],
                        ),

                        // Price row (right-side button handled below via Stack)
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                "${NumberFormatter.formatSum(product.price)} so'm",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            // Placeholder so text doesn't go under the button
                            const SizedBox(width: 36),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ── Navigation InkWell (covers everything except the + button area)
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),

            // ── Add button (highest z-order — always on top)
            Positioned(
              right: 8,
              bottom: 8,
              child: Material(
                color: AppColors.primaryLight,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _handleAdd(context),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.add_rounded, color: AppColors.primary, size: 18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet for picking a variant before adding to cart
class _VariantPickerSheet extends StatefulWidget {
  final ProductEntity product;
  final void Function(VariantEntity? variant) onPick;
  const _VariantPickerSheet({required this.product, required this.onPick});

  @override
  State<_VariantPickerSheet> createState() => _VariantPickerSheetState();
}

class _VariantPickerSheetState extends State<_VariantPickerSheet> {
  VariantEntity? _selected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.neutral200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Product title
          Text(widget.product.title, style: AppTextStyles.h3),
          const SizedBox(height: 4),
          Text(
            'product.size'.tr(),
            style: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral500),
          ),
          const SizedBox(height: 16),

          // Variant chips
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: widget.product.variants.map((v) {
              final isSelected = _selected?.id == v.id;
              return GestureDetector(
                onTap: () => setState(() => _selected = v),
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
                        "${NumberFormatter.formatSum(v.price)} so'm",
                        style: AppTextStyles.bodyExtraSmall.copyWith(
                          color: isSelected ? Colors.white70 : AppColors.neutral500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Confirm button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _selected == null
                  ? null
                  : () {
                      Navigator.pop(context);
                      widget.onPick(_selected);
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.neutral200,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                'product.add_to_cart'.tr(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
