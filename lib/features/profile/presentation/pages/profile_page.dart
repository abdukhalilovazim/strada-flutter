import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pizza_strada/core/storage/secure_storage.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/core/theme/app_icons.dart';
import 'package:pizza_strada/features/home/presentation/bloc/home_cubit.dart';
import 'package:pizza_strada/core/utils/yandex_key_manager.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _name = 'Mijoz';
  String _phone = '';

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final name = await SecureStorage.getUserName();
    final phone = await SecureStorage.getUserPhone();
    if (mounted) {
      setState(() {
        if (name != null) _name = name;
        if (phone != null) _phone = phone;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('profile.title'.tr(), style: AppTextStyles.h2.copyWith(color: AppColors.neutral900)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // User Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.neutral200),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(AppIcons.profile, color: AppColors.primary, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_name, style: AppTextStyles.labelLarge.copyWith(color: AppColors.neutral900)),
                        const SizedBox(height: 4),
                        Text(_phone, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Settings Items
            _buildItem(
              icon: Icons.notifications_none_rounded,
              title: 'profile.notifications'.tr(),
              onTap: () {},
            ),
            _buildItem(
              icon: Icons.language_rounded,
              title: 'profile.change_language'.tr(),
              onTap: () => _showLanguagePicker(),
            ),
            _buildItem(
              icon: Icons.map_rounded,
              title: "Next Map Key (Debug)",
              subtitle: "Xarita ishlamasa bosing va appni restart qiling",
              onTap: () async {
                await YandexMapKeyManager.switchToNextKey();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xarita kaliti o\'zgartirildi. Ilovani restart qiling!')));
                }
              },
            ),
            
            // Phone call from settings
            BlocBuilder<HomeCubit, HomeState>(
              builder: (context, state) {
                String? supportPhone;
                if (state is HomeLoaded) {
                  supportPhone = state.settings?.supportPhone;
                }
                return _buildItem(
                  icon: AppIcons.support,
                  title: 'profile.call_support'.tr(),
                  subtitle: supportPhone,
                  onTap: () async {
                    if (supportPhone != null) {
                      final uri = Uri.parse('tel:$supportPhone');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    }
                  },
                );
              },
            ),

            const SizedBox(height: 32),

            // Logout
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.neutral200),
              ),
              child: ListTile(
                onTap: () async {
                  await SecureStorage.clearAll();
                  if (mounted) context.go('/auth/login');
                },
                leading: const Icon(Icons.logout_rounded, color: AppColors.error, size: 22),
                title: Text('profile.logout'.tr(), style: AppTextStyles.labelLarge.copyWith(color: AppColors.error)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('profile.select_language'.tr(), style: AppTextStyles.h3),
                const SizedBox(height: 20),
                _buildLanguageOption("O'zbek tili", const Locale('uz')),
                _buildLanguageOption("Русский язык", const Locale('ru')),
                _buildLanguageOption("English", const Locale('en')),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(String title, Locale locale) {
    final isSelected = context.locale == locale;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: ListTile(
        title: Text(title, style: AppTextStyles.labelMedium.copyWith(color: isSelected ? AppColors.primary : AppColors.neutral900)),
        trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppColors.primary) : null,
        onTap: () async {
          await context.setLocale(locale);
          if (context.mounted) {
            context.read<HomeCubit>().init();
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  Widget _buildItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.neutral50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.neutral700, size: 20),
        ),
        title: Text(title, style: AppTextStyles.labelMedium.copyWith(color: AppColors.neutral900)),
        subtitle: subtitle != null ? Text(subtitle, style: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral400)) : null,
        trailing: const Icon(AppIcons.arrowRight, color: AppColors.neutral400, size: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
