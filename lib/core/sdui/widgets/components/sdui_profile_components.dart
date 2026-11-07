import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../storage/secure_storage.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/theme_cubit.dart';
import '../../../utils/number_formatter.dart';
import '../../models/sdui_section_model.dart';
import '../../registry/sdui_action_dispatcher.dart';

/// 👤 Profil: Foydalanuvchi ma'lumotlari kartasi (Profile Header Card)
class SDUIProfileHeaderComponent extends StatefulWidget {
  final SDUISectionModel section;
  final SDUIActionHandler onAction;

  const SDUIProfileHeaderComponent({
    super.key,
    required this.section,
    required this.onAction,
  });

  @override
  State<SDUIProfileHeaderComponent> createState() => _SDUIProfileHeaderComponentState();
}

class _SDUIProfileHeaderComponentState extends State<SDUIProfileHeaderComponent> {
  String _userName = 'Mijoz';
  String _userPhone = '+998 -- --- -- --';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final name = await SecureStorage.getUserName();
    final phone = await SecureStorage.getUserPhone();
    if (mounted) {
      setState(() {
        if (name != null && name.isNotEmpty) _userName = name;
        if (phone != null && phone.isNotEmpty) _userPhone = phone;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.neutral200.withValues(alpha: 0.7),
        ),
        boxShadow: AppColors.softShadow(isDark),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFFFF6B6B), AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(2.5),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? AppColors.darkCard : Colors.white,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: ClipOval(
                    child: Container(
                      color: isDark ? AppColors.neutral800 : const Color(0xFFFFF0F2),
                      child: Center(
                        child: Icon(
                          Icons.person_rounded,
                          size: 32,
                          color: isDark ? Colors.white : AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? AppColors.darkCard : Colors.white,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.camera_alt_rounded,
                      size: 11,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName,
                  style: AppTextStyles.h4.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.neutral900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _userPhone,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.neutral500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('profile.edit_profile_dialog'.tr())),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// ⭐ Profil: Keshbek & Bonuslar (Loyalty Card) - Keshbek tizimi mavjud emas
class SDUILoyaltyComponent extends StatelessWidget {
  final SDUISectionModel section;
  final SDUIActionHandler onAction;

  const SDUILoyaltyComponent({
    super.key,
    required this.section,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

/// 📋 Profil: Menyu punktlari (Orders / Addresses / Branches)
class SDUIProfileMenuGroupComponent extends StatelessWidget {
  final SDUISectionModel section;
  final SDUIActionHandler onAction;

  const SDUIProfileMenuGroupComponent({
    super.key,
    required this.section,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final menuItems = [
      {'title': 'profile.my_orders'.tr(), 'icon': Icons.receipt_long_outlined, 'route': '/orders'},
      {'title': 'profile.saved_addresses'.tr(), 'icon': Icons.location_on_outlined, 'route': '/saved-addresses'},
      {'title': 'profile.branches'.tr(), 'icon': Icons.storefront_outlined, 'route': '/branches'},
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.neutral200.withValues(alpha: 0.7),
        ),
        boxShadow: AppColors.softShadow(isDark),
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: menuItems.map((item) {
            final isLast = item == menuItems.last;
            return Column(
              children: [
                ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item['icon'] as IconData, color: AppColors.primary, size: 20),
                ),
                title: Text(
                  item['title'] as String,
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.neutral900,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.neutral400),
                onTap: () {
                  final route = item['route'] as String;
                  if (route == '/orders') {
                    context.go('/orders');
                  } else {
                    context.push(route);
                  }
                },
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 60,
                  color: isDark ? AppColors.darkBorder : AppColors.neutral200,
                ),
            ],
          );
        }).toList(),
      ),
    ),
    );
  }
}

/// ⚙️ Profil: Ilova sozlamalari (Til & Tungi rejim)
class SDUIAppSettingsComponent extends StatelessWidget {
  final SDUISectionModel section;
  final SDUIActionHandler onAction;

  const SDUIAppSettingsComponent({
    super.key,
    required this.section,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final props = section.properties;
    final title = props['title']?.toString() ?? 'Ilova sozlamalari';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.neutral200.withValues(alpha: 0.7),
        ),
        boxShadow: AppColors.softShadow(isDark),
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            child: Text(
              title,
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.neutral500, fontWeight: FontWeight.w700),
            ),
          ),
          // Language
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.language_rounded, color: AppColors.primary, size: 20),
            ),
            title: Text(
              'profile.select_lang_title'.tr(),
              style: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.neutral900,
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                context.locale.languageCode == 'ru' ? 'Русский' : "O'zbekcha",
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
            ),
            onTap: () {
              HapticFeedback.lightImpact();
              final newLocale = context.locale.languageCode == 'uz'
                  ? const Locale('ru')
                  : const Locale('uz');
              context.setLocale(newLocale);
            },
          ),
          Divider(height: 1, indent: 56, color: isDark ? AppColors.darkBorder : AppColors.neutral200),
          // Theme switch
          BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, mode) {
              final isDarkMode = mode == ThemeMode.dark;
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isDarkMode ? Colors.amber : AppColors.primary).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: isDarkMode ? Colors.amber : AppColors.primary,
                    size: 20,
                  ),
                ),
                title: Text(
                  'profile.dark_mode_title'.tr(),
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.neutral900,
                  ),
                ),
                subtitle: Text(
                  isDarkMode
                      ? (context.locale.languageCode == 'ru' ? 'Темная тема включена' : 'Qorong\'i mavzu yoqilgan')
                      : (context.locale.languageCode == 'ru' ? 'Светлая тема включена' : 'Yorug\' mavzu yoqilgan'),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.neutral400,
                    fontSize: 12,
                  ),
                ),
                trailing: Transform.scale(
                  scale: 0.85,
                  child: Switch.adaptive(
                    value: isDarkMode,
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppColors.primary,
                    onChanged: (_) {
                      HapticFeedback.lightImpact();
                      context.read<ThemeCubit>().toggleTheme();
                    },
                  ),
                ),
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.read<ThemeCubit>().toggleTheme();
                },
              );
            },
          ),
        ],
      ),
    ),
    );
  }
}

