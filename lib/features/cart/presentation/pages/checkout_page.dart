import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/cart_cubit.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  bool _isDelivery = true;
  final _addressController = TextEditingController();
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _addressController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text("checkout.title".tr()),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Delivery Toggle
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.neutral100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  _buildToggleItem(
                    title: "checkout.delivery".tr(),
                    isActive: _isDelivery,
                    onTap: () => setState(() => _isDelivery = true),
                  ),
                  _buildToggleItem(
                    title: "checkout.pickup".tr(),
                    isActive: !_isDelivery,
                    onTap: () => setState(() => _isDelivery = false),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Address Section
            if (_isDelivery) ...[
              Text("checkout.address".tr(), style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              _buildCardField(
                child: TextField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    hintText: "checkout.select_address".tr(),
                    hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral400),
                    border: InputBorder.none,
                    suffixIcon: const Icon(Icons.map_rounded, color: AppColors.primary),
                  ),
                  onTap: () => context.push('/map-picker'),
                  readOnly: true,
                ),
              ),
            ] else ...[
              Text("checkout.branch".tr(), style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              _buildCardField(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Pizza Strada (Asosiy filial)", style: AppTextStyles.bodyMedium),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.neutral400),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),

            // Comment
            Text("checkout.comment".tr(), style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            _buildCardField(
              child: TextField(
                controller: _commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "checkout.comment".tr() + "...",
                  hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral400),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Order Summary
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: BlocBuilder<CartCubit, CartState>(
                builder: (context, state) {
                  final deliveryFee = _isDelivery ? 15000 : 0;
                  final total = state.subtotal + deliveryFee;
                  
                  return Column(
                    children: [
                      _buildRow("cart.subtotal".tr(), "${state.subtotal.toInt()} so'm"),
                      const SizedBox(height: 12),
                      _buildRow("cart.delivery".tr(), "$deliveryFee so'm"),
                      const Divider(height: 32, color: AppColors.neutral100),
                      _buildRow("cart.total".tr(), "${total.toInt()} so'm", isTotal: true),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -4)),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 54,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                context.go('/orders');
                context.read<CartCubit>().clear();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Buyurtma qabul qilindi".tr()),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Text("checkout.confirm".tr()),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleItem({required String title, required bool isActive, required VoidCallback onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isActive ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : null,
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: AppTextStyles.labelMedium.copyWith(
              color: isActive ? AppColors.primary : AppColors.neutral600,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardField({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral100, width: 1),
      ),
      child: child,
    );
  }

  Widget _buildRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: isTotal ? AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700) : AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral400)),
        Text(value, style: isTotal ? AppTextStyles.h2.copyWith(color: AppColors.primary) : AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
