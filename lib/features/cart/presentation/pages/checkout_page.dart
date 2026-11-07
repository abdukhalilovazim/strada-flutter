import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pizza_strada/core/sdui/sdui.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/checkout/checkout_cubit.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/checkout/checkout_state.dart';
import 'package:pizza_strada/features/cart/presentation/widgets/order_type_bottom_sheet.dart';

/// 💳 CheckoutPage: Bosqichli (Stepped) SDUI Checkout
/// Step 1: Yetkazib berish (Manzil / Filial tanlash)
/// Step 2: To'lov va tasdiqlash (Mijoz, To'lov turi, Kuryer izohi, Hisob-kitob)
class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  int _currentStep = 0; // 0 = Yetkazib berish, 1 = To'lov va tasdiqlash

  static const _step1Types = {
    'order_type_selector_card',
    'address_selector_card',
    'pickup_branch_card',
    'delivery_time_slot_card',
  };

  static const _step2Types = {
    'customer_info_card',
    'payment_method_selector_card',
    'courier_notes_card',
    'checkout_summary_card',
    'submit_order_cta_card',
  };

  void _proceedToStep2(BuildContext context, CheckoutState checkoutState, CartState cartState) {
    HapticFeedback.mediumImpact();

    if (cartState.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('cart.empty_error'.tr()),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (checkoutState.isDelivery) {
      if (checkoutState.address == null ||
          checkoutState.address!.trim().isEmpty ||
          checkoutState.lat == null ||
          checkoutState.lng == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('checkout.select_address_error'.tr()),
            backgroundColor: AppColors.error,
          ),
        );
        context.push('/map-picker');
        return;
      }
    } else {
      if (checkoutState.branchId == null || checkoutState.branchId!.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('checkout.select_branch_error'.tr()),
            backgroundColor: AppColors.error,
          ),
        );
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const OrderTypeBottomSheet(),
        );
        return;
      }
    }

    setState(() => _currentStep = 1);
  }

  PreferredSizeWidget _buildStepIndicator(bool isDark) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(54),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        decoration: BoxDecoration(
          color: Theme.of(context).appBarTheme.backgroundColor,
          border: Border(
            bottom: BorderSide(
              color: isDark ? AppColors.neutral800 : AppColors.neutral200,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                if (_currentStep == 1) {
                  HapticFeedback.selectionClick();
                  setState(() => _currentStep = 0);
                }
              },
              child: _StepDot(
                number: 1,
                label: 'checkout.delivery'.tr(),
                isActive: _currentStep == 0,
                isDone: _currentStep > 0,
              ),
            ),
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: _currentStep > 0
                      ? AppColors.primary
                      : (isDark ? AppColors.neutral700 : AppColors.neutral200),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
            _StepDot(
              number: 2,
              label: 'checkout.step2_label'.tr(),
              isActive: _currentStep == 1,
              isDone: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep2LocationSummary(BuildContext context, CheckoutState state, bool isDark) {
    final isDelivery = state.isDelivery;
    final locationText = isDelivery
        ? (state.address ?? 'checkout.delivery_location'.tr())
        : (state.branchTitle ?? 'checkout.selected_branch'.tr());

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.neutral200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isDelivery ? Icons.location_on_rounded : Icons.storefront_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isDelivery ? 'checkout.delivery_location'.tr() : 'checkout.pickup_location'.tr(),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.neutral500,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    locationText,
                    style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() => _currentStep = 0);
              },
              icon: const Icon(Icons.edit_outlined, size: 14, color: AppColors.primary),
              label: Text(
                'common.change'.tr(),
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider(
      create: (_) => SDUIPageCubit(slug: 'checkout')..load(),
      child: BlocBuilder<CheckoutCubit, CheckoutState>(
        builder: (context, checkoutState) {
          return BlocBuilder<CartCubit, CartState>(
            builder: (context, cartState) {
              return Scaffold(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                appBar: AppBar(
                  title: Text(
                    'checkout.title'.tr(),
                    style: AppTextStyles.h2.copyWith(
                      color: Theme.of(context).textTheme.headlineMedium?.color,
                    ),
                  ),
                  backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
                  elevation: 0,
                  centerTitle: true,
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                    onPressed: () {
                      if (_currentStep == 1) {
                        HapticFeedback.selectionClick();
                        setState(() => _currentStep = 0);
                      } else {
                        context.pop();
                      }
                    },
                  ),
                  bottom: _buildStepIndicator(isDark),
                ),
                body: BlocBuilder<SDUIPageCubit, SDUIPageState>(
                  builder: (context, state) {
                    if (state is SDUIPageUpdating) {
                      return SDUIUpdateView(
                        isSuccess: state.isSuccess,
                        title: state.title,
                        subtitle: state.subtitle,
                      );
                    }

                    if (state is SDUIPageLoading) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      );
                    }

                    if (state is SDUIPageFailure) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.neutral400),
                            const SizedBox(height: 12),
                            Text(
                              'common.no_internet'.tr(),
                              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral600),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => context.read<SDUIPageCubit>().load(forceRefresh: true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: Text('common.retry'.tr()),
                            ),
                          ],
                        ),
                      );
                    }

                    if (state is SDUIPageLoaded) {
                      final step1Sections = state.page.sections
                          .where((s) => _step1Types.contains(s.type))
                          .toList();
                      final step2Sections = state.page.sections
                          .where((s) => _step2Types.contains(s.type))
                          .toList();

                      final currentSections = _currentStep == 0 ? step1Sections : step2Sections;
                      final filteredPage = state.page.copyWith(sections: currentSections);

                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: SDUIRenderer(
                          key: ValueKey('checkout_step_${_currentStep}_${state.page.versionUuid}'),
                          page: filteredPage,
                          leadingSlivers: [
                            if (_currentStep == 1)
                              _buildStep2LocationSummary(context, checkoutState, isDark),
                          ],
                          onRefresh: () => context.read<SDUIPageCubit>().load(forceRefresh: true),
                        ),
                      );
                    }

                    return const SizedBox.shrink();
                  },
                ),
                bottomNavigationBar: _currentStep == 0
                    ? Container(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
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
                              offset: const Offset(0, -4),
                            ),
                          ],
                        ),
                        child: SafeArea(
                          top: false,
                          child: SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: () => _proceedToStep2(context, checkoutState, cartState),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 3,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'checkout.next'.tr(),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward_rounded, size: 20),
                                ],
                              ),
                            ),
                          ),
                        ),
                      )
                    : null,
              );
            },
          );
        },
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final int number;
  final String label;
  final bool isActive;
  final bool isDone;

  const _StepDot({
    required this.number,
    required this.label,
    required this.isActive,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = (isActive || isDone) ? AppColors.primary : AppColors.neutral400;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isDone
                ? AppColors.primary
                : (isActive
                    ? AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.12)
                    : Colors.transparent),
            shape: BoxShape.circle,
            border: Border.all(
              color: color,
              width: 1.8,
            ),
          ),
          alignment: Alignment.center,
          child: isDone
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
              : Text(
                  '$number',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
            color: isActive
                ? (isDark ? Colors.white : AppColors.neutral900)
                : AppColors.neutral500,
          ),
        ),
      ],
    );
  }
}
