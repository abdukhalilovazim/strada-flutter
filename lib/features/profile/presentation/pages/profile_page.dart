import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pizza_strada/core/sdui/models/sdui_section_model.dart';
import 'package:pizza_strada/core/sdui/widgets/components/sdui_profile_components.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';

/// 👤 ProfilePage powered 100% by Native Flutter UI
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

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
          SDUIProfileHeaderComponent(section: dummySection, onAction: (_) {}),
          SDUILoyaltyComponent(section: dummySection, onAction: (_) {}),
          SDUIProfileMenuGroupComponent(section: dummySection, onAction: (_) {}),
          SDUIAppSettingsComponent(section: dummySection, onAction: (_) {}),
          SDUISupportContactsComponent(section: dummySection, onAction: (_) {}),
          SDUILogoutDeleteComponent(section: dummySection, onAction: (_) {}),
          SDUIAppVersionComponent(section: dummySection, onAction: (_) {}),
        ],
      ),
    );
  }
}
