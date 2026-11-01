import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:pizza_strada/core/di/injection.dart';
import 'package:pizza_strada/core/models/saved_address_model.dart';
import 'package:pizza_strada/core/storage/secure_storage.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/core/theme/theme_cubit.dart';
import 'package:pizza_strada/core/utils/phone_number_formatter.dart';
import 'package:pizza_strada/core/widgets/app_button.dart';
import 'package:pizza_strada/features/auth/domain/entities/user_entity.dart';
import 'package:pizza_strada/features/auth/domain/usecases/get_me_usecase.dart';
import 'package:pizza_strada/features/home/presentation/bloc/home_cubit.dart';
import 'package:pizza_strada/features/profile/presentation/pages/branches_web_view_page.dart';
import 'package:pizza_strada/features/profile/presentation/pages/edit_profile_page.dart';

extension _SafeTranslateX on String {
  String trWith(String fallback) {
    try {
      final res = tr(this);
      return (res == this || res.isEmpty) ? fallback : res;
    } catch (_) {
      return fallback;
    }
  }
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserEntity? _user;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final name = await SecureStorage.getUserName();
    final phone = await SecureStorage.getUserPhone();
    if (mounted && name != null && phone != null) {
      setState(() {
        _user = UserEntity(id: 0, fullName: name, phone: phone, token: '');
      });
    }

