import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pizza_strada/core/services/smart_recommendation_engine.dart';
import 'package:pizza_strada/core/storage/secure_storage.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/core/utils/number_formatter.dart';
import 'package:pizza_strada/core/utils/variant_localization_helper.dart';
import 'package:pizza_strada/core/widgets/pizza_image_placeholder.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/checkout/checkout_cubit.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/checkout/checkout_state.dart';

/// 🛒 CartPage powered 100% by Native Flutter UI & BLoC
class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CheckoutCubit>().loadCheckoutOptions();
      }
    });
  }

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
              : Stack(
                  children: [
                    _buildCartContent(context, cartState, isDark),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 12,
                      child: SafeArea(
                        top: false,
                        child: _buildCheckoutBottomBar(context, cartState, isDark),
                      ),
                    ),
                  ],
                ),
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
      padding: const EdgeInsets.only(bottom: 90),
      children: [
        _buildCartItemsList(context, cartState, isDark),
        _buildUpsellSlider(context, cartState, isDark),
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
            : '';
        final variantDetails = item.variant?.details;
        final hasSize = localizedVariant.isNotEmpty;
        final hasDetails = variantDetails != null && variantDetails.trim().isNotEmpty;

        final itemKey = ValueKey(
          item.isCoupon
              ? 'cart_coupon_${item.couponId}'
              : 'cart_item_${item.product.id}_${item.variant?.id ?? 'none'}',
        );

        return Dismissible(
          key: itemKey,
          direction: DismissDirection.horizontal,
          dismissThresholds: const {
            DismissDirection.startToEnd: 0.65,
            DismissDirection.endToStart: 0.65,
          },
          background: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Text(
                  'common.delete'.tr(),
                  style: AppTextStyles.labelMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          secondaryBackground: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'common.delete'.tr(),
                  style: AppTextStyles.labelMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
              ],
            ),
          ),
          onDismissed: (_) {
            HapticFeedback.mediumImpact();
            context.read<CartCubit>().removeFromCart(item);
          },
          child: Container(
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
                      if (item.isCoupon) ...[
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.confirmation_number_outlined, size: 12, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              'Kupon to\'plami',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.primary,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        // 2. Size
                        if (hasSize) ...[
                          const SizedBox(height: 2),
                          Text(
                            localizedVariant,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: isDark ? AppColors.neutral300 : AppColors.neutral700,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        // 3. Detail
                        if (hasDetails) ...[
                          const SizedBox(height: 1.5),
                          Text(
                            variantDetails.trim(),
                            style: AppTextStyles.bodyExtraSmall.copyWith(
                              color: AppColors.neutral500,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                      // 4. Price
                      const SizedBox(height: 5),
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
          ),
        );
      },
    );
  }

  Widget _buildUpsellSlider(BuildContext context, CartState cartState, bool isDark) {
    if (cartState.items.isEmpty) return const SizedBox.shrink();

    final cartItemsPayload = cartState.items
        .map((e) => {'product_id': e.product.id, 'quantity': e.quantity})
        .toList();

    return FutureBuilder<RecommendationMatch>(
      future: SmartRecommendationEngine.fetch(items: cartItemsPayload),
      initialData: SmartRecommendationEngine.currentMatch,
      builder: (context, snapshot) {
        final match = snapshot.data;
        if (match == null || match.isEmpty) return const SizedBox.shrink();

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
      },
    );
  }

  Widget _buildCheckoutBottomBar(BuildContext context, CartState cartState, bool isDark) {
    final total = cartState.subtotal.toInt();

    return BlocBuilder<CheckoutCubit, CheckoutState>(
      builder: (context, checkoutState) {
        final canOrder = checkoutState.canOrder;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!canOrder) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF3E2D12) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF78350F) : const Color(0xFFFDE68A),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: isDark ? const Color(0xFFFBBF24) : const Color(0xFFB45309),
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        checkoutState.canOrderMessage ?? 'checkout.ordering_suspended'.tr(),
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: !canOrder
                    ? null
                    : () async {
                        HapticFeedback.mediumImpact();
                        final token = await SecureStorage.getToken();
                        if (token == null || token.isEmpty) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('checkout.login_required'.tr()),
                                backgroundColor: AppColors.primary,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                            context.push('/auth/login');
                          }
                          return;
                        }
                        if (context.mounted) {
                          context.push('/checkout');
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: canOrder
                      ? AppColors.primary
                      : (isDark ? AppColors.neutral800 : AppColors.neutral300),
                  disabledBackgroundColor: isDark ? AppColors.neutral800 : AppColors.neutral300,
                  foregroundColor: Colors.white,
                  disabledForegroundColor: isDark ? AppColors.neutral500 : AppColors.neutral500,
                  elevation: canOrder ? 4 : 0,
                  shadowColor: Colors.black.withValues(alpha: 0.25),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      canOrder ? 'cart.checkout'.tr() : '${'cart.checkout'.tr()} (${'checkout.inactive'.tr()})',
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
          ],
        );
      },
    );
  }
}

