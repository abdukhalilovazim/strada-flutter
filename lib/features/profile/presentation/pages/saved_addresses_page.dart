import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pizza_strada/core/models/saved_address_model.dart';
import 'package:pizza_strada/core/network/api_client.dart';
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

    // 1. Mahalliy saqlangan manzillar
    final localList = await SecureStorage.getSavedAddresses();
    final addressMap = <String, SavedAddressModel>{};
    for (final a in localList) {
      final key = a.address.trim().toLowerCase();
      if (key.isNotEmpty) addressMap[key] = a;
    }

    // 2. Foydalanuvchining backenddagi saqlangan manzillarini olish (/api/v1/addresses)
    try {
      final token = await SecureStorage.getToken();
      if (token != null && token.isNotEmpty) {
        final response = await ApiClient().get('addresses');
        final dynamic rawAddresses = (response is Map && response['data'] != null)
            ? response['data']
            : response;

        if (rawAddresses is List) {
          for (final item in rawAddresses) {
            if (item is Map<String, dynamic>) {
              final serverAddr = SavedAddressModel.fromJson(item);
              if (serverAddr.address.trim().isNotEmpty) {
                final key = serverAddr.address.trim().toLowerCase();
                addressMap[key] = serverAddr;
                await SecureStorage.saveAddress(serverAddr);
              }
            }
          }
        }
      }
    } catch (_) {
      // Tarmoq xatosi yoki oflayn holatda localList ishlatiladi
    }

    final merged = addressMap.values.toList();
    if (mounted) {
      setState(() {
        _addresses = merged;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteAddress(String id) async {
    final target = _addresses.where((a) => a.id == id).firstOrNull;
    final isServer = target != null
        ? target.isServerId
        : (!id.startsWith('local_') && int.tryParse(id) != null && int.parse(id) < 1000000000);

    setState(() {
      _addresses.removeWhere((a) => a.id == id);
    });
    await SecureStorage.deleteAddress(id);

    // Faqat haqiqiy server ID bo'lsa backenddan o'chirish (mahalliy timestamp bo'lsa serverga so'rov ketmaydi)
    if (isServer) {
      try {
        await ApiClient().delete('addresses/$id');
      } catch (_) {}
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('profile.address_deleted'.tr()),
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
        content: Text('profile.address_selected'.tr(namedArgs: {'address': address.address})),
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
    double selectedLat = 39.6542;
    double selectedLng = 66.9597;

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
                    style: AppTextStyles.h4.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: isDark ? Colors.white : AppColors.neutral900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),

                  // Xaritadan aniq tanlash tugmasi (Map Picker Access)
                  InkWell(
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      final result = await context.push<Map<String, dynamic>>('/map-picker');
                      if (result != null && result['address'] != null) {
                        streetCtrl.text = result['address'] as String;
                        if (result['lat'] != null) selectedLat = (result['lat'] as num).toDouble();
                        if (result['lng'] != null) selectedLng = (result['lng'] as num).toDouble();
                      }
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.map_rounded, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Xaritadan aniq tanlash',
                                  style: AppTextStyles.labelMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                                Text(
                                  'Joylashuvingizni xaritada belgilang',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: isDark ? AppColors.neutral400 : AppColors.neutral500,
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primary, size: 14),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Label (Uy, Ishxona)
                  TextField(
                    controller: titleCtrl,
                    autocorrect: false,
                    enableSuggestions: false,
                    spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
                    textInputAction: TextInputAction.next,
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
                    autocorrect: false,
                    enableSuggestions: false,
                    spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      labelText: 'Ko\'cha va uy raqami *',
                      hintText: 'Masalan: Oltinvodiy ko\'chasi, 42-uy',
                      prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.my_location_rounded, color: AppColors.primary, size: 20),
                        tooltip: 'Xaritadan tanlash',
                        onPressed: () async {
                          HapticFeedback.lightImpact();
                          final result = await context.push<Map<String, dynamic>>('/map-picker');
                          if (result != null && result['address'] != null) {
                            streetCtrl.text = result['address'] as String;
                            if (result['lat'] != null) selectedLat = (result['lat'] as num).toDouble();
                            if (result['lng'] != null) selectedLng = (result['lng'] as num).toDouble();
                          }
                        },
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Apt, floor, entrance (Row)
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: aptCtrl,
                          autocorrect: false,
                          enableSuggestions: false,
                          spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
                          textInputAction: TextInputAction.next,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'Xonadon',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: floorCtrl,
                          autocorrect: false,
                          enableSuggestions: false,
                          spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
                          textInputAction: TextInputAction.next,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'Qavat',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: entranceCtrl,
                          autocorrect: false,
                          enableSuggestions: false,
                          spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
                          textInputAction: TextInputAction.done,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'Podyezd',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () async {
                        HapticFeedback.lightImpact();
                        final street = streetCtrl.text.trim();
                        if (street.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('profile.enter_street_house_error'.tr())),
                          );
                          return;
                        }

                        final label = titleCtrl.text.trim().isNotEmpty ? titleCtrl.text.trim() : 'Manzil';
                        final commentParts = [
                          if (aptCtrl.text.trim().isNotEmpty) '${aptCtrl.text.trim()}-xonadon',
                          if (entranceCtrl.text.trim().isNotEmpty) '${entranceCtrl.text.trim()}-podyezd',
                          if (floorCtrl.text.trim().isNotEmpty) '${floorCtrl.text.trim()}-qavat',
                        ];

                        final tempLocalId = 'local_${DateTime.now().millisecondsSinceEpoch}';
                        final newAddress = SavedAddressModel(
                          id: tempLocalId,
                          label: label,
                          address: street,
                          lat: selectedLat,
                          lng: selectedLng,
                          comment: commentParts.join(', '),
                        );

                        await SecureStorage.saveAddress(newAddress);

                        try {
                          final token = await SecureStorage.getToken();
                          if (token != null && token.isNotEmpty) {
                            final res = await ApiClient().post('addresses', body: {
                              'label': label,
                              'address': street,
                              'address_text': street,
                              'lat': selectedLat,
                              'latitude': selectedLat,
                              'lng': selectedLng,
                              'longitude': selectedLng,
                            });
                            if (res is Map && res['data'] != null && res['data']['id'] != null) {
                              final serverModel = SavedAddressModel.fromJson(res['data'] as Map<String, dynamic>);
                              await SecureStorage.deleteAddress(tempLocalId);
                              await SecureStorage.saveAddress(serverModel);
                            }
                          }
                        } catch (_) {}

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
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text('profile.save'.tr(), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    ),
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
          style: AppTextStyles.h4.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 17,
            color: isDark ? Colors.white : AppColors.neutral900,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
      floatingActionButton: _addresses.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _showAddAddressSheet,
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(
                'profile.new_address'.tr(),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
            ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_on_outlined, size: 44, color: AppColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              'profile.no_saved_addresses'.tr(),
              style: AppTextStyles.h4.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: isDark ? Colors.white : AppColors.neutral900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'profile.no_saved_addresses_desc'.tr(),
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral500, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _showAddAddressSheet,
                icon: const Icon(Icons.add_location_alt_rounded, size: 18),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'profile.add_address'.tr(),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
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