/// 📞 Profil: Qo'llab-quvvatlash telefon raqami (Faqat raqam, Telegram emas)
class SDUISupportContactsComponent extends StatelessWidget {
  final SDUISectionModel section;
  final SDUIActionHandler onAction;

  const SDUISupportContactsComponent({
    super.key,
    required this.section,
    required this.onAction,
  });

  Future<void> _callPhone(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'[\s\(\)\-]'), '');
    final uri = Uri.parse('tel:$cleaned');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final props = section.properties;
    final rawPhone = props['phone']?.toString() ?? '+998662211177';
    final formattedPhone = NumberFormatter.formatPhone(rawPhone);
    final title = props['title']?.toString() ?? 'Qo\'llab-quvvatlash va aloqa';
    final phoneLabel = props['phone_label']?.toString() ?? 'Call-markazga qo\'ng\'iroq qilish';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.neutral200.withValues(alpha: 0.7),
        ),
        boxShadow: AppColors.softShadow(isDark),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            _callPhone(rawPhone);
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: isDark ? 0.2 : 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.phone_in_talk_rounded,
                      color: AppColors.success,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.neutral500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        formattedPhone,
                        style: AppTextStyles.h4.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.neutral900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        phoneLabel,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.neutral400,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.call_rounded, size: 14, color: Colors.white),
                      SizedBox(width: 5),
                      Text(
                        'Qo\'ng\'iroq',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 🚪 Profil: Hisobdan chiqish
class SDUILogoutDeleteComponent extends StatelessWidget {
  final SDUISectionModel section;
  final SDUIActionHandler onAction;

  const SDUILogoutDeleteComponent({
    super.key,
    required this.section,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final props = section.properties;
    final logoutText = props['logout_text']?.toString() ?? 'Hisobdan chiqish';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Center(
        child: TextButton.icon(
          onPressed: () async {
            await SecureStorage.deleteToken();
            await SecureStorage.deleteUserInfo();
            if (context.mounted) {
              context.go('/auth/login');
            }
          },
          icon: const Icon(Icons.logout_rounded, color: AppColors.error, size: 18),
          label: Text(
            logoutText,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

/// ℹ️ Profil: Ilova versiyasi
class SDUIAppVersionComponent extends StatelessWidget {
  final SDUISectionModel section;
  final SDUIActionHandler onAction;

  const SDUIAppVersionComponent({
    super.key,
    required this.section,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 30, top: 8),
      alignment: Alignment.center,
      child: const Text(
        'Pizza Strada Uzbekistan • v1.2.0',
        style: TextStyle(color: AppColors.neutral400, fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }
}

