import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../features/cart/presentation/bloc/cart_cubit.dart';
import '../../../../features/cart/presentation/bloc/checkout/checkout_cubit.dart';
import '../../../../features/cart/presentation/bloc/checkout/checkout_state.dart';
import '../../../../features/home/presentation/bloc/home_cubit.dart';
import '../../../services/analytics_service.dart';
import '../../../services/smart_recommendation_engine.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../utils/number_formatter.dart';
import '../../../utils/variant_localization_helper.dart';
import '../../../widgets/pizza_image_placeholder.dart';
import '../../models/section_model.dart';
import '../../registry/action_dispatcher.dart';

/// 📍 Savat: Yetkazish filiali va vaqti (Delivery Info Card) - Yashirilgan (Savatchada location ko'rsatilmaydi)
class SDUICartDeliveryInfoComponent extends StatelessWidget {
  final SDUISectionModel section;
  final SDUIActionHandler onAction;

  const SDUICartDeliveryInfoComponent({
    super.key,
    required this.section,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

/// 🛍 Savat: Mahsulotlar ro'yxati (Cart Items List)
class SDUICartItemListComponent extends StatelessWidget {
  final SDUISectionModel section;
  final SDUIActionHandler onAction;

  const SDUICartItemListComponent({
    super.key,
    required this.section,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<CartCubit, CartState>(
      builder: (context, cartState) {
        if (cartState.items.isEmpty) {
          return const SizedBox.shrink();
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cartState.items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = cartState.items[index];
            final itemKey = '${item.product.slug}_${item.variant?.id ?? 0}';

            return Dismissible(
              key: ValueKey('cart_item_$itemKey'),
              direction: DismissDirection.horizontal,
              background: Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(left: 20),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
              ),
              secondaryBackground: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
              ),
              onDismissed: (_) {
                HapticFeedback.mediumImpact();
                context.read<CartCubit>().removeFromCart(item);
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.neutral200.withValues(alpha: 0.7),
                  ),
                  boxShadow: AppColors.softShadow(isDark),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 72,
                        height: 72,
                        color: isDark ? AppColors.neutral800 : const Color(0xFFF8F9FA),
                        padding: const EdgeInsets.all(4),
                        child: item.product.hasValidImage
                            ? CachedNetworkImage(
                                imageUrl: item.product.validImageUrl,
                                fit: BoxFit.contain,
                                placeholder: (_, __) => Container(color: Colors.transparent),
                                errorWidget: (_, __, ___) => const PizzaImagePlaceholder(fit: BoxFit.contain),
                              )
                            : const PizzaImagePlaceholder(fit: BoxFit.contain),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.product.title,
                            style: AppTextStyles.h4.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : AppColors.neutral900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (item.variant != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              VariantLocalizationHelper.localize(item.variant!.title),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.neutral500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Text(
                            '${NumberFormatter.formatSum(item.totalPrice.toInt())} ${'common.currency'.tr()}',
                            style: AppTextStyles.priceMedium.copyWith(
                              color: AppColors.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Quantity stepper
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.neutral800 : const Color(0xFFF1F3F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            onTap: () => context.read<CartCubit>().updateQuantity(item, -1),
                            borderRadius: BorderRadius.circular(8),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              child: Icon(Icons.remove_rounded, size: 16),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '${item.quantity}',
                              style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          InkWell(
                            onTap: () => context.read<CartCubit>().updateQuantity(item, 1),
                            borderRadius: BorderRadius.circular(8),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              child: Icon(Icons.add_rounded, size: 16, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// 📦 Savat bo'sh bo'lgandagi card (Empty Cart Card)
class SDUIEmptyCartComponent extends StatelessWidget {
  final SDUISectionModel section;
  final SDUIActionHandler onAction;

  const SDUIEmptyCartComponent({
    super.key,
    required this.section,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<CartCubit, CartState>(
      builder: (context, cartState) {
        if (cartState.items.isNotEmpty) return const SizedBox.shrink();

        final props = section.properties;
        final title = props['title']?.toString() ?? 'cart.empty'.tr();
        final subtitle = props['subtitle']?.toString() ?? 'cart.empty_subtitle'.tr();
        final buttonText = props['button_text']?.toString() ?? 'cart.go_home'.tr();

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.neutral800 : AppColors.neutral100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shopping_bag_outlined,
                  size: 42,
                  color: AppColors.neutral400,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: AppTextStyles.h3.copyWith(
                  color: isDark ? Colors.white : AppColors.neutral900,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral500),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  if (section.action != null) {
                    onAction(section.action!);
                  } else {
                    context.go('/home');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(buttonText),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 🥫 Savat: Qo'shimcha takliflar (Upsell Recommendations Slider)
class SDUIUpsellSliderComponent extends StatelessWidget {
  final SDUISectionModel section;
  final SDUIActionHandler onAction;

  const SDUIUpsellSliderComponent({
    super.key,
    required this.section,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<CartCubit, CartState>(
      builder: (context, cartState) {
        if (cartState.items.isEmpty) return const SizedBox.shrink();

        return BlocBuilder<HomeCubit, HomeState>(
          builder: (context, homeState) {
            if (homeState is! HomeLoaded) return const SizedBox.shrink();

            final match = SmartRecommendationEngine.resolve(
              cartItems: cartState.items,
              allProducts: homeState.fullProducts,
              localeCode: context.locale.languageCode,
            );

            if (match.isEmpty) return const SizedBox.shrink();

            final title = section.properties['title']?.toString() ?? match.title;

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : const Color(0xFFF8F9FA),
                border: Border.symmetric(
                  horizontal: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.neutral200,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      title,
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: isDark ? Colors.white : AppColors.neutral900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 156,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      itemCount: match.products.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, i) {
                        final product = match.products[i];
                        return Container(
                          width: 115,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.neutral200,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Image with Floating '+' button (EVOS style)
                              Expanded(
                                flex: 5,
                                child: Stack(
                                  children: [
                                    Container(
                                      width: double.infinity,
                                      height: double.infinity,
                                      decoration: BoxDecoration(
                                        color: isDark ? AppColors.neutral800 : const Color(0xFFF8F9FA),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      alignment: Alignment.center,
                                      child: product.hasValidImage
                                          ? CachedNetworkImage(
                                              imageUrl: product.validImageUrl,
                                              fit: BoxFit.contain,
                                            )
                                          : const Icon(Icons.fastfood_rounded, color: AppColors.primary, size: 28),
                                    ),
                                    Positioned(
                                      bottom: 4,
                                      right: 4,
                                      child: Material(
                                        color: isDark ? AppColors.darkCard : Colors.white,
                                        shape: const CircleBorder(),
                                        elevation: 2,
                                        shadowColor: Colors.black.withValues(alpha: 0.2),
                                        child: InkWell(
                                          customBorder: const CircleBorder(),
                                          onTap: () {
                                            HapticFeedback.lightImpact();
                                            context.read<CartCubit>().addToCart(product);
                                          },
                                          child: Container(
                                            width: 26,
                                            height: 26,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                                                width: 1,
                                              ),
                                            ),
                                            alignment: Alignment.center,
                                            child: Icon(
                                              Icons.add_rounded,
                                              size: 17,
                                              color: isDark ? Colors.white : AppColors.neutral900,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              // Price (Bold)
                              Text(
                                '${NumberFormatter.formatSum(product.price.toInt())} ${'common.currency'.tr()}',
                                style: AppTextStyles.priceSmall.copyWith(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : AppColors.neutral900,
                                ),
                                maxLines: 1,
                              ),
                              const SizedBox(height: 2),
                              // Title
                              Text(
                                product.title,
                                style: AppTextStyles.labelSmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                  color: isDark ? AppColors.neutral300 : AppColors.neutral700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// 🎟 Savat: Promokod kiritish (Promo Code Card)
class SDUIPromoCodeComponent extends StatefulWidget {
  final SDUISectionModel section;
  final SDUIActionHandler onAction;

  const SDUIPromoCodeComponent({
    super.key,
    required this.section,
    required this.onAction,
  });

  @override
  State<SDUIPromoCodeComponent> createState() => _SDUIPromoCodeComponentState();
}

class _SDUIPromoCodeComponentState extends State<SDUIPromoCodeComponent> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final props = widget.section.properties;
    final placeholder = props['placeholder']?.toString() ?? 'Promokodni kiriting';
    final buttonText = props['button_text']?.toString() ?? 'Qo\'llash';

    return BlocBuilder<CartCubit, CartState>(
      builder: (context, cartState) {
        if (cartState.items.isEmpty) return const SizedBox.shrink();

        return BlocConsumer<CheckoutCubit, CheckoutState>(
          listenWhen: (prev, curr) =>
              prev.promoError != curr.promoError ||
              prev.appliedPromoCode != curr.appliedPromoCode,
          listener: (context, checkoutState) {
            if (checkoutState.promoError != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(checkoutState.promoError!),
                  backgroundColor: AppColors.error,
                ),
              );
              context.read<CheckoutCubit>().clearPromo();
            } else if (checkoutState.appliedPromoCode != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${'cart.promo_activated'.tr()}: ${checkoutState.appliedPromoCode}'),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          },
          builder: (context, checkoutState) {
            final isApplied = checkoutState.appliedPromoCode != null;
            final isLoading = checkoutState.loadingPromo;

            return Container(
              margin: const EdgeInsets.fromLTRB(16, 6, 16, 8),
              child: isApplied
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.4),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.success,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'cart.promo_activated'.tr(),
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11.5,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  checkoutState.appliedPromoCode!,
                                  style: AppTextStyles.labelLarge.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: isDark ? Colors.white : AppColors.neutral900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              _controller.clear();
                              context.read<CheckoutCubit>().clearPromo();
                            },
                            icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.error),
                            label: Text(
                              'common.cancel'.tr(),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.error,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              minimumSize: Size.zero,
                            ),
                          ),
                        ],
                      ),
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 50,
                            child: TextField(
                              controller: _controller,
                              textCapitalization: TextCapitalization.characters,
                              textInputAction: TextInputAction.done,
                              style: AppTextStyles.labelMedium.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                fontSize: 14,
                                color: isDark ? Colors.white : AppColors.neutral900,
                              ),
                              onChanged: (_) => setState(() {}),
                              onSubmitted: (code) {
                                if (code.trim().isNotEmpty) {
                                  context.read<CheckoutCubit>().applyPromo(code.trim(), cartState.subtotal);
                                }
                              },
                              decoration: InputDecoration(
                                labelText: 'Promokod',
                                labelStyle: AppTextStyles.bodySmall.copyWith(
                                  color: isDark ? AppColors.neutral400 : AppColors.neutral500,
                                  fontSize: 13,
                                ),
                                hintText: placeholder,
                                hintStyle: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.neutral400,
                                  fontSize: 13,
                                ),
                                prefixIcon: const Icon(
                                  Icons.confirmation_number_outlined,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                suffixIcon: _controller.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.neutral400),
                                        onPressed: () {
                                          HapticFeedback.lightImpact();
                                          _controller.clear();
                                          setState(() {});
                                        },
                                      )
                                    : null,
                                filled: true,
                                fillColor: isDark ? AppColors.darkCard : Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: isDark ? AppColors.darkBorder : AppColors.neutral200,
                                    width: 1.2,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: isDark ? AppColors.darkBorder : AppColors.neutral200,
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
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: (isLoading || _controller.text.trim().isEmpty)
                                ? null
                                : () {
                                    HapticFeedback.lightImpact();
                                    final code = _controller.text.trim();
                                    if (code.isNotEmpty) {
                                      context.read<CheckoutCubit>().applyPromo(code, cartState.subtotal);
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: isDark ? AppColors.neutral800 : AppColors.neutral200,
                              disabledForegroundColor: AppColors.neutral400,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                                  )
                                : Text(
                                    buttonText,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                  ),
                          ),
                        ),
                      ],
                    ),
            );
          },
        );
      },
    );
  }
}

/// 🧾 Savat: Narxlar tafsiloti (Cart Summary Card)
class SDUICartSummaryComponent extends StatelessWidget {
  final SDUISectionModel section;
  final SDUIActionHandler onAction;

  const SDUICartSummaryComponent({
    super.key,
    required this.section,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final props = section.properties;
    final title = props['title']?.toString() ?? 'cart.total'.tr();

    return BlocBuilder<CartCubit, CartState>(
      builder: (context, cartState) {
        if (cartState.items.isEmpty) return const SizedBox.shrink();

        return BlocBuilder<CheckoutCubit, CheckoutState>(
          builder: (context, checkoutState) {
            double discount = 0;
            if (checkoutState.promoValue != null && checkoutState.promoValue! > 0) {
              if (checkoutState.promoType == 2) {
                discount = cartState.subtotal * (checkoutState.promoValue! / 100);
              } else {
                discount = checkoutState.promoValue!;
              }
            }

            final finalTotal = (cartState.subtotal - discount).clamp(0.0, double.infinity);

            return Container(
              margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.neutral200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${'cart.subtotal'.tr()}:', style: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral500)),
                      Text(
                        '${NumberFormatter.formatSum(cartState.subtotal)} ${'common.currency'.tr()}',
                        style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  if (discount > 0) ...[
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${'checkout.promo_discount'.tr()}:',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.success),
                        ),
                        Text(
                          '-${NumberFormatter.formatSum(discount)} ${'common.currency'.tr()}',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.success,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${'cart.delivery'.tr()}:', style: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral500)),
                      Text('checkout.free'.tr(), style: AppTextStyles.labelMedium.copyWith(color: AppColors.success, fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${'cart.total'.tr()}:', style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w800)),
                      Text(
                        '${NumberFormatter.formatSum(finalTotal)} ${'common.currency'.tr()}',
                        style: AppTextStyles.priceLarge.copyWith(color: AppColors.primary, fontSize: 18),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// 🔴 Savat: Rasmiylashtirish tugmasi (Cart Checkout Button)
class SDUICartCheckoutButtonComponent extends StatelessWidget {
  final SDUISectionModel section;
  final SDUIActionHandler onAction;

  const SDUICartCheckoutButtonComponent({
    super.key,
    required this.section,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final props = section.properties;
    final buttonText = props['button_text']?.toString() ?? 'cart.checkout'.tr();

    return BlocBuilder<CartCubit, CartState>(
      builder: (context, cartState) {
        if (cartState.items.isEmpty) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          child: SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () {
                AnalyticsService.instance.logEvent('cart_checkout_clicked', {
                  'items_count': cartState.items.length,
                  'subtotal': cartState.subtotal,
                });
                if (section.action != null) {
                  onAction(section.action!);
                } else {
                  context.push('/checkout');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    buttonText,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

