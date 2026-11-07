import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:pizza_strada/core/models/saved_address_model.dart';
import 'package:pizza_strada/core/network/api_client.dart';
import 'package:pizza_strada/core/storage/secure_storage.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/core/utils/number_formatter.dart';

/// 👤 Edit Profile & Manage Locations Page
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  DateTime? _selectedBirthDate;

  bool _isLoading = true;
  bool _isSaving = false;
  List<SavedAddressModel> _addresses = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    // 1. Shaxsiy ma'lumotlarni yuklash (Keshdan va API dan)
    final cachedName = await SecureStorage.getUserName();
    final cachedPhone = await SecureStorage.getUserPhone();
    if (cachedName != null && cachedName.isNotEmpty) {
      _fullNameController.text = cachedName;
    }
    if (cachedPhone != null && cachedPhone.isNotEmpty) {
      _phoneController.text = NumberFormatter.formatPhone(cachedPhone);
    }

    try {
      final token = await SecureStorage.getToken();
      if (token != null && token.isNotEmpty) {
        final response = await ApiClient().get('me');
        final data = (response is Map && response['data'] != null)
            ? response['data'] as Map<String, dynamic>
            : (response is Map<String, dynamic> ? response : null);

        if (data != null && mounted) {
          final fullName = data['full_name'] as String?;
          final phone = data['phone'] as String?;
          final birthDateStr = data['birth_date'] as String?;

          if (fullName != null && fullName.isNotEmpty) {
            _fullNameController.text = fullName;
            await SecureStorage.saveUserName(fullName);
          }
          if (phone != null && phone.isNotEmpty) {
            _phoneController.text = NumberFormatter.formatPhone(phone);
            await SecureStorage.saveUserPhone(phone);
          }
          if (birthDateStr != null && birthDateStr.isNotEmpty) {
            _selectedBirthDate = DateTime.tryParse(birthDateStr);
          }
        }
      }
    } catch (_) {}

    // 2. Saqlangan manzillarni yuklash
    await _loadAddresses();

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAddresses() async {
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
    } catch (_) {}

    if (mounted) {
      setState(() {
        _addresses = addressMap.values.toList();
      });
    }
  }

  Future<void> _saveProfile() async {
    final newName = _fullNameController.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('profile.enter_street_house_error'.tr()), // Or name error
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);

    try {
      final birthDateFormatted = _selectedBirthDate != null
          ? DateFormat('yyyy-MM-dd').format(_selectedBirthDate!)
          : null;

      final body = <String, dynamic>{
        'full_name': newName,
        if (birthDateFormatted != null) 'birth_date': birthDateFormatted,
      };

      final token = await SecureStorage.getToken();
      if (token != null && token.isNotEmpty) {
        await ApiClient().put('me', body: body);
      }
      await SecureStorage.saveUserName(newName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil ma\'lumotlari muvaffaqiyatli saqlandi ✨'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      // Offline fallback: save locally
      await SecureStorage.saveUserName(newName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ma\'lumotlar qurilmada saqlandi'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _pickBirthDate() async {
    HapticFeedback.lightImpact();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(now.year - 20, now.month, now.day),
      firstDate: DateTime(1920),
      lastDate: now,
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: isDark ? Colors.white : AppColors.neutral900,
              surface: isDark ? AppColors.darkCard : Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      setState(() => _selectedBirthDate = picked);
    }
  }

  Future<void> _addNewAddressFromMap() async {
    HapticFeedback.lightImpact();
    final result = await context.push<Map<String, dynamic>>('/map-picker');
    if (result != null && mounted) {
      final lat = (result['lat'] as num?)?.toDouble() ?? 39.6542;
      final lng = (result['lng'] as num?)?.toDouble() ?? 66.9597;
      final address = (result['address'] as String?)?.trim();

      if (address != null && address.isNotEmpty) {
        final newModel = SavedAddressModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          label: address,
          address: address,
          lat: lat,
          lng: lng,
        );

        await SecureStorage.saveAddress(newModel);
        await _loadAddresses();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Yangi manzil muvaffaqiyatli qo\'shildi 📍'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteAddress(SavedAddressModel model) async {
    HapticFeedback.mediumImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Manzilni o\'chirish',
          style: AppTextStyles.h4.copyWith(
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : AppColors.neutral900,
          ),
        ),
        content: Text(
          'Ushbu manzilni ro\'yxatdan o\'chirishni xohlaysizmi?',
          style: AppTextStyles.bodyMedium.copyWith(
            color: isDark ? AppColors.neutral300 : AppColors.neutral600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'common.cancel'.tr(),
              style: TextStyle(
                color: isDark ? AppColors.neutral400 : AppColors.neutral600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'common.delete'.tr(),
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await SecureStorage.deleteAddress(model.id);
      await _loadAddresses();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('profile.address_deleted'.tr()),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  String get _initials {
    final name = _fullNameController.text.trim();
    if (name.isEmpty || name == 'Mijoz') return 'S';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'profile.edit'.tr(),
          style: AppTextStyles.h2.copyWith(
            color: Theme.of(context).textTheme.headlineMedium?.color,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: isDark ? AppColors.neutral800 : AppColors.neutral200,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              children: [
                // 1. Avatar Card
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
                          border: Border.all(
                            color: AppColors.primary,
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _initials,
                            style: AppTextStyles.h2.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 32,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary,
                            border: Border.all(
                              color: isDark ? AppColors.darkSurface : Colors.white,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 2. Shaxsiy ma'lumotlar bloki
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.neutral200,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'Shaxsiy ma\'lumotlar',
                            style: AppTextStyles.h4.copyWith(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: isDark ? Colors.white : AppColors.neutral900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Ism inputi
                      Text(
                        'F.I.SH / Ism',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.neutral500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _fullNameController,
                        autocorrect: false,
                        enableSuggestions: false,
                        spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
                        textCapitalization: TextCapitalization.words,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.neutral900,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Ismingizni kiriting...',
                          prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.primary, size: 20),
                          filled: true,
                          fillColor: isDark ? AppColors.neutral800 : const Color(0xFFF8F9FA),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: isDark ? AppColors.darkBorder : const Color(0xFFEDF2F7),
                              width: 1.2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Telefon inputi (O'zgarmas / Tasdiqlangan)
                      Text(
                        'Telefon raqami (Asosiy)',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.neutral500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _phoneController,
                        readOnly: true,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.neutral300 : AppColors.neutral700,
                        ),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.primary, size: 20),
                          suffixIcon: const Tooltip(
                            message: 'Tasdiqlangan telefon raqami',
                            child: Icon(Icons.lock_outline_rounded, color: AppColors.neutral400, size: 18),
                          ),
                          filled: true,
                          fillColor: isDark ? AppColors.neutral800.withValues(alpha: 0.5) : const Color(0xFFF1F3F5),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: isDark ? AppColors.darkBorder : const Color(0xFFEDF2F7),
                              width: 1.2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Tug'ilgan sana picker
                      Text(
                        'profile.birthdate'.tr(),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.neutral500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: _pickBirthDate,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.neutral800 : const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : const Color(0xFFEDF2F7),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.cake_outlined, color: AppColors.primary, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedBirthDate != null
                                      ? DateFormat('dd.MM.yyyy').format(_selectedBirthDate!)
                                      : 'Tug\'ilgan sanani belgilash (ixtiyoriy)',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: _selectedBirthDate != null ? FontWeight.w700 : FontWeight.w500,
                                    color: _selectedBirthDate != null
                                        ? (isDark ? Colors.white : AppColors.neutral900)
                                        : AppColors.neutral400,
                                  ),
                                ),
                              ),
                              const Icon(Icons.calendar_today_outlined, size: 18, color: AppColors.neutral400),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Saqlash tugmasi
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                                )
                              : Text(
                                  'profile.save'.tr(),
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 3. Mening manzillarim (Location bilan bitta joyda!)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.neutral200,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 22),
                              const SizedBox(width: 8),
                              Text(
                                'profile.saved_addresses'.tr(),
                                style: AppTextStyles.h4.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: isDark ? Colors.white : AppColors.neutral900,
                                ),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: _addNewAddressFromMap,
                            icon: const Icon(Icons.add_location_alt_outlined, size: 16, color: AppColors.primary),
                            label: Text(
                              'profile.add_address'.tr(),
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
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
                      const SizedBox(height: 12),

                      if (_addresses.isEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.neutral800 : const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          alignment: Alignment.center,
                          child: Column(
                            children: [
                              Icon(Icons.map_outlined, size: 36, color: AppColors.neutral400),
                              const SizedBox(height: 8),
                              Text(
                                'Hozircha saqlangan manzillar yo\'q',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.neutral500,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _addresses.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            final item = _addresses[index];
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isDark ? AppColors.neutral800 : const Color(0xFFF8F9FA),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isDark ? AppColors.darkBorder : const Color(0xFFEDF2F7),
                                ),
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
                                    child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.label.isNotEmpty ? item.label : item.address,
                                          style: AppTextStyles.labelMedium.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: isDark ? Colors.white : AppColors.neutral900,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (item.label.isNotEmpty && item.label != item.address) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            item.address,
                                            style: AppTextStyles.bodySmall.copyWith(
                                              color: AppColors.neutral500,
                                              fontSize: 11.5,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                                    onPressed: () => _deleteAddress(item),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
