import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_dimensions.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/core/widgets/app_button.dart';
import 'package:pizza_strada/core/widgets/app_text_field.dart';
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
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        title: Text("Buyurtma", style: AppTextStyles.h2),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDim.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Delivery Toggle
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.neutral100,
                borderRadius: AppDim.radiusMd,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isDelivery = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _isDelivery ? Colors.white : Colors.transparent,
                          borderRadius: AppDim.radiusSm,
                        ),
                        alignment: Alignment.center,
                        child: Text("Yetkazish",
                            style: AppTextStyles.labelMedium.copyWith(
                                color: _isDelivery ? AppColors.primary : AppColors.neutral400)),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isDelivery = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_isDelivery ? Colors.white : Colors.transparent,
                          borderRadius: AppDim.radiusSm,
                        ),
                        alignment: Alignment.center,
                        child: Text("Olib ketish",
                            style: AppTextStyles.labelMedium.copyWith(
                                color: !_isDelivery ? AppColors.primary : AppColors.neutral400)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Address Section
            if (_isDelivery) ...[
              Text("Manzil", style: AppTextStyles.labelLarge),
              const SizedBox(height: 12),
              AppTextField(
                label: "Ko'cha, uy, kvartira",
                controller: _addressController,
                hintText: "Masalan: Buyuk Ipak Yo'li, 12, 1",
                suffix: IconButton(
                  icon: const Icon(Icons.map_outlined, color: AppColors.primary),
                  onPressed: () => context.push('/map-picker'),
                ),
              ),
            ] else ...[
              Text("Filial", style: AppTextStyles.labelLarge),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppDim.radiusMd,
                  border: Border.all(color: AppColors.neutral200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Pizza Strada (Asosiy filial)", style: AppTextStyles.bodyMedium),
                    const Icon(Icons.keyboard_arrow_down, color: AppColors.neutral400),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),

            // Comment
            AppTextField(
              label: "Izoh",
              controller: _commentController,
              hintText: "Kuryer uchun maxsus eslatmalar...",
            ),
            const SizedBox(height: 32),

            // Order Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppDim.radiusLg,
              ),
              child: BlocBuilder<CartCubit, CartState>(
                builder: (context, state) {
                  return Column(
                    children: [
                      _buildRow("Mahsulotlar", "${state.subtotal.toInt()} UZS"),
                      const SizedBox(height: 12),
                      _buildRow("Yetkazish", _isDelivery ? "15,000 UZS" : "0 UZS"),
                      const Divider(height: 32),
                      _buildRow("Jami", "${(state.subtotal + (_isDelivery ? 15000 : 0)).toInt()} UZS", isTotal: true),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(AppDim.lg),
        decoration: const BoxDecoration(color: Colors.white),
        child: SafeArea(
          child: AppButton(
            text: "Tasdiqlash",
            onTap: () {
              // TODO: Confirm order logic
              context.go('/orders');
              context.read<CartCubit>().clear();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Buyurtma qabul qilindi")),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: isTotal ? AppTextStyles.labelLarge : AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral400)),
        Text(value, style: isTotal ? AppTextStyles.h3.copyWith(color: AppColors.primary) : AppTextStyles.labelMedium),
      ],
    );
  }
}
