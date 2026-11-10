import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../features/home/presentation/bloc/home_cubit.dart';
import '../../../storage/secure_storage.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../theme/theme_cubit.dart';
import '../../../utils/device_info_helper.dart';
import '../../../utils/number_formatter.dart';
import '../../models/section_model.dart';
import '../../registry/action_dispatcher.dart';

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
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final token = await SecureStorage.getToken();
    final name = await SecureStorage.getUserName();
    final phone = await SecureStorage.getUserPhone();
    final hasAuth = token != null && token.isNotEmpty;
    if (mounted) {
      setState(() {
        _isLoggedIn = hasAuth;
        if (hasAuth) {
          _userName = (name != null && name.trim().isNotEmpty) ? name.trim() : 'Mijoz';
          _userPhone = (phone != null && phone.trim().isNotEmpty) ? NumberFormatter.formatPhone(phone.trim()) : '';
        } else {
          _userName = 'Kirish';
          _userPhone = 'Profilga kirish uchun bosing';
        }
      });
    }
  }

  String get _initials {
    final trimmed = _userName.trim();
    if (trimmed.isEmpty || trimmed == 'Mijoz' || trimmed == 'checkout.guest_customer'.tr()) {
      return 'S';
    }
    final parts = trimmed.split(RegExp(r'\s+'));
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return trimmed.isNotEmpty ? trimmed[0].toUpperCase() : 'S';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () async {
        HapticFeedback.lightImpact();
        if (_isLoggedIn) {
          await context.push('/profile/edit');
        } else {
          await context.push('/auth/login');
        }
        _loadUser();
      },
      borderRadius: BorderRadius.circular(22),
      child: Container(
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
            // User Avatar (Initials for logged in, Person icon for guest)
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isLoggedIn
                    ? (isDark ? AppColors.neutral800 : const Color(0xFFF1F3F5))
                    : AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
                border: Border.all(
                  color: _isLoggedIn
                      ? (isDark ? AppColors.darkBorder : AppColors.neutral200)
                      : AppColors.primary.withValues(alpha: 0.3),
                  width: 1.2,
                ),
              ),
              child: Center(
                child: _isLoggedIn
                    ? Text(
                        _initials,
                        style: AppTextStyles.h3.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 19,
                        ),
                      )
                    : const Icon(
                        Icons.person_outline_rounded,
                        color: AppColors.primary,
                        size: 26,
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
                  const SizedBox(height: 3),
                  Text(
                    _userPhone,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: _isLoggedIn ? AppColors.neutral500 : AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            if (_isLoggedIn)
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: AppColors.primary, size: 20),
                onPressed: () async {
                  HapticFeedback.lightImpact();
                  await context.push('/profile/edit');
                  _loadUser();
                },
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Kirish',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 11),
                  ],
                ),
              ),
          ],
        ),
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

  String _getLanguageLabel(String code) {
    switch (code) {
      case 'ru':
        return 'Русский';
      case 'en':
        return 'English';
      case 'uz':
      default:
        return "O'zbekcha";
    }
  }

  void _showLanguageBottomSheet(BuildContext context) {
    HapticFeedback.lightImpact();
    final currentCode = context.locale.languageCode;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final languages = [
      {
        'code': 'uz',
        'title': "O'zbekcha",
        'subtitle': "O'zbek tili",
        'flag': '🇺🇿',
      },
      {
        'code': 'ru',
        'title': 'Русский',
        'subtitle': 'Русский язык',
        'flag': '🇷🇺',
      },
      {
        'code': 'en',
        'title': 'English',
        'subtitle': 'English language',
        'flag': '🇬🇧',
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.neutral700 : AppColors.neutral300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.language_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'profile.select_lang_title'.tr(),
                      style: AppTextStyles.h4.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.neutral900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...languages.map((lang) {
                final code = lang['code'] as String;
                final isSelected = currentCode == code;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      await context.setLocale(Locale(code));
                      if (ctx.mounted) {
                        Navigator.of(ctx).pop();
                      }
                      if (context.mounted) {
                        context.read<HomeCubit>().init(forceRefresh: true);
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: isDark ? 0.15 : 0.08)
                            : (isDark ? AppColors.darkSurface : const Color(0xFFF8F9FA)),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? AppColors.darkBorder : AppColors.neutral200),
                          width: isSelected ? 1.5 : 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            lang['flag'] as String,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lang['title'] as String,
                                  style: AppTextStyles.labelMedium.copyWith(
                                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                    color: isSelected
                                        ? AppColors.primary
                                        : (isDark ? Colors.white : AppColors.neutral900),
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  lang['subtitle'] as String,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: isDark ? AppColors.neutral400 : AppColors.neutral500,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            )
                          else
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark ? AppColors.neutral600 : AppColors.neutral300,
                                  width: 1.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

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
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getLanguageLabel(context.locale.languageCode),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary, size: 16),
                ],
              ),
            ),
            onTap: () => _showLanguageBottomSheet(context),
          ),
          Divider(height: 1, indent: 56, color: isDark ? AppColors.darkBorder : AppColors.neutral200),
          // Theme switch
          BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, mode) {
              final isDarkMode = mode == ThemeMode.dark;
              final lang = context.locale.languageCode;
              final titleText = lang == 'ru'
                  ? 'Тема оформления'
                  : (lang == 'en' ? 'App Theme' : 'Ilova mavzusi');
              final statusText = isDarkMode
                  ? (lang == 'ru' ? 'Темная тема' : (lang == 'en' ? 'Dark mode' : 'Tungi mavzu'))
                  : (lang == 'ru' ? 'Светлая тема' : (lang == 'en' ? 'Light mode' : 'Yorug\' mavzu'));

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? const Color(0xFF1E1B4B)
                        : const Color(0xFFFEF3C7),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDarkMode
                          ? const Color(0xFF312E81)
                          : const Color(0xFFFDE68A),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      isDarkMode ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                      color: isDarkMode ? const Color(0xFFA5B4FC) : const Color(0xFFD97706),
                      size: 19,
                    ),
                  ),
                ),
                title: Text(
                  titleText,
                  style: AppTextStyles.labelMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.neutral900,
                  ),
                ),
                subtitle: Text(
                  statusText,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.neutral500,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: _ThemeSwitchWidget(
                  isDark: isDarkMode,
                  onToggle: () {
                    HapticFeedback.lightImpact();
                    context.read<ThemeCubit>().toggleTheme();
                  },
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

/// 🌓 Zamonaviy va nafis Dark/Light Mode switcheri
class _ThemeSwitchWidget extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggle;

  const _ThemeSwitchWidget({required this.isDark, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOutCubic,
        width: 68,
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F3F5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1.5),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Orqa tarafdagi quyosh va oy piktogrammalari
            Positioned.fill(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Icon(
                      Icons.wb_sunny_rounded,
                      size: 13,
                      color: isDark ? AppColors.neutral500 : const Color(0xFFF59E0B),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Icon(
                      Icons.nightlight_round,
                      size: 13,
                      color: isDark ? const Color(0xFFA5B4FC) : AppColors.neutral400,
                    ),
                  ),
                ],
              ),
            ),
            // Harakatlanuvchi dumaloq indikator (thumb)
            AnimatedAlign(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOutCubic,
              alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF312E81) : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                      blurRadius: 5,
                      offset: const Offset(0, 1.5),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    isDark ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                    size: 14,
                    color: isDark ? const Color(0xFFFDE68A) : const Color(0xFFF59E0B),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
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
    final title = props['title']?.toString() ?? 'Qo\'llab-quvvatlash';
    final phoneLabel = props['phone_label']?.toString() ?? 'Call-markaz';

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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: isDark ? 0.2 : 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.phone_in_talk_rounded,
                      color: AppColors.success,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.neutral500,
                          fontWeight: FontWeight.w600,
                          fontSize: 11.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formattedPhone,
                        style: AppTextStyles.h4.copyWith(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.neutral900,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        phoneLabel,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.neutral400,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.call_rounded, size: 13, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Qo\'ng\'iroq',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
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

/// ℹ️ Profil: Ilova versiyasi (pubspec.yaml dan real versiya)
class SDUIAppVersionComponent extends StatefulWidget {
  final SDUISectionModel section;
  final SDUIActionHandler onAction;

  const SDUIAppVersionComponent({
    super.key,
    required this.section,
    required this.onAction,
  });

  @override
  State<SDUIAppVersionComponent> createState() => _SDUIAppVersionComponentState();
}

class _SDUIAppVersionComponentState extends State<SDUIAppVersionComponent> {
  late String _versionText;

  @override
  void initState() {
    super.initState();
    _versionText = _formatVersion(
      DeviceInfoHelper.appVersion,
      DeviceInfoHelper.appVersionCode,
    );
    _loadRealVersion();
  }

  String _formatVersion(String version, String buildNumber) {
    if (version.isEmpty) return '';
    if (buildNumber.isNotEmpty && buildNumber != '0') {
      return 'v$version ($buildNumber)';
    }
    return 'v$version';
  }

  Future<void> _loadRealVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final formatted = _formatVersion(info.version, info.buildNumber);
      if (mounted && formatted != _versionText && formatted.isNotEmpty) {
        setState(() {
          _versionText = formatted;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final display = _versionText.isNotEmpty
        ? 'Pizza Strada Uzbekistan • $_versionText'
        : 'Pizza Strada Uzbekistan';

    return Container(
      padding: const EdgeInsets.only(bottom: 30, top: 8),
      alignment: Alignment.center,
      child: Text(
        display,
        style: const TextStyle(
          color: AppColors.neutral400,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