    final token = await SecureStorage.getToken();
    if (token != null) {
      final getMe = getIt<GetMeUseCase>();
      final result = await getMe();
      result.fold(
        (failure) => null,
        (user) async {
          await SecureStorage.saveUserInfo(name: user.fullName, phone: user.phone);
          if (mounted) {
            setState(() {
              _user = user;
            });
          }
        },
      );
    }
  }

  String _getInitials(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  String _getCurrentLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'uz':
        return "🇺🇿 O'zbekcha";
      case 'ru':
        return "🇷🇺 Русский";
      case 'en':
        return "🇬🇧 English";
      default:
        return locale.languageCode.toUpperCase();
    }
  }

  Future<void> _makeCall(String phone) async {
    final clean = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final homeState = context.watch<HomeCubit>().state;
    final supportPhone = (homeState is HomeLoaded &&
            homeState.settings?.supportPhone != null &&
            homeState.settings!.supportPhone.isNotEmpty)
        ? homeState.settings!.supportPhone
        : '+998 71 200 00 00';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'profile.title'.tr(),
          style: AppTextStyles.h3.copyWith(
            fontWeight: FontWeight.w800,
            color: Theme.of(context).textTheme.headlineMedium?.color,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── 1. User Header or Guest Banner ──
            if (_user != null)
              _buildUserCard(isDark)
            else
              _buildGuestCard(isDark),

            const SizedBox(height: 14),

            // ── 2. Bento Shortcuts Row (if user logged in) ──
            if (_user != null) ...[
              _buildBentoShortcuts(isDark),
              const SizedBox(height: 10),
            ],

            // ── 3. Section: App Settings ──
            _buildSectionHeader('profile.section_app'.trWith('Ilova sozlamalari')),
            _buildGroupCard(
              context: context,
              children: [
                _buildGroupRow(
                  icon: Icons.language_rounded,
                  iconColor: const Color(0xFF0284C7),
                  iconBgColor: const Color(0xFFE0F2FE),
                  title: 'profile.change_language'.tr(),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors.neutral100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _getCurrentLanguageName(context.locale),
                          style: AppTextStyles.labelSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : AppColors.neutral800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: isDark ? AppColors.neutral500 : AppColors.neutral400,
                      ),
                    ],
                  ),
                  onTap: () => _showLanguagePicker(),
                ),
                _buildDivider(isDark),
                BlocBuilder<ThemeCubit, ThemeMode>(
                  builder: (context, themeMode) {
                    final isDarkMode = themeMode == ThemeMode.dark;
                    return _buildGroupRow(
                      icon: isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                      iconColor: const Color(0xFF8B5CF6),
                      iconBgColor: const Color(0xFFEDE9FE),
                      title: 'profile.dark_mode'.tr(),
                      trailing: Switch.adaptive(
                        value: isDarkMode,
                        activeTrackColor: AppColors.primary,
                        onChanged: (val) {
                          HapticFeedback.lightImpact();
                          context.read<ThemeCubit>().toggle();
                        },
                      ),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.read<ThemeCubit>().toggle();
                      },
                      isLast: true,
                    );
                  },
                ),
              ],
            ),

            // ── 4. Section: Strada Pizza ──
            _buildSectionHeader('profile.section_strada'.trWith('Strada Pizza')),
            _buildGroupCard(
              context: context,
              children: [
                _buildGroupRow(
                  icon: Icons.storefront_rounded,
                  iconColor: const Color(0xFFEA580C),
                  iconBgColor: const Color(0xFFFFEDD5),
                  title: 'profile.branches'.tr(),
                  subtitle: 'profile.branches_desc'.trWith('Ish vaqti, manzillar va lokatsiya'),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BranchesWebViewPage()),
                    );
                  },
                ),
                _buildDivider(isDark),
                _buildGroupRow(
                  icon: Icons.phone_in_talk_rounded,
                  iconColor: AppColors.primary,
                  iconBgColor: AppColors.primaryLight,
                  title: 'profile.call_center'.trWith('Aloqa markazi'),
                  subtitle: supportPhone,
                  trailing: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.call_rounded,
                      color: AppColors.primary,
                      size: 16,
                    ),
                  ),
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    _makeCall(supportPhone);
                  },
                  isLast: true,
                ),
              ],
            ),

            // ── 5. Section: Account (if logged in) ──
            if (_user != null) ...[
              _buildSectionHeader('profile.section_account'.trWith('Hisob')),
              _buildGroupCard(
                context: context,
                children: [
                  _buildGroupRow(
                    icon: Icons.badge_outlined,
                    iconColor: const Color(0xFF6366F1),
                    iconBgColor: const Color(0xFFEEF2FF),
                    title: 'profile.edit'.tr(),
                    subtitle: 'profile.birthdate'.tr(),
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      final updated = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => EditProfilePage(user: _user!),
                        ),
                      );
                      if (updated != null && updated is UserEntity && mounted) {
                        setState(() => _user = updated);
                      }
                    },
                  ),
                  _buildDivider(isDark),
                  _buildGroupRow(
                    icon: Icons.logout_rounded,
                    iconColor: AppColors.error,
                    iconBgColor: const Color(0xFFFFE4E6),
                    title: 'profile.logout'.tr(),
                    isDestructive: true,
                    isLast: true,
                    onTap: () => _confirmLogout(context),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 32),

            // ── 6. App Footer Branding ──
            Center(
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_pizza_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pizza Strada',
                    style: AppTextStyles.labelMedium.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isDark ? AppColors.neutral300 : AppColors.neutral700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${'profile.version'.trWith('Versiya')} 1.0.0 (Build 42)',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.neutral500,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bento User Card ──
  Widget _buildUserCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.neutral200.withValues(alpha: 0.8),
          width: 1,
        ),
        boxShadow: AppColors.softShadow(isDark),
      ),
      child: Row(
        children: [
          // Initials Avatar with Gradient Ring
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              _getInitials(_user!.fullName),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _user!.fullName,
                  style: AppTextStyles.h4.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.neutral900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 14,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      PhoneNumberFormatter.formatFull(_user!.phone),
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.neutral400 : AppColors.neutral600,
                      ),
                    ),
                  ],
                ),
                if (_user?.birthdate != null && _user!.birthdate!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    '🎂 ${_user!.birthdate!}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.neutral500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () async {
              HapticFeedback.lightImpact();
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditProfilePage(user: _user!),
                ),
              );
              if (updated != null && updated is UserEntity && mounted) {
                setState(() => _user = updated);
              }
            },
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.neutral100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.edit_outlined,
                size: 18,
                color: isDark ? Colors.white : AppColors.neutral800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bento Shortcuts Row (Orders, Addresses) ──
  Widget _buildBentoShortcuts(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildBentoShortcutItem(
            isDark: isDark,
            icon: Icons.receipt_long_rounded,
            iconColor: AppColors.primary,
            title: 'profile.my_orders'.trWith('Mening buyurtmalarim'),
            onTap: () {
              HapticFeedback.lightImpact();
              GoRouter.of(context).go('/orders');
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildBentoShortcutItem(
            isDark: isDark,
            icon: Icons.location_on_rounded,
            iconColor: const Color(0xFF10B981),
            title: 'profile.saved_addresses'.trWith('Saqlangan manzillar'),
            onTap: () {
              HapticFeedback.lightImpact();
              _showSavedAddressesSheet(context);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBentoShortcutItem({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.neutral200.withValues(alpha: 0.8),
          width: 1,
        ),
        boxShadow: AppColors.softShadow(isDark),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: isDark ? 0.18 : 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: AppTextStyles.labelSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: isDark ? Colors.white : AppColors.neutral900,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Guest Card ──
  Widget _buildGuestCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.neutral200.withValues(alpha: 0.8),
          width: 1,
        ),
        boxShadow: AppColors.softShadow(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.person_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'profile.guest_greeting'.tr(),
                      style: AppTextStyles.h4.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.neutral900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'profile.guest_login_prompt'.tr(),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: isDark ? AppColors.neutral400 : AppColors.neutral600,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          AppButton(
            text: 'auth.login_button'.tr(),
            onTap: () async {
              HapticFeedback.selectionClick();
              await context.push('/auth/login');
              _loadUserInfo();
            },
          ),
        ],
      ),
    );
  }

  // ── Section Header ──
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 18),
      child: Text(
        title.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: AppColors.neutral500,
          fontSize: 11,
        ),
      ),
    );
  }

  // ── Inset Group Card ──
  Widget _buildGroupCard({
    required BuildContext context,
    required List<Widget> children,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.neutral200.withValues(alpha: 0.8),
          width: 1,
        ),
        boxShadow: AppColors.softShadow(isDark),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 60,
      endIndent: 16,
      color: isDark ? AppColors.darkBorder : const Color(0xFFF1F5F9),
    );
  }

  // ── Group Row Item ──
  Widget _buildGroupRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    String? subtitle,
    Widget? trailing,
    required VoidCallback onTap,
    bool isLast = false,
    bool isDestructive = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isDark ? iconColor.withValues(alpha: 0.18) : iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isDark ? (isDestructive ? AppColors.error : Colors.white) : iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        color: isDestructive
                            ? AppColors.error
                            : (isDark ? Colors.white : AppColors.neutral900),
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: isDark ? AppColors.neutral400 : AppColors.neutral500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                trailing
              else
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: isDark ? AppColors.neutral500 : AppColors.neutral400,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Saved Addresses Bottom Sheet ──
  void _showSavedAddressesSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return FutureBuilder<List<SavedAddressModel>>(
          future: SecureStorage.getSavedAddresses(),
          builder: (context, snapshot) {
            final addresses = snapshot.data ?? [];

            return Container(
              height: MediaQuery.of(context).size.height * 0.65,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  // Drag Handle
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.neutral700 : AppColors.neutral300,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'profile.saved_addresses'.trWith('Saqlangan manzillar'),
                          style: AppTextStyles.h3.copyWith(
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : AppColors.neutral900,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: addresses.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.location_off_outlined,
                                      size: 40,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'profile.no_saved_addresses'.trWith('Saqlangan manzillar mavjud emas'),
                                    style: AppTextStyles.h4.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : AppColors.neutral900,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'profile.no_saved_addresses_desc'.trWith('Buyurtma berganingizda manzillaringiz avtomatik saqlanib boradi'),
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.neutral500,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            itemCount: addresses.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final item = addresses[index];
                              final details = (item.comment != null && item.comment!.isNotEmpty)
                                  ? item.comment!
                                  : [
                                      if (item.apartment != null && item.apartment!.isNotEmpty)
                                        'Kvartira: ${item.apartment}',
                                      if (item.entrance != null && item.entrance!.isNotEmpty)
                                        'Podyezd: ${item.entrance}',
                                      if (item.floor != null && item.floor!.isNotEmpty)
                                        'Qavat: ${item.floor}',
                                    ].join(' • ');

                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkSurface : AppColors.neutral50,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark ? AppColors.darkBorder : AppColors.neutral200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.location_on_rounded,
                                        color: AppColors.primary,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.address,
                                            style: AppTextStyles.labelMedium.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: isDark ? Colors.white : AppColors.neutral900,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (details.isNotEmpty) ...[
                                            const SizedBox(height: 3),
                                            Text(
                                              details,
                                              style: AppTextStyles.bodySmall.copyWith(
                                                color: AppColors.neutral500,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Language Selector Sheet ──
  void _showLanguagePicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.neutral700 : AppColors.neutral300,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'profile.select_language'.tr(),
                    style: AppTextStyles.h3.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : AppColors.neutral900,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildLanguageOption("O'zbekcha 🇺🇿", const Locale('uz')),
                  _buildLanguageOption("Русский 🇷🇺", const Locale('ru')),
                  _buildLanguageOption("English 🇬🇧", const Locale('en')),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageOption(String title, Locale locale) {
    final isSelected = context.locale == locale;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.08)
            : (isDark ? AppColors.darkSurface : AppColors.neutral50),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.neutral200),
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            HapticFeedback.selectionClick();
            await context.setLocale(locale);
            if (!mounted) return;
            context.read<HomeCubit>().init();
            Navigator.pop(context);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.labelMedium.copyWith(
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? Colors.white : AppColors.neutral900),
                    ),
                  ),
                ),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? AppColors.neutral700 : AppColors.neutral300),
                      width: isSelected ? 6.5 : 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Logout Confirmation Dialog ──
  void _confirmLogout(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkCard : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'profile.logout'.tr(),
            style: AppTextStyles.h3.copyWith(
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : AppColors.neutral900,
            ),
          ),
          content: Text(
            'profile.logout_confirm'.tr(),
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark ? AppColors.neutral400 : AppColors.neutral600,
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'common.cancel'.tr(),
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.neutral500,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              onPressed: () async {
                HapticFeedback.mediumImpact();
                Navigator.pop(dialogContext);
                await SecureStorage.clearAll();
                if (!context.mounted) return;
                setState(() => _user = null);
              },
              child: Text(
                'profile.logout'.tr(),
                style: AppTextStyles.labelMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
