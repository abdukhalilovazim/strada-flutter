import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/core/widgets/app_button.dart';
import 'package:pizza_strada/core/widgets/app_text_field.dart';
import 'package:pizza_strada/features/auth/presentation/bloc/auth_cubit.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

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
    final user = context.read<AuthCubit>().state.user;
    _nameController = TextEditingController(text: user?.fullName ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _selectedDate = user?.birthdate;
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
    
    await context.read<AuthCubit>().updateProfile(
      fullName: name,
      birthdate: _selectedDate,
    );
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (context.read<AuthCubit>().state.error == null) {
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.read<AuthCubit>().state.error!),
            backgroundColor: Colors.red,
          )
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('profile.edit'.tr()),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
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
            AppTextField(
              controller: _nameController,
              hintText: 'auth.name_hint'.tr(),
            ),
            const SizedBox(height: 16),
            Text('auth.phone'.tr(), style: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral500)),
            const SizedBox(height: 8),
            AppTextField(
              controller: _phoneController,
              hintText: '',
              enabled: false,
            ),
            const SizedBox(height: 16),
            Text('profile.birthdate'.tr(), style: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral500)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
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
              onPressed: _isLoading ? null : _save,
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
