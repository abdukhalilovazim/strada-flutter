import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pizza_strada/core/di/injection.dart';
import 'package:pizza_strada/core/models/saved_address_model.dart';
import 'package:pizza_strada/core/network/api_client.dart';
import 'package:pizza_strada/core/services/analytics_service.dart';
import 'package:pizza_strada/core/storage/secure_storage.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/core/utils/number_formatter.dart';
import 'package:pizza_strada/core/utils/phone_number_formatter.dart';
import 'package:pizza_strada/core/widgets/app_text_field.dart';
import 'package:pizza_strada/core/widgets/pizza_image_placeholder.dart';
import 'package:pizza_strada/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/cart_cubit.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/checkout/checkout_cubit.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/checkout/checkout_state.dart';
import 'package:pizza_strada/features/cart/presentation/widgets/checkout_otp_sheet.dart';
import 'package:pizza_strada/features/home/domain/entities/home_entities.dart';
import 'package:pizza_strada/features/home/presentation/bloc/home_cubit.dart';
import 'package:pizza_strada/features/orders/data/models/order_model.dart';
import 'package:pizza_strada/features/orders/domain/entities/order_entity.dart';
import 'package:url_launcher/url_launcher.dart';

/// 🍕 3-Step Checkout Funnel (Dodo Pizza & Uzum Tezkor benchmark)
/// Step 1: Yetkazib berish turi & Manzil (Saved addresses, Map picker, Branch selection)
/// Step 2: Promokod & To'lov usuli (Cash, Terminal, Payme online)
/// Step 3: Tasdiqlash, Izoh & To'lovga o'tish (Review, Note, Submit / Payme launch)
class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  int _currentStep = 0;
  final PageController _pageController = PageController();

  List<CheckoutBranch> _branches = [];
  List<SavedAddressModel> _savedAddresses = [];

  final _commentController = TextEditingController();
  final _promoController = TextEditingController();
  final _guestNameController = TextEditingController();
  final _guestPhoneController = TextEditingController();
  final _additionalPhoneController = TextEditingController();

  bool _isLoggedIn = false;
  String? _userName;
  String? _userPhone;
  bool _isSubmittingOrder = false;
  bool _showCommentField = false;
  bool _showPromoField = false;
  bool _showStep1ValidationErrors = false;

  bool _isStep1Valid(CheckoutState state) {
    final hasLocation = state.isDelivery
        ? (state.address != null && state.address!.trim().isNotEmpty)
        : (state.branchId != null && state.branchId!.trim().isNotEmpty);
    if (!hasLocation) return false;

    final hasName = _guestNameController.text.trim().isNotEmpty;
    if (_isLoggedIn) {
      return hasName;
    }

    final digits = _guestPhoneController.text.replaceAll(RegExp(r'\D'), '');
    final hasPhone = digits.length >= 9;

    return hasName && hasPhone;
  }

  @override
  void initState() {
    super.initState();
    _loadBranches();
    _loadUserData();
    _loadSavedAddresses();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final state = context.read<CheckoutCubit>().state;

      // Agar manzil tanlangan bo'lsa-yu, yetkazish narxi 0 bo'lsa hisoblash
      if (state.isDelivery &&
          state.lat != null &&
          state.lng != null &&
          state.deliveryPrice == 0) {
        context.read<CheckoutCubit>().setAddressAndCalculateDelivery(
              state.lat!,
              state.lng!,
              state.address ?? '',
            );
      }

      if (state.comment.isNotEmpty) {
        _commentController.text = state.comment;
      }
      if (state.appliedPromoCode != null) {
        _promoController.text = state.appliedPromoCode!;
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _commentController.dispose();
    _promoController.dispose();
    _additionalPhoneController.dispose();
    _guestNameController.dispose();
    _guestPhoneController.dispose();
    super.dispose();
  }

  Future<void> _loadBranches() async {
    try {
      final response = await ApiClient().get('branches');
      if (response is List && mounted) {
        final list = response
            .map((e) => CheckoutBranch.fromJson(e as Map<String, dynamic>))
            .toList();

        setState(() {
          _branches = list;
          final cubit = context.read<CheckoutCubit>();
          final currentBranchId = cubit.state.branchId;

          if (_branches.isNotEmpty) {
            if (currentBranchId == null) {
              cubit.setBranch(_branches.first.id, branchTitle: _branches.first.title);
            } else if (cubit.state.branchTitle == null) {
              final match = _branches.where((b) => b.id == currentBranchId).firstOrNull;
              if (match != null) {
                cubit.setBranch(match.id, branchTitle: match.title);
              }
            }
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _loadUserData() async {
    final token = await SecureStorage.getToken();
    final name = await SecureStorage.getUserName();
    final phone = await SecureStorage.getUserPhone();
    if (mounted) {
      setState(() {
        _isLoggedIn = token != null && token.isNotEmpty && phone != null && phone.isNotEmpty;
        _userName = name;
        _userPhone = phone;
        if (_userName != null && _guestNameController.text.isEmpty) {
          _guestNameController.text = _userName!;
        }
        if (_userPhone != null && _guestPhoneController.text.isEmpty) {
          _guestPhoneController.text = _userPhone!;
        }
      });
    }
  }

  Future<void> _loadSavedAddresses() async {
    final local = await SecureStorage.getSavedAddresses();
    if (mounted) {
      setState(() => _savedAddresses = local);
    }

    final token = await SecureStorage.getToken();
    if (token != null && token.isNotEmpty) {
      try {
        final res = await ApiClient().get('addresses');
        if (res is List && mounted) {
          final serverList = res.map((item) {
            return SavedAddressModel(
              id: item['id']?.toString() ?? '',
              label: item['label']?.toString() ?? 'Manzil',
              address: item['address_text']?.toString() ?? '',
              lat: (item['latitude'] as num?)?.toDouble() ?? 0.0,
              lng: (item['longitude'] as num?)?.toDouble() ?? 0.0,
            );
          }).toList();

          final set = <String>{};
          final merged = <SavedAddressModel>[];
          for (final a in [...serverList, ...local]) {
            if (a.address.isNotEmpty && set.add(a.address)) {
              merged.add(a);
            }
          }

          setState(() {
            _savedAddresses = merged;
          });
        }
      } catch (_) {}
    }
  }

  void _goToStep(int step) {
    HapticFeedback.lightImpact();
    setState(() => _currentStep = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
    );
  }

  int _getPaymentMethodId(String key) {
    final k = key.toLowerCase().trim();
    if (k == 'payme' || k == '1') return 1;
    return 0; // cash
  }

  String _getPaymentMethodTitle(CheckoutState state, List<PaymentMethodEntity> methods) {
    final match = methods.where((m) => m.key == state.selectedPaymentMethodKey).firstOrNull;
    if (match != null) return match.value;
    final id = _getPaymentMethodId(state.selectedPaymentMethodKey);
    if (id == 1 || state.selectedPaymentMethodKey == 'payme') return 'Payme (Online to\'lov)';
    return 'checkout.cash_payment'.tr();
  }

  double _computeDiscount(CheckoutState state, double subtotal) {
    if (state.appliedPromoCode == null) return 0;
    double discount = 0;
    if (state.promoValue != null) {
      if (state.promoType == 1) {
        discount += subtotal * state.promoValue! / 100;
      } else {
        discount += state.promoValue!;
      }
    }
    return discount;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final homeState = context.watch<HomeCubit>().state;
    List<PaymentMethodEntity> paymentMethods = [];
    if (homeState is HomeLoaded) {
      paymentMethods = homeState.settings?.paymentMethods ?? [];
    }

    return BlocConsumer<CheckoutCubit, CheckoutState>(
      listener: (context, state) {
        if (state.submitError != null) {
          setState(() => _isSubmittingOrder = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.submitError!),
            backgroundColor: AppColors.error,
          ));
          context.read<CheckoutCubit>().clearSubmitError();
        } else if (state.successData != null) {
          setState(() => _isSubmittingOrder = false);
          _handleSuccess(state.successData!);
        }
      },
      builder: (context, checkoutState) {
        final cartState = context.watch<CartCubit>().state;
        final subtotal = cartState.subtotal;
        final discount = _computeDiscount(checkoutState, subtotal);
        final deliveryFee = checkoutState.isDelivery ? checkoutState.deliveryPrice : 0.0;
        final finalTotal = (subtotal + deliveryFee - discount).clamp(0.0, double.infinity);

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(
              'checkout.title'.tr(),
              style: AppTextStyles.h2.copyWith(
                color: Theme.of(context).textTheme.headlineMedium?.color,
                fontSize: 18,
              ),
            ),
            centerTitle: true,
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            elevation: 0,
            surfaceTintColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: isDark ? Colors.white : AppColors.neutral900,
                size: 20,
              ),
              onPressed: () {
                if (_currentStep > 0) {
                  _goToStep(_currentStep - 1);
                } else {
                  context.pop();
                }
              },
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(64),
              child: _buildStepperHeader(isDark),
            ),
          ),
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            behavior: HitTestBehavior.translucent,
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                // ── 1-QADAM: Manzil & Filial ──
                _buildStep1Fulfillment(checkoutState, isDark),

                // ── 2-QADAM: To'lov & Promokod ──
                _buildStep2PaymentAndPromo(checkoutState, paymentMethods, subtotal, discount, isDark),

                // ── 3-QADAM: Tasdiqlash & Izoh & To'lov ──
                _buildStep3ReviewAndSubmit(
                  checkoutState,
                  cartState,
                  paymentMethods,
                  subtotal,
                  deliveryFee,
                  discount,
                  finalTotal,
                  isDark,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── 🏆 TOP STEPPER HEADER ──
  Widget _buildStepperHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.neutral800 : AppColors.neutral200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildStepItem(0, 'checkout.step1_title'.tr(), isDark),
          _buildStepDivider(0, isDark),
          _buildStepItem(1, 'checkout.step2_title'.tr(), isDark),
          _buildStepDivider(1, isDark),
          _buildStepItem(2, 'checkout.step3_title'.tr(), isDark),
        ],
      ),
    );
  }

  Widget _buildStepItem(int stepIndex, String title, bool isDark) {
    final isDone = _currentStep > stepIndex;
    final isActive = _currentStep == stepIndex;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (stepIndex < _currentStep) {
            _goToStep(stepIndex);
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone
                    ? AppColors.success
                    : isActive
                        ? AppColors.primary
                        : (isDark ? AppColors.neutral800 : AppColors.neutral200),
              ),
              child: Center(
                child: isDone
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                    : Text(
                        '${stepIndex + 1}',
                        style: TextStyle(
                          color: isActive
                              ? Colors.white
                              : (isDark ? AppColors.neutral400 : AppColors.neutral600),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                color: isActive
                    ? AppColors.primary
                    : isDone
                        ? (isDark ? Colors.white : AppColors.neutral900)
                        : AppColors.neutral400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepDivider(int stepIndex, bool isDark) {
    final isDone = _currentStep > stepIndex;
    return Container(
      width: 24,
      height: 2,
      margin: const EdgeInsets.only(bottom: 16),
      color: isDone
          ? AppColors.primary
          : (isDark ? AppColors.neutral800 : AppColors.neutral200),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // ── 📍 1-QADAM: Yetkazib berish turi va Manzil / Filial ──
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildStep1Fulfillment(CheckoutState state, bool isDark) {
    final hasAddressError = _showStep1ValidationErrors &&
        state.isDelivery &&
        (state.address == null || state.address!.trim().isEmpty);
    final hasBranchError = _showStep1ValidationErrors &&
        !state.isDelivery &&
        (state.branchId == null || state.branchId!.trim().isEmpty);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Delivery / Pickup Segmented Control
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.neutral100,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.neutral200,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTypeSegment(
                    title: 'checkout.delivery'.tr(),
                    icon: Icons.delivery_dining_rounded,
                    isSelected: state.isDelivery,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.read<CheckoutCubit>().setDeliveryType(true);
                      setState(() {});
                    },
                    isDark: isDark,
                  ),
                ),
                Expanded(
                  child: _buildTypeSegment(
                    title: 'checkout.pickup'.tr(),
                    icon: Icons.storefront_rounded,
                    isSelected: !state.isDelivery,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.read<CheckoutCubit>().setDeliveryType(false);
                      setState(() {});
                    },
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Agar Yetkazib berish bo'lsa:
          if (state.isDelivery) ...[
            // ⭐️ Saqlangan oldingi manzillar (Recent locations)
            if (_savedAddresses.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.history_rounded, size: 18, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'checkout.saved_locations'.tr(),
                    style: AppTextStyles.h4.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.neutral900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 78,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _savedAddresses.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final addr = _savedAddresses[index];
                    final isSelected = state.address == addr.address;

                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.read<CheckoutCubit>().setAddressAndCalculateDelivery(
                              addr.lat,
                              addr.lng,
                              addr.address,
                            );
                        if (addr.comment != null && addr.comment!.isNotEmpty) {
                          _commentController.text = addr.comment!;
                          context.read<CheckoutCubit>().setComment(addr.comment!);
                        } else {
                          _commentController.clear();
                          context.read<CheckoutCubit>().setComment('');
                        }
                        setState(() {});
                      },
                      child: Container(
                        width: 220,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.08)
                              : (isDark ? AppColors.darkCard : Colors.white),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark ? AppColors.darkBorder : AppColors.neutral200),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: AppColors.softShadow(isDark),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDark ? AppColors.neutral800 : AppColors.neutral100),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                addr.label.toLowerCase().contains('ish')
                                    ? Icons.work_outline_rounded
                                    : Icons.home_outlined,
                                color: isSelected ? Colors.white : AppColors.neutral600,
                                size: 18,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    addr.label,
                                    style: AppTextStyles.labelMedium.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : AppColors.neutral900,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    addr.address,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: isDark ? AppColors.neutral400 : AppColors.neutral600,
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 🗺️ Xaritadan yangi manzil tanlash tugmasi
            Material(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(18),
              elevation: 2,
              shadowColor: Colors.black.withValues(alpha: 0.06),
              child: InkWell(
                onTap: () async {
                  HapticFeedback.lightImpact();
                  final result = await context.push<Map<String, dynamic>>('/map-picker');
                  if (!mounted) return;
                  if (result != null) {
                    final lat = result['lat'] as double?;
                    final lng = result['lng'] as double?;
                    final address = result['address'] as String?;
                    if (lat != null && lng != null && address != null) {
                      context.read<CheckoutCubit>().setAddressAndCalculateDelivery(lat, lng, address);
                      setState(() {});
                    }
                  }
                },
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: hasAddressError
                          ? AppColors.error
                          : (state.address != null
                              ? AppColors.primary
                              : (isDark ? AppColors.darkBorder : AppColors.neutral200)),
                      width: hasAddressError ? 1.5 : (state.address != null ? 1.5 : 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (hasAddressError ? AppColors.error : AppColors.primary).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.location_on_rounded,
                          color: hasAddressError ? AppColors.error : AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              state.address ?? 'checkout.pick_on_map'.tr(),
                              style: AppTextStyles.labelLarge.copyWith(
                                fontWeight: FontWeight.w700,
                                color: state.address != null
                                    ? (isDark ? Colors.white : AppColors.neutral900)
                                    : (hasAddressError ? AppColors.error : AppColors.primary),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (state.address != null) ...[
                              const SizedBox(height: 4),
                              if (state.loadingDelivery)
                                Text('checkout.calculating'.tr(), style: AppTextStyles.bodySmall)
                              else
                                Text(
                                  'Yetkazish: ${NumberFormatter.formatSum(state.deliveryPrice.toInt())} ${'common.currency'.tr()} • ~35 daq',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.success,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: hasAddressError ? AppColors.error : AppColors.neutral400,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (hasAddressError) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 14, color: AppColors.error),
                    const SizedBox(width: 6),
                    Text(
                      'checkout.select_address_error'.tr(),
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),

            // 📝 Manzil va kurer uchun izoh (xonadon, podyezd, mo'ljal)
            Text(
              'checkout.comment'.tr(),
              style: AppTextStyles.h4.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.neutral900,
              ),
            ),
            const SizedBox(height: 8),
            AppTextField(
              controller: _commentController,
              hintText: 'checkout.comment_hint'.tr(),
              prefixIcon: Icons.notes_rounded,
              maxLines: 2,
              onChanged: (val) {
                context.read<CheckoutCubit>().setComment(val);
                setState(() {});
              },
            ),
          ] else ...[
            // 🏃 Agar Olib ketish bo'lsa: Filiallar ro'yxati
            Text(
              'checkout.branch'.tr(),
              style: AppTextStyles.h4.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.neutral900,
              ),
            ),
            const SizedBox(height: 10),
            if (_branches.isEmpty)
              const Center(child: CircularProgressIndicator(color: AppColors.primary))
            else ...[
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _branches.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final branch = _branches[index];
                  final isSelected = state.branchId == branch.id;

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.read<CheckoutCubit>().setBranch(branch.id, branchTitle: branch.title);
                      setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.08)
                            : (isDark ? AppColors.darkCard : Colors.white),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : (hasBranchError
                                  ? AppColors.error.withValues(alpha: 0.6)
                                  : (isDark ? AppColors.darkBorder : AppColors.neutral200)),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                            color: isSelected ? AppColors.primary : AppColors.neutral400,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  branch.title,
                                  style: AppTextStyles.labelLarge.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : AppColors.neutral900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Har kuni 10:00 - 23:00',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: isDark ? AppColors.neutral400 : AppColors.neutral600,
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
              ),
              if (hasBranchError) ...[
                const SizedBox(height: 6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 14, color: AppColors.error),
                      const SizedBox(width: 6),
                      Text(
                        'checkout.select_branch_error'.tr(),
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
          const SizedBox(height: 24),

          // Qabul qiluvchi ma'lumotlari (Ism & Telefon)
          Text(
            'checkout.recipient'.tr(),
            style: AppTextStyles.h4.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.neutral900,
            ),
          ),
          const SizedBox(height: 10),
          AppTextField(
            controller: _guestNameController,
            hintText: 'Ismingiz',
            prefixIcon: Icons.person_outline_rounded,
            errorText: _showStep1ValidationErrors && _guestNameController.text.trim().isEmpty
                ? 'checkout.enter_name_error'.tr()
                : null,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          if (_isLoggedIn) ...[
            // 🔒 Asosiy tizimga ulangan telefon raqami (o'zgartirilmaydi)
            AppTextField(
              controller: _guestPhoneController,
              enabled: false,
              hintText: '+998 90 123 45 67',
              prefixIcon: Icons.phone_android_rounded,
              suffixIcon: const Padding(
                padding: EdgeInsets.only(right: 12),
                child: Icon(Icons.lock_outline_rounded, size: 18, color: AppColors.neutral400),
              ),
            ),
            const SizedBox(height: 10),
            // 📞 Qo'shimcha telefon raqami (ixtiyoriy)
            AppTextField(
              controller: _additionalPhoneController,
              hintText: "Qo'shimcha telefon raqami (ixtiyoriy)",
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                PhoneNumberFormatter(),
              ],
              onChanged: (_) => setState(() {}),
            ),
          ] else ...[
            AppTextField(
              controller: _guestPhoneController,
              hintText: '+998 90 123 45 67',
              keyboardType: TextInputType.phone,
              prefixIcon: Icons.phone_outlined,
              errorText: _showStep1ValidationErrors &&
                      _guestPhoneController.text.replaceAll(RegExp(r'\D'), '').length < 9
                  ? 'checkout.enter_phone_error'.tr()
                  : null,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                PhoneNumberFormatter(),
              ],
              onChanged: (_) => setState(() {}),
            ),
          ],
          const SizedBox(height: 32),

          // ➡️ 1-Qadam Pastki Tugmasi
          Builder(
            builder: (context) {
              final isValid = _isStep1Valid(state);
              return SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (!isValid) {
                      HapticFeedback.mediumImpact();
                      setState(() => _showStep1ValidationErrors = true);
                      return;
                    }
                    _goToStep(1);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isValid
                        ? AppColors.primary
                        : (isDark ? AppColors.neutral800 : AppColors.neutral300),
                    foregroundColor: isValid
                        ? Colors.white
                        : (isDark ? AppColors.neutral500 : AppColors.neutral600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: isValid ? 3 : 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'checkout.next'.tr(),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: isValid
                              ? Colors.white
                              : (isDark ? AppColors.neutral500 : AppColors.neutral600),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 20,
                        color: isValid
                            ? Colors.white
                            : (isDark ? AppColors.neutral500 : AppColors.neutral600),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // ── 💳 2-QADAM: To'lov usuli va Promokodlar ──
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildStep2PaymentAndPromo(
    CheckoutState state,
    List<PaymentMethodEntity> paymentMethods,
    double subtotal,
    double discount,
    bool isDark,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Promokod (Ixtiyoriy)
          if (!_showPromoField && state.appliedPromoCode == null) ...[
            Material(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(16),
              elevation: 1,
              shadowColor: Colors.black.withValues(alpha: 0.04),
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _showPromoField = true);
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.neutral200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.confirmation_number_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'checkout.have_promo_code'.tr(),
                          style: AppTextStyles.labelMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.neutral900,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.add_circle_outline_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'cart.promo'.tr(),
                  style: AppTextStyles.h4.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.neutral900,
                  ),
                ),
                if (state.appliedPromoCode == null)
                  TextButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      setState(() => _showPromoField = false);
                    },
                    icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 18, color: AppColors.neutral500),
                    label: Text(
                      'common.hide'.tr(),
                      style: const TextStyle(fontSize: 12, color: AppColors.neutral500, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.neutral200),
                boxShadow: AppColors.softShadow(isDark),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _promoController,
                          decoration: InputDecoration(
                            hintText: 'checkout.promo_hint'.tr(),
                            hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral400),
                            prefixIcon: const Icon(Icons.confirmation_number_outlined, color: AppColors.primary),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          textCapitalization: TextCapitalization.characters,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          final code = _promoController.text.trim();
                          if (code.isNotEmpty) {
                            context.read<CheckoutCubit>().applyPromo(code, subtotal);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        child: Text('cart.apply'.tr()),
                      ),
                    ],
                  ),
                  if (state.appliedPromoCode != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${state.appliedPromoCode} (-${NumberFormatter.formatSum(discount.toInt())} ${'common.currency'.tr()})',
                              style: const TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.neutral600),
                            onPressed: () {
                              _promoController.clear();
                              context.read<CheckoutCubit>().clearPromo();
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (state.promoError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      state.promoError!,
                      style: const TextStyle(color: AppColors.error, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),

          // 2. To'lov usullari (1 qatorda 2 ta ustun - Naqd & Payme)
          Text(
            'checkout.payment'.tr(),
            style: AppTextStyles.h4.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.neutral900,
            ),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _buildPaymentOptionColumn(
                  title: 'checkout.cash_payment'.tr(),
                  subtitle: 'Kurerga to\'lash',
                  icon: Icons.payments_outlined,
                  isSelected: state.selectedPaymentMethodKey == '0' || state.selectedPaymentMethodKey == 'cash',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context.read<CheckoutCubit>().setPaymentMethod('0');
                  },
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPaymentOptionColumn(
                  title: 'Payme',
                  subtitle: 'Online to\'lov',
                  icon: Icons.account_balance_wallet_rounded,
                  isSelected: state.selectedPaymentMethodKey == '1' || state.selectedPaymentMethodKey == 'payme',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context.read<CheckoutCubit>().setPaymentMethod('1');
                  },
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // ➡️ 2-Qadam Pastki Tugmalari (Orqaga / Oldinga)
          Row(
            children: [
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => _goToStep(0),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text('checkout.prev_step'.tr()),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => _goToStep(2),
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
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // ── 📋 3-QADAM: Tasdiqlash, Izoh va To'lovga o'tish ──
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildStep3ReviewAndSubmit(
    CheckoutState checkoutState,
    CartState cartState,
    List<PaymentMethodEntity> paymentMethods,
    double subtotal,
    double deliveryFee,
    double discount,
    double finalTotal,
    bool isDark,
  ) {
    final isOnlinePayment = checkoutState.selectedPaymentMethodKey == '1' ||
        checkoutState.selectedPaymentMethodKey == 'payme';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Manzil & To'lov Rezyumesi (O'zgartirish tugmalari bilan)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.neutral200),
              boxShadow: AppColors.softShadow(isDark),
            ),
            child: Column(
              children: [
                // Manzil qatori
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        checkoutState.isDelivery ? Icons.delivery_dining_rounded : Icons.storefront_rounded,
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
                            checkoutState.isDelivery ? 'checkout.delivery_location'.tr() : 'checkout.pickup_location'.tr(),
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral400),
                          ),
                          Text(
                            checkoutState.isDelivery
                                ? (checkoutState.address ?? '')
                                : (checkoutState.branchTitle ?? 'Filial'),
                            style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _goToStep(0),
                      child: Text('common.change'.tr(), style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                Divider(color: isDark ? AppColors.darkBorder : AppColors.neutral200, height: 16),

                // Qabul qiluvchi & Telefon qatori
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_rounded, color: AppColors.info, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'checkout.recipient'.tr(),
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral400),
                          ),
                          Text(
                            _guestNameController.text.trim().isNotEmpty
                                ? '${_guestNameController.text.trim()} • ${_guestPhoneController.text.trim()}'
                                : _guestPhoneController.text.trim(),
                            style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_additionalPhoneController.text.trim().isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Qo\'shimcha tel: ${_additionalPhoneController.text.trim()}',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: isDark ? AppColors.neutral400 : AppColors.neutral600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _goToStep(0),
                      child: Text('common.change'.tr(), style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                Divider(color: isDark ? AppColors.darkBorder : AppColors.neutral200, height: 16),

                // To'lov qatori
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.payment_rounded, color: AppColors.success, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'checkout.payment_method_title'.tr(),
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral400),
                          ),
                          Text(
                            _getPaymentMethodTitle(checkoutState, paymentMethods),
                            style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => _goToStep(1),
                      child: Text('common.change'.tr(), style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Buyurtma tarkibi
          Text(
            'checkout.order_items_title'.tr(),
            style: AppTextStyles.h4.copyWith(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.neutral900,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.neutral200),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cartState.items.length,
              separatorBuilder: (_, __) => Divider(color: isDark ? AppColors.darkBorder : AppColors.neutral200, height: 14),
              itemBuilder: (context, index) {
                final item = cartState.items[index];
                return Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 42,
                        height: 42,
                        color: isDark ? AppColors.neutral800 : AppColors.neutral100,
                        child: const PizzaImagePlaceholder(fit: BoxFit.contain),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.product.title,
                            style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (item.variant != null)
                            Text(
                              item.variant!.title,
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral500, fontSize: 11),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      '${item.quantity} × ${NumberFormatter.formatSum(item.unitPrice.toInt())}',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral600),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${NumberFormatter.formatSum(item.totalPrice.toInt())} ${'common.currency'.tr()}',
                      style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w800, color: AppColors.primary),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // 3. Buyurtmaga izoh (Ixtiyoriy)
          if (_commentController.text.trim().isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : const Color(0xFFF8F9FA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.neutral200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.notes_rounded, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'checkout.comment'.tr(),
                          style: AppTextStyles.labelSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.neutral400 : AppColors.neutral600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _commentController.text.trim(),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: isDark ? Colors.white : AppColors.neutral900,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else if (!_showCommentField) ...[
            Material(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(16),
              elevation: 1,
              shadowColor: Colors.black.withValues(alpha: 0.04),
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _showCommentField = true);
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.neutral200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'checkout.add_comment_optional'.tr(),
                          style: AppTextStyles.labelMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.neutral900,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.add_circle_outline_rounded,
                        color: AppColors.primary,
                        size: 22,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'checkout.comment'.tr(),
                  style: AppTextStyles.h4.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.neutral900,
                  ),
                ),
                if (_commentController.text.trim().isEmpty)
                  TextButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      setState(() => _showCommentField = false);
                    },
                    icon: const Icon(Icons.keyboard_arrow_up_rounded, size: 18, color: AppColors.neutral500),
                    label: Text(
                      'common.hide'.tr(),
                      style: const TextStyle(fontSize: 12, color: AppColors.neutral500, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            AppTextField(
              controller: _commentController,
              hintText: 'checkout.comment_hint'.tr(),
              maxLines: 2,
              prefixIcon: Icons.chat_bubble_outline_rounded,
              onChanged: (val) {
                context.read<CheckoutCubit>().setComment(val);
                setState(() {});
              },
            ),
          ],
          const SizedBox(height: 20),

          // 4. Hisob-kitob (Chek)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.neutral200),
              boxShadow: AppColors.softShadow(isDark),
            ),
            child: Column(
              children: [
                _buildReceiptRow('cart.subtotal'.tr(), '${NumberFormatter.formatSum(subtotal.toInt())} ${'common.currency'.tr()}'),
                const SizedBox(height: 8),
                _buildReceiptRow(
                  'cart.delivery'.tr(),
                  deliveryFee == 0
                      ? 'checkout.free'.tr()
                      : '${NumberFormatter.formatSum(deliveryFee.toInt())} ${'common.currency'.tr()}',
                  valueColor: deliveryFee == 0 ? AppColors.success : null,
                ),
                if (discount > 0) ...[
                  const SizedBox(height: 8),
                  _buildReceiptRow(
                    'cart.discount'.tr(),
                    '-${NumberFormatter.formatSum(discount.toInt())} ${'common.currency'.tr()}',
                    valueColor: AppColors.success,
                  ),
                ],
                Divider(color: isDark ? AppColors.darkBorder : AppColors.neutral200, height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'cart.total'.tr(),
                      style: AppTextStyles.h3.copyWith(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    Text(
                      '${NumberFormatter.formatSum(finalTotal.toInt())} ${'common.currency'.tr()}',
                      style: AppTextStyles.h2.copyWith(
                        color: AppColors.primary,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 🚀 5. Yakuniy harakat tugmasi (Order Submit / Online Payment)
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isSubmittingOrder
                  ? null
                  : () => _handleSubmitOrder(checkoutState, cartState, paymentMethods),
              style: ElevatedButton.styleFrom(
                backgroundColor: isOnlinePayment ? const Color(0xFF00CCCC) : AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 4,
              ),
              child: _isSubmittingOrder
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(isOnlinePayment ? Icons.lock_outline_rounded : Icons.check_circle_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          isOnlinePayment ? 'checkout.pay_online_btn'.tr() : 'checkout.submit_order'.tr(),
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // ── SUB-WIDGETS & ORDER EXECUTION ──
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildTypeSegment({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : (isDark ? AppColors.neutral400 : AppColors.neutral600),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : (isDark ? AppColors.neutral400 : AppColors.neutral700),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 14,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOptionColumn({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.08)
              : (isDark ? AppColors.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.neutral200),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: AppColors.softShadow(isDark),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? AppColors.neutral800 : AppColors.neutral100),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.white : AppColors.neutral600,
                    size: 20,
                  ),
                ),
                Icon(
                  isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                  color: isSelected ? AppColors.primary : AppColors.neutral400,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: AppTextStyles.labelLarge.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: isDark ? Colors.white : AppColors.neutral900,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTextStyles.bodySmall.copyWith(
                color: isDark ? AppColors.neutral400 : AppColors.neutral600,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral600)),
        Text(
          value,
          style: AppTextStyles.labelLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Future<void> _handleSubmitOrder(
    CheckoutState checkoutState,
    CartState cartState,
    List<PaymentMethodEntity> paymentMethods,
  ) async {
    // 1. Agar foydalanuvchi tizimga kirmagan bo'lsa: OTP orqali tasdiqlash
    if (!_isLoggedIn) {
      final name = _guestNameController.text.trim();
      final phone = _guestPhoneController.text.trim();

      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('checkout.enter_name_error'.tr()), backgroundColor: AppColors.error),
        );
        return;
      }

      final digits = phone.replaceAll(RegExp(r'\D'), '');
      if (digits.length < 9) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('checkout.enter_phone_error'.tr()), backgroundColor: AppColors.error),
        );
        return;
      }

      final fullPhone = digits.startsWith('998') ? '+$digits' : '+998$digits';

      try {
        final authDs = getIt<AuthRemoteDataSource>();
        final res = await authDs.loginWithChannel(
          fullName: name.isNotEmpty ? name : 'Mijoz',
          phone: fullPhone,
        );
        final channel = res['channel']?.toString() ?? 'sms';

        if (!mounted) return;
        final verified = await CheckoutOtpSheet.show(
          context,
          phone: fullPhone,
          fullName: name,
          initialChannel: channel,
        );

        if (verified != true) return;
        await _loadUserData();
        if (!mounted) return;
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is ApiException ? e.message : 'auth.login_error'.tr()), backgroundColor: AppColors.error),
        );
        return;
      }
    }

    setState(() => _isSubmittingOrder = true);

    // Manzilni eslab qolish (Save to recent addresses for next orders)
    if (checkoutState.isDelivery && checkoutState.address != null && checkoutState.lat != null) {
      SecureStorage.saveAddress(
        SavedAddressModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          label: 'Manzil',
          address: checkoutState.address!,
          lat: checkoutState.lat!,
          lng: checkoutState.lng!,
          comment: _commentController.text.trim(),
        ),
      );
    }

    final products = cartState.items.map((item) {
      final vId = item.variant?.id ?? item.product.variants.firstOrNull?.id;
      final effectiveVariantId = (vId != null && vId > 0) ? vId : item.product.id;
      return {
        'id': effectiveVariantId,
        'variant_id': effectiveVariantId,
        'product_id': item.product.id,
        'quantity': item.quantity,
      };
    }).toList();

    final extraPhone = _additionalPhoneController.text.trim();
    String effectiveComment = _commentController.text.trim();
    if (extraPhone.isNotEmpty) {
      if (effectiveComment.isNotEmpty) {
        effectiveComment = '$effectiveComment (Qo\'shimcha tel: $extraPhone)';
      } else {
        effectiveComment = 'Qo\'shimcha tel: $extraPhone';
      }
    }

    if (!mounted) return;
    context.read<CheckoutCubit>().submitOrder(
          products: products,
          commentOverride: effectiveComment.isNotEmpty ? effectiveComment : null,
        );
  }

  void _handleSuccess(Map<String, dynamic> data) async {
    final orderId = data['order_id']?.toString() ?? data['id']?.toString() ?? '';
    final totalAmount = double.tryParse(data['total_price']?.toString() ?? '') ?? 0;
    final paymentMethod = data['payment_method_text']?.toString() ?? 'unknown';

    AnalyticsService.instance.logOrderPlaced(
      orderId: orderId,
      totalAmount: totalAmount,
      paymentMethod: paymentMethod,
      isDelivery: context.read<CheckoutCubit>().state.isDelivery,
    );

    OrderEntity? orderEntity;
    try {
      orderEntity = OrderModel.fromJson(data);
    } catch (_) {}

    // ⚡ Online to'lov (Payme URL) bo'lsa darhol ochish
    final paymentUrl = data['payment_url'] as String?;
    if (paymentUrl != null && paymentUrl.isNotEmpty) {
      final uri = Uri.tryParse(paymentUrl);
      if (uri != null) {
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (e) {
          debugPrint('Could not launch payment URL: $e');
        }
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('checkout.order_placed'.tr()),
        backgroundColor: AppColors.success,
      ));
      context.read<CartCubit>().clear();
      context.read<CheckoutCubit>().resetAfterOrder();
      if (orderId.isNotEmpty) {
        context.go('/order/$orderId', extra: orderEntity);
      } else {
        context.go('/orders');
      }
    }
  }
}

class CheckoutBranch {
  final String id;
  final String title;
  final double latitude;
  final double longitude;

  CheckoutBranch({
    required this.id,
    required this.title,
    required this.latitude,
    required this.longitude,
  });

  factory CheckoutBranch.fromJson(Map<String, dynamic> json) {
    return CheckoutBranch(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      latitude: double.tryParse(json['latitude']?.toString() ?? '0') ?? 0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '0') ?? 0,
    );
  }
}
