import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pizza_strada/core/sdui/models/section_model.dart';
import 'package:pizza_strada/core/sdui/widgets/components/profile_components.dart';
import 'package:pizza_strada/core/storage/secure_storage.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';

/// 👤 ProfilePage powered 100% by Native Flutter UI
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final token = await SecureStorage.getToken();
    final hasAuth = token != null && token.isNotEmpty;
    if (mounted && _isLoggedIn != hasAuth) {
      setState(() {
        _isLoggedIn = hasAuth;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const dummySection = SDUISectionModel(id: 'profile', type: 'profile');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'nav.profile'.tr(),
          style: AppTextStyles.h2.copyWith(
            color: Theme.of(context).textTheme.headlineMedium?.color,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: isDark ? AppColors.neutral800 : AppColors.neutral200,
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 60),
        children: [
          SDUIProfileHeaderComponent(
            section: dummySection,
            onAction: (_) => _checkAuth(),
          ),
          SDUILoyaltyComponent(section: dummySection, onAction: (_) {}),
          SDUIProfileMenuGroupComponent(section: dummySection, onAction: (_) {}),
          SDUIAppSettingsComponent(section: dummySection, onAction: (_) {}),
          SDUIAppVersionComponent(section: dummySection, onAction: (_) {}),
        ],
      ),
    );
  }
}
