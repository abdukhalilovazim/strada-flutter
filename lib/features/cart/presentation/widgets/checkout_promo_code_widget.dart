import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/checkout/checkout_cubit.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/checkout/checkout_state.dart';

/// 🎟 Checkout sahifasi uchun promo-kod kiritish va tasdiqlash vidjeti
class CheckoutPromoCodeWidget extends StatefulWidget {
  const CheckoutPromoCodeWidget({super.key});

  @override
  State<CheckoutPromoCodeWidget> createState() => _CheckoutPromoCodeWidgetState();
}

class _CheckoutPromoCodeWidgetState extends State<CheckoutPromoCodeWidget> {
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
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          context.read<CheckoutCubit>().clearPromo();
        } else if (checkoutState.appliedPromoCode != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${'cart.promo_activated'.tr()}: ${checkoutState.appliedPromoCode}'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                            Row(
                              children: [
                                Text(
                                  checkoutState.appliedPromoCode!,
                                  style: AppTextStyles.labelLarge.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: isDark ? Colors.white : AppColors.neutral900,
                                  ),
                                ),
                                if (checkoutState.isPercentagePromo && checkoutState.promoValue != null) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '-${checkoutState.promoValue!.toInt()}%',
                                      style: const TextStyle(
                                        color: AppColors.success,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
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
                          autocorrect: false,
                          enableSuggestions: false,
                          spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
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

