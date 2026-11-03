import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../storage/secure_storage.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/theme_cubit.dart';
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
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _userName.isNotEmpty ? _userName[0].toUpperCase() : 'S',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
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
                const SnackBar(content: Text('Profilni tahrirlash oynasi')),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// ⭐ Profil: Keshbek & Bonuslar (Loyalty Card)
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
    final props = section.properties;
    final title = props['title']?.toString() ?? 'Strada Keshbek';
    final subtitle = props['subtitle']?.toString() ?? 'Ballar to\'plang va buyurtmaning 100% gacha to\'lang';
    final badge = props['badge']?.toString() ?? '5%';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE53935), Color(0xFFFF5722), Color(0xFFFF9800)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '25 000 ball',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
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
      {'title': 'Mening buyurtmalarim', 'icon': Icons.receipt_long_outlined, 'route': '/orders'},
      {'title': 'Mening manzillarim', 'icon': Icons.location_on_outlined, 'route': '/map-picker'},
      {'title': 'Filiallar va restoranlar', 'icon': Icons.storefront_outlined, 'route': '/branches'},
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
            leading: const Icon(Icons.language_rounded, color: AppColors.primary),
            title: const Text('Til / Язык', style: TextStyle(fontWeight: FontWeight.w700)),
            trailing: Text(
              context.locale.languageCode == 'ru' ? 'Русский' : "O'zbekcha",
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800),
            ),
            onTap: () {
              final newLocale = context.locale.languageCode == 'uz'
                  ? const Locale('ru')
                  : const Locale('uz');
              context.setLocale(newLocale);
            },
          ),
          Divider(height: 1, indent: 56, color: isDark ? AppColors.darkBorder : AppColors.neutral200),
          // Theme switch
          ListTile(
            leading: Icon(
              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: AppColors.primary,
            ),
            title: const Text('Tungi rejim', style: TextStyle(fontWeight: FontWeight.w700)),
            trailing: Switch(
              value: isDark,
              activeColor: AppColors.primary,
              onChanged: (_) {
                context.read<ThemeCubit>().toggleTheme();
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// 📞 Profil: Call-center va Telegram yordam
class SDUISupportContactsComponent extends StatelessWidget {
  final SDUISectionModel section;
  final SDUIActionHandler onAction;

  const SDUISupportContactsComponent({
    super.key,
    required this.section,
    required this.onAction,
  });

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final props = section.properties;
    final phone = props['phone']?.toString() ?? '+998662211177';
    final tgBot = props['telegram_bot']?.toString() ?? 'https://t.me/stradapizzabot';

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.neutral200.withValues(alpha: 0.7),
        ),
        boxShadow: AppColors.softShadow(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Qo\'llab-quvvatlash va aloqa',
            style: AppTextStyles.labelSmall.copyWith(color: AppColors.neutral500, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _launchUrl('tel:$phone'),
                  icon: const Icon(Icons.phone_in_talk_rounded, size: 16),
                  label: const Text('Call-markaz', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _launchUrl(tgBot),
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: const Text('Telegram bot', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0088CC),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
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

