import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/core/widgets/app_button.dart';
import 'package:pizza_strada/core/di/injection.dart';
import 'package:pizza_strada/features/auth/domain/entities/user_entity.dart';
import 'package:pizza_strada/features/auth/domain/usecases/update_profile_usecase.dart';
import 'package:pizza_strada/core/storage/secure_storage.dart';

class EditProfilePage extends StatefulWidget {
  final UserEntity user;
  
  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  String? _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.fullName);
    _phoneController = TextEditingController(text: widget.user.phone);
    _selectedDate = widget.user.birthdate;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _selectedDate != null 
        ? DateTime.tryParse(_selectedDate!) ?? now 
        : now;
    
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    setState(() => _isLoading = true);
    
    final updateProfile = getIt<UpdateProfileUseCase>();
    final result = await updateProfile(
      fullName: name,
      birthdate: _selectedDate,
    );
    
    if (mounted) {
      setState(() => _isLoading = false);
      result.fold(
        (failure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(failure.messageKey),
              backgroundColor: AppColors.error,
            )
          );
        },
        (user) async {
          await SecureStorage.saveUserInfo(name: user.fullName, phone: user.phone);
          if (mounted) {
            context.pop(user); // Return updated user
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('profile.edit'.tr()),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).iconTheme.color, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('auth.full_name'.tr(), style: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral500)),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'auth.name_hint'.tr(),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color),
            ),
            const SizedBox(height: 16),
            Text('auth.phone'.tr(), style: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral500)),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              enabled: false,
              decoration: InputDecoration(
                hintText: '',
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral500),
            ),
            const SizedBox(height: 16),
            Text('profile.birthdate'.tr(), style: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral500)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.neutral300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedDate ?? 'YYYY-MM-DD',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: _selectedDate != null 
                            ? Theme.of(context).textTheme.bodyMedium?.color
                            : AppColors.neutral500,
                      ),
                    ),
                    const Icon(Icons.calendar_month, color: AppColors.neutral500, size: 20),
                  ],
                ),
              ),
            ),
            const Spacer(),
            AppButton(
              onTap: _isLoading ? null : _save,
              text: 'profile.save'.tr(),
              isLoading: _isLoading,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
