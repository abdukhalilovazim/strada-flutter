import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pizza_strada/core/storage/secure_storage.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/core/theme/app_icons.dart';
import 'package:pizza_strada/features/home/presentation/bloc/home_cubit.dart';
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
        title: Text("Profil", style: AppTextStyles.h2.copyWith(color: AppColors.neutral900)),
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
              title: "Bildirishnomalar",
              onTap: () {},
            ),
            _buildItem(
              icon: Icons.language_rounded,
              title: "Tilni o'zgartirish",
              onTap: () {},
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
                  title: "Telefon qilish",
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
                title: Text("Chiqish", style: AppTextStyles.labelLarge.copyWith(color: AppColors.error)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
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
        border: Border.all(color: AppColors.neutral200),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: AppColors.neutral700, size: 22),
        title: Text(title, style: AppTextStyles.labelMedium.copyWith(color: AppColors.neutral900)),
        subtitle: subtitle != null ? Text(subtitle, style: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral400)) : null,
        trailing: const Icon(AppIcons.arrowRight, color: AppColors.neutral200, size: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
