import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pizza_strada/core/models/saved_address_model.dart';
import 'package:pizza_strada/core/storage/secure_storage.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/features/cart/presentation/bloc/checkout/checkout_cubit.dart';

/// 📍 100% Native Saved Addresses Page
class SavedAddressesPage extends StatefulWidget {
  const SavedAddressesPage({super.key});

  @override
  State<SavedAddressesPage> createState() => _SavedAddressesPageState();
}

class _SavedAddressesPageState extends State<SavedAddressesPage> {
  List<SavedAddressModel> _addresses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() => _isLoading = true);
    final list = await SecureStorage.getSavedAddresses();
    if (mounted) {
      setState(() {
        _addresses = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteAddress(String id) async {
    setState(() {
      _addresses.removeWhere((a) => a.id == id);
    });
    // Persist removal
    final current = await SecureStorage.getSavedAddresses();
    current.removeWhere((a) => a.id == id);
    await SecureStorage.clearAll();
    for (final a in current) {
      await SecureStorage.saveAddress(a);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Manzil o\'chirildi'.tr()),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _selectAddress(SavedAddressModel address) {
    context.read<CheckoutCubit>().setAddressAndCalculateDelivery(
      address.lat,
      address.lng,
      address.address,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Yetkazib berish manzili tanlandi: ${address.address}'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
    Navigator.of(context).pop();
  }

  void _showAddAddressSheet() {
    final titleCtrl = TextEditingController(text: 'Uy');
    final streetCtrl = TextEditingController();
    final aptCtrl = TextEditingController();
    final floorCtrl = TextEditingController();
    final entranceCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.neutral300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Yangi manzil qo\'shish',
                    style: AppTextStyles.h3.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.neutral900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Label (Uy, Ishxona)
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: 'Manzil nomi (Masalan: Uy, Ishxona)',
                      prefixIcon: const Icon(Icons.bookmark_outline_rounded, color: AppColors.primary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Street & building
                  TextField(
                    controller: streetCtrl,
                    decoration: InputDecoration(
                      labelText: 'Ko\'cha va uy raqami *',
                      hintText: 'Masalan: Oltinvodiy ko\'chasi, 42-uy',
                      prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Apt & floor
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: aptCtrl,
                          decoration: InputDecoration(
                            labelText: 'Xonadon',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: floorCtrl,
                          decoration: InputDecoration(
                            labelText: 'Qavat',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: entranceCtrl,
                          decoration: InputDecoration(
                            labelText: 'Podyezd',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: () async {
                      final street = streetCtrl.text.trim();
                      if (street.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Iltimos, ko\'cha va uy raqamini kiriting')),
                        );
                        return;
                      }

                      final label = titleCtrl.text.trim().isNotEmpty ? titleCtrl.text.trim() : 'Manzil';
                      final commentParts = [
                        if (aptCtrl.text.trim().isNotEmpty) '${aptCtrl.text.trim()}-xonadon',
                        if (entranceCtrl.text.trim().isNotEmpty) '${entranceCtrl.text.trim()}-podyezd',
                        if (floorCtrl.text.trim().isNotEmpty) '${floorCtrl.text.trim()}-qavat',
                      ];

                      final newAddress = SavedAddressModel(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        label: label,
                        address: street,
                        lat: 39.6542,
                        lng: 66.9597,
                        comment: commentParts.join(', '),
                      );

                      await SecureStorage.saveAddress(newAddress);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                      }
                      if (mounted) {
                        _loadAddresses();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Saqlash', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkSurface : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          'profile.saved_addresses'.tr(),
          style: AppTextStyles.h3.copyWith(
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppColors.neutral900,
          ),
        ),
        centerTitle: true,
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : AppColors.neutral900, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _addresses.isEmpty
              ? _buildEmptyState(isDark)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: _addresses.length,
                  itemBuilder: (context, index) {
                    final address = _addresses[index];
                    return _buildAddressCard(context, address, isDark);
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAddressSheet,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Yangi manzil', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_on_outlined, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'profile.no_saved_addresses'.tr(),
              style: AppTextStyles.h4.copyWith(
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : AppColors.neutral900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'profile.no_saved_addresses_desc'.tr(),
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddAddressSheet,
              icon: const Icon(Icons.add_location_alt_rounded),
              label: const Text('Manzil qo\'shish'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(BuildContext context, SavedAddressModel address, bool isDark) {
    final isHome = address.label.toLowerCase().contains('uy') || address.label.toLowerCase().contains('дом');
    final isWork = address.label.toLowerCase().contains('ish') || address.label.toLowerCase().contains('работа');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.neutral200.withValues(alpha: 0.7),
        ),
        boxShadow: AppColors.softShadow(isDark),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isHome
                  ? Icons.home_rounded
                  : (isWork ? Icons.work_rounded : Icons.location_on_rounded),
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: InkWell(
              onTap: () => _selectAddress(address),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    address.label,
                    style: AppTextStyles.labelLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.neutral900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    address.address,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: isDark ? AppColors.neutral400 : AppColors.neutral600,
                      height: 1.3,
                    ),
                  ),
                  if (address.comment != null && address.comment!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      address.comment!,
                      style: AppTextStyles.bodyExtraSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.neutral400, size: 20),
            onPressed: () => _deleteAddress(address.id),
          ),
        ],
      ),
    );
  }
}
