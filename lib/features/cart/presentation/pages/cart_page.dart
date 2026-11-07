import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pizza_strada/core/services/smart_recommendation_engine.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/core/utils/number_formatter.dart';
import 'package:pizza_strada/core/utils/variant_localization_helper.dart';
import 'package:pizza_strada/core/widgets/pizza_image_placeholder.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/checkout/checkout_cubit.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/checkout/checkout_state.dart';
import 'package:pizza_strada/features/home/presentation/bloc/home_cubit.dart';

/// 🛒 CartPage powered 100% by Native Flutter UI & BLoC
class CartPage extends StatelessWidget {
  const CartPage({super.key});

  void _showClearConfirm(BuildContext context) {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'cart.clear_title'.tr(),
          style: AppTextStyles.h4.copyWith(
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppColors.neutral900,
          ),
        ),
        content: Text(
          'cart.clear_confirm'.tr(),
          style: AppTextStyles.bodyMedium.copyWith(
            color: isDark ? AppColors.neutral300 : AppColors.neutral600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'common.cancel'.tr(),
              style: TextStyle(
                color: isDark ? AppColors.neutral400 : AppColors.neutral600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<CartCubit>().clearCart();
              context.read<CheckoutCubit>().clearPromo();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              minimumSize: const Size(64, 40),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('common.clear'.tr(), style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocBuilder<CartCubit, CartState>(
      builder: (context, cartState) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(
              'cart.title'.tr(),
              style: AppTextStyles.h2.copyWith(
                color: Theme.of(context).textTheme.headlineMedium?.color,
              ),
            ),
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            elevation: 0,
            centerTitle: true,
            actions: [
              if (cartState.items.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.neutral500),
                  tooltip: 'common.clear'.tr(),
                  onPressed: () => _showClearConfirm(context),
                ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 1,
                color: isDark ? AppColors.neutral800 : AppColors.neutral200,
              ),
            ),
          ),
          body: cartState.items.isEmpty
              ? _buildEmptyCart(context, isDark)
              : _buildCartContent(context, cartState, isDark),
          bottomNavigationBar: cartState.items.isEmpty
              ? null
              : _buildCheckoutBottomBar(context, cartState, isDark),
        );
      },
    );
  }

  Widget _buildEmptyCart(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.shopping_bag_outlined,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'cart.empty'.tr(),
              style: AppTextStyles.h3.copyWith(
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.neutral900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'cart.empty_subtitle'.tr(),
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark ? AppColors.neutral400 : AppColors.neutral600,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.go('/home');
                },
                icon: const Icon(Icons.local_pizza_rounded, size: 20),
                label: Text(
                  'cart.go_home'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartContent(BuildContext context, CartState cartState, bool isDark) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 120),
      children: [
        _buildCartItemsList(context, cartState, isDark),
        _buildUpsellSlider(context, cartState, isDark),
        const _CartPromoCodeWidget(),
        _buildSummaryCard(context, cartState, isDark),
      ],
    );
  }

  Widget _buildCartItemsList(BuildContext context, CartState cartState, bool isDark) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      itemCount: cartState.items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final item = cartState.items[i];
        final product = item.product;

        final rawVariantTitle = item.variant?.title;
        final localizedVariant = rawVariantTitle != null && rawVariantTitle.isNotEmpty
            ? VariantLocalizationHelper.localize(rawVariantTitle)
            : null;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.neutral200.withValues(alpha: 0.7),
            ),
            boxShadow: AppColors.softShadow(isDark),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 68,
                  height: 68,
                  child: product.validImageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: product.validImageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const PizzaImagePlaceholder(width: 68, height: 68),
                          errorWidget: (_, __, ___) => const PizzaImagePlaceholder(width: 68, height: 68),
                        )
                      : const PizzaImagePlaceholder(width: 68, height: 68),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (localizedVariant != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        localizedVariant,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.neutral500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      '${NumberFormatter.formatSum(item.totalPrice)} ${'common.currency'.tr()}',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : const Color(0xFFF1F3F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(
                        item.quantity == 1 ? Icons.delete_outline_rounded : Icons.remove_rounded,
                        size: 18,
                        color: item.quantity == 1 ? AppColors.error : AppColors.neutral700,
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        context.read<CartCubit>().updateQuantity(item, -1);
                      },
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        '${item.quantity}',
                        style: AppTextStyles.labelMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_rounded, size: 18, color: AppColors.neutral900),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        context.read<CartCubit>().updateQuantity(item, 1);
                      },
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUpsellSlider(BuildContext context, CartState cartState, bool isDark) {
    final homeState = context.watch<HomeCubit>().state;
    if (homeState is! HomeLoaded) return const SizedBox.shrink();

    final match = SmartRecommendationEngine.resolve(
      cartItems: cartState.items,
      allProducts: homeState.fullProducts,
      localeCode: context.locale.languageCode,
    );

    if (match.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    match.title.isNotEmpty ? match.title : 'cart.upsell_title'.tr(),
                    style: AppTextStyles.h4.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 135,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: match.products.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (ctx, i) {
                final product = match.products[i];
                return Container(
                  width: 110,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.neutral200.withValues(alpha: 0.7),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: product.validImageUrl.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: product.validImageUrl,
                                        fit: BoxFit.cover,
                                        errorWidget: (_, __, ___) => const PizzaImagePlaceholder(width: 48, height: 48),
                                      )
                                    : const PizzaImagePlaceholder(width: 48, height: 48),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: InkWell(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  context.read<CartCubit>().addToCart(
                                        product,
                                        variant: product.variants.firstOrNull,
                                      );
                                },
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 14),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        product.title,
                        style: AppTextStyles.labelSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 11.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${NumberFormatter.formatSum(product.price.toInt())} ${'common.currency'.tr()}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
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
  }

  Widget _buildSummaryCard(BuildContext context, CartState cartState, bool isDark) {
    return BlocBuilder<CheckoutCubit, CheckoutState>(
      builder: (context, checkoutState) {
        final subtotal = cartState.subtotal;
        final deliveryPrice = checkoutState.isDelivery ? checkoutState.deliveryPrice : 0;
        final discount = checkoutState.discountAmount;
        final total = (subtotal + deliveryPrice - discount).clamp(0, double.infinity).toInt();

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? AppColors.darkBorder : AppColors.neutral200.withValues(alpha: 0.7),
            ),
            boxShadow: AppColors.softShadow(isDark),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hisob-kitob',
                style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              _buildSummaryRow('cart.subtotal'.tr(), '${NumberFormatter.formatSum(subtotal)} ${'common.currency'.tr()}', isDark),
              const SizedBox(height: 8),
              _buildSummaryRow(
                'cart.delivery'.tr(),
                deliveryPrice > 0 ? '${NumberFormatter.formatSum(deliveryPrice)} ${'common.currency'.tr()}' : 'Bepul',
                isDark,
                valueColor: deliveryPrice > 0 ? null : AppColors.success,
              ),
              if (discount > 0) ...[
                const SizedBox(height: 8),
                _buildSummaryRow(
                  'cart.discount'.tr(),
                  '-${NumberFormatter.formatSum(discount)} ${'common.currency'.tr()}',
                  isDark,
                  valueColor: AppColors.success,
                ),
              ],
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(height: 1),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'cart.total'.tr(),
                    style: AppTextStyles.h4.copyWith(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '${NumberFormatter.formatSum(total)} ${'common.currency'.tr()}',
                    style: AppTextStyles.h4.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value, bool isDark, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isDark ? AppColors.neutral400 : AppColors.neutral600,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.labelMedium.copyWith(
            fontWeight: FontWeight.w700,
            color: valueColor ?? (isDark ? Colors.white : AppColors.neutral900),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckoutBottomBar(BuildContext context, CartState cartState, bool isDark) {
    return BlocBuilder<CheckoutCubit, CheckoutState>(
      builder: (context, checkoutState) {
        final subtotal = cartState.subtotal;
        final deliveryPrice = checkoutState.isDelivery ? checkoutState.deliveryPrice : 0;
        final discount = checkoutState.discountAmount;
        final total = (subtotal + deliveryPrice - discount).clamp(0, double.infinity).toInt();

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.neutral800 : AppColors.neutral200,
                width: 1,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, -3),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  context.push('/checkout');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'cart.checkout'.tr(),
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    Text(
                      '${NumberFormatter.formatSum(total)} ${'common.currency'.tr()}',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// 🎟 Native Promo Code Widget
class _CartPromoCodeWidget extends StatefulWidget {
  const _CartPromoCodeWidget();

  @override
  State<_CartPromoCodeWidget> createState() => _CartPromoCodeWidgetState();
}

class _CartPromoCodeWidgetState extends State<_CartPromoCodeWidget> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
        final cartSubtotal = context.watch<CartCubit>().state.subtotal;

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
                              context.read<CheckoutCubit>().applyPromo(code.trim(), cartSubtotal);
                            }
                          },
                          decoration: InputDecoration(
                            labelText: 'Promokod',
                            labelStyle: AppTextStyles.bodySmall.copyWith(
                              color: isDark ? AppColors.neutral400 : AppColors.neutral500,
                              fontSize: 13,
                            ),
                            hintText: 'Promokodni kiriting',
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
                        onPressed: _controller.text.trim().isEmpty || isLoading
                            ? null
                            : () {
                                HapticFeedback.mediumImpact();
                                FocusScope.of(context).unfocus();
                                context.read<CheckoutCubit>().applyPromo(_controller.text.trim(), cartSubtotal);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Text(
                                'cart.apply'.tr(),
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                              ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
