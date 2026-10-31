import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/core/utils/number_formatter.dart';
import 'package:pizza_strada/core/utils/phone_number_formatter.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/checkout/checkout_state.dart';

/// Buyurtmani yakuniy tasdiqlash uchun xulosa oynasi (Order Confirmation Bottom Sheet).
///
/// Checkout bosqichlari to'ldirilgach, barcha ma'lumotlarni
/// (manzil/filial, to'lov usuli, mahsulotlar ro'yxati, qabul qiluvchi va narxlar)
/// bitta ekranda jamlab ko'rsatadi va yakuniy tasdiqlash tugmasini taqdim etadi.
class OrderConfirmationSheet extends StatelessWidget {
  final CheckoutState checkoutState;
  final CartState cartState;
  final String userName;
  final String userPhone;
  final String paymentMethodName;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final double finalTotal;
  final VoidCallback onConfirm;

  const OrderConfirmationSheet({
    super.key,
    required this.checkoutState,
    required this.cartState,
    required this.userName,
    required this.userPhone,
    required this.paymentMethodName,
    required this.subtotal,
    required this.deliveryFee,
    required this.discount,
    required this.finalTotal,
    required this.onConfirm,
  });

  static Future<void> show(
    BuildContext context, {
    required CheckoutState checkoutState,
    required CartState cartState,
    required String userName,
    required String userPhone,
    required String paymentMethodName,
    required double subtotal,
    required double deliveryFee,
    required double discount,
    required double finalTotal,
    required VoidCallback onConfirm,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OrderConfirmationSheet(
        checkoutState: checkoutState,
        cartState: cartState,
        userName: userName,
        userPhone: userPhone,
        paymentMethodName: paymentMethodName,
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        discount: discount,
        finalTotal: finalTotal,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDelivery = checkoutState.isDelivery;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag Handle & Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.neutral700 : AppColors.neutral300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'checkout.confirm_order_title'.tr(),
                        style: AppTextStyles.h3.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.headlineMedium?.color,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                        color: isDark ? AppColors.neutral400 : AppColors.neutral600,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Manzil / Filial kartasi
                    _buildInfoCard(
                      context,
                      isDark: isDark,
                      icon: isDelivery ? Icons.delivery_dining_rounded : Icons.storefront_rounded,
                      title: isDelivery ? 'checkout.delivery'.tr() : 'checkout.pickup'.tr(),
                      subtitle: isDelivery
                          ? (checkoutState.address ?? 'checkout.select_address'.tr())
                          : (checkoutState.branchTitle ?? 'checkout.select_branch'.tr()),
                      badgeText: isDelivery && deliveryFee > 0
                          ? '${'cart.delivery'.tr()}: ${NumberFormatter.formatSum(deliveryFee.toInt())} ${'common.currency'.tr()}'
                          : null,
                    ),

                    const SizedBox(height: 12),

                    // 2. Qabul qiluvchi
                    if (userPhone.isNotEmpty) ...[
                      _buildInfoCard(
                        context,
                        isDark: isDark,
                        icon: Icons.person_rounded,
                        title: 'checkout.recipient_title'.tr(),
                        subtitle: userName.isNotEmpty
                            ? '$userName • ${PhoneNumberFormatter.format(userPhone)}'
                            : PhoneNumberFormatter.format(userPhone),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // 3. To'lov usuli
                    _buildInfoCard(
                      context,
                      isDark: isDark,
                      icon: Icons.payment_rounded,
                      title: 'checkout.payment_method_title'.tr(),
                      subtitle: paymentMethodName,
                    ),

                    const SizedBox(height: 16),

                    // 4. Mahsulotlar ro'yxati
                    Text(
                      '${'checkout.order_items_title'.tr()} (${cartState.items.length})',
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.neutral50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.neutral200.withValues(alpha: 0.8),
                        ),
                      ),
                      child: Column(
                        children: cartState.items.map((item) {
                          final itemTotal = (item.unitPrice * item.quantity).toInt();
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.product.title,
                                        style: AppTextStyles.labelSmall.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: theme.textTheme.bodyLarge?.color,
                                        ),
                                      ),
                                      if (item.variant != null)
                                        Text(
                                          item.variant!.title,
                                          style: AppTextStyles.bodyExtraSmall.copyWith(
                                            color: isDark ? AppColors.neutral400 : AppColors.neutral600,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${item.quantity}x',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${NumberFormatter.formatSum(itemTotal)} ${'common.currency'.tr()}',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.textTheme.bodyLarge?.color,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // 5. Izoh (agar bo'lsa)
                    if (checkoutState.comment.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkCard : AppColors.neutral50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? AppColors.darkBorder : AppColors.neutral200.withValues(alpha: 0.8),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.chat_bubble_outline_rounded, size: 18, color: AppColors.neutral500),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                checkoutState.comment,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: isDark ? AppColors.neutral300 : AppColors.neutral700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // 6. Yakuniy narxlar
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : AppColors.neutral50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? AppColors.darkBorder : AppColors.neutral200.withValues(alpha: 0.8),
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildPriceRow(
                            label: 'cart.subtotal'.tr(),
                            value: '${NumberFormatter.formatSum(subtotal.toInt())} ${'common.currency'.tr()}',
                            isDark: isDark,
                          ),
                          if (isDelivery) ...[
                            const SizedBox(height: 8),
                            _buildPriceRow(
                              label: 'cart.delivery'.tr(),
                              value: '${NumberFormatter.formatSum(deliveryFee.toInt())} ${'common.currency'.tr()}',
                              isDark: isDark,
                            ),
                          ],
                          if (discount > 0) ...[
                            const SizedBox(height: 8),
                            _buildPriceRow(
                              label: 'cart.discount'.tr(),
                              value: '- ${NumberFormatter.formatSum(discount.toInt())} ${'common.currency'.tr()}',
                              isDark: isDark,
                              isDiscount: true,
                            ),
                          ],
                          const Divider(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'cart.total'.tr(),
                                style: AppTextStyles.labelLarge.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                              ),
                              Text(
                                '${NumberFormatter.formatSum(finalTotal.toInt())} ${'common.currency'.tr()}',
                                style: AppTextStyles.h3.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 7. Tasdiqlash tugmasi
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    onConfirm();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'checkout.confirm_order_btn'.tr(),
                        style: AppTextStyles.labelLarge.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    String? badgeText,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.neutral50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.neutral200.withValues(alpha: 0.8),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyExtraSmall.copyWith(
                        color: isDark ? AppColors.neutral400 : AppColors.neutral600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (badgeText != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badgeText,
                          style: AppTextStyles.bodyExtraSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow({
    required String label,
    required String value,
    required bool isDark,
    bool isDiscount = false,
  }) {
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
          style: AppTextStyles.labelSmall.copyWith(
            fontWeight: FontWeight.w600,
            color: isDiscount
                ? AppColors.secondary
                : (isDark ? Colors.white : AppColors.neutral900),
          ),
        ),
      ],
    );
  }
}
