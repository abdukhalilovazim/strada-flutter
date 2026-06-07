import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pizza_strada/core/storage/secure_storage.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/core/theme/app_icons.dart';
import 'package:pizza_strada/features/home/presentation/bloc/home_cubit.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pizza_strada/core/network/graphql_client.dart';
import 'package:graphql_flutter/graphql_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _name = 'Mijoz';
  String _phone = '';
  String? _selectedPurpose;
  bool _showInquiryForm = false;
  final _messageController = TextEditingController();
  bool _isSubmitting = false;
  int _charCount = 0;

  final List<Map<String, String>> _purposes = [
    {'key': 'food', 'translation': 'profile.inquiry_purpose_food'},
    {'key': 'delivery', 'translation': 'profile.inquiry_purpose_delivery'},
    {'key': 'service', 'translation': 'profile.inquiry_purpose_service'},
    {'key': 'suggestion', 'translation': 'profile.inquiry_purpose_suggestion'},
    {'key': 'complaint', 'translation': 'profile.inquiry_purpose_complaint'},
    {'key': 'other', 'translation': 'profile.inquiry_purpose_other'},
  ];

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
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
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text('profile.title'.tr(), style: AppTextStyles.h2.copyWith(color: Theme.of(context).textTheme.headlineMedium?.color)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
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
                color: Theme.of(context).cardColor,
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
                        Text(_name, style: AppTextStyles.labelLarge.copyWith(color: Theme.of(context).textTheme.bodyLarge?.color)),
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
            const SizedBox(height: 12),
            _buildItem(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'profile.support_inquiry'.tr(),
              onTap: () {
                setState(() {
                  _showInquiryForm = !_showInquiryForm;
                });
              },
            ),

            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _showInquiryForm
                  ? Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: _buildInquiryForm(),
                    )
                  : const SizedBox.shrink(),
            ),

            const SizedBox(height: 32),

            // Logout
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.neutral200),
              ),
              child: ListTile(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (dialogContext) {
                      return AlertDialog(
                        backgroundColor: Theme.of(dialogContext).cardColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: Text(
                          'profile.logout'.tr(),
                          style: AppTextStyles.h3.copyWith(
                            color: Theme.of(dialogContext).textTheme.headlineMedium?.color,
                          ),
                        ),
                        content: Text(
                          'profile.logout_confirm'.tr(),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Theme.of(dialogContext).textTheme.bodyMedium?.color,
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: Text(
                              'common.no'.tr(),
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.neutral600,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              Navigator.pop(dialogContext);
                              await SecureStorage.clearAll();
                              if (mounted) {
                                context.go('/auth/login');
                              }
                            },
                            child: Text(
                              'common.yes'.tr(),
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
                leading: const Icon(Icons.logout_rounded, color: AppColors.error, size: 22),
                title: Text('profile.logout'.tr(), style: AppTextStyles.labelLarge.copyWith(color: AppColors.error)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  void _showLanguagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
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
        title: Text(title, style: AppTextStyles.labelMedium.copyWith(color: isSelected ? AppColors.primary : Theme.of(context).textTheme.bodyMedium?.color)),
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
        color: Theme.of(context).cardColor,
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
        title: Text(title, style: AppTextStyles.labelMedium.copyWith(color: Theme.of(context).textTheme.bodyMedium?.color)),
        subtitle: subtitle != null ? Text(subtitle, style: AppTextStyles.bodySmall.copyWith(color: AppColors.neutral400)) : null,
        trailing: const Icon(AppIcons.arrowRight, color: AppColors.neutral400, size: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  Widget _buildInquiryForm() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.neutral800 : AppColors.neutral200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'profile.inquiry_purpose'.tr(),
                style: AppTextStyles.h4.copyWith(
                  color: Theme.of(context).textTheme.headlineMedium?.color,
                ),
              ),
              const Text(
                ' *',
                style: TextStyle(color: AppColors.error),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _purposes.map((purpose) {
              final isSelected = _selectedPurpose == purpose['key'];
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPurpose = isSelected ? null : purpose['key'];
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryLight
                        : (isDark ? AppColors.neutral800 : AppColors.neutral50),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? AppColors.neutral700 : AppColors.neutral200),
                      width: 1.2,
                    ),
                  ),
                  child: Text(
                    purpose['translation']!.tr(),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? Colors.white : AppColors.neutral900),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text(
                'profile.message'.tr(),
                style: AppTextStyles.h4.copyWith(
                  color: Theme.of(context).textTheme.headlineMedium?.color,
                ),
              ),
              const Text(
                ' *',
                style: TextStyle(color: AppColors.error),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _messageController,
            maxLines: 4,
            maxLength: 500,
            style: AppTextStyles.bodyMedium.copyWith(
              color: isDark ? Colors.white : AppColors.neutral900,
            ),
            onChanged: (text) {
              setState(() {
                _charCount = text.length;
              });
            },
            decoration: InputDecoration(
              counterText: "",
              hintText: 'profile.message_hint'.tr(),
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.neutral400,
              ),
              filled: true,
              fillColor: isDark ? AppColors.neutral800.withOpacity(0.5) : AppColors.neutral50,
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? AppColors.neutral700 : AppColors.neutral200,
                  width: 1.0,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isDark ? AppColors.neutral700 : AppColors.neutral200,
                  width: 1.0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$_charCount/500',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.neutral500,
            ),
          ),
          const SizedBox(height: 24),
          _isSubmitting
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                  ),
                )
              : _buildSendButton(),
        ],
      ),
    );
  }

  Widget _buildSendButton() {
    final isEnabled = _selectedPurpose != null && _messageController.text.trim().length >= 5;
    return _AnimatedScaleButton(
      onTap: isEnabled ? _submitInquiry : null,
      child: Container(
        width: double.infinity,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isEnabled ? AppColors.primary : AppColors.neutral200,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.send_rounded,
              color: isEnabled ? Colors.white : AppColors.neutral400,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              'profile.send'.tr(),
              style: AppTextStyles.labelLarge.copyWith(
                color: isEnabled ? Colors.white : AppColors.neutral400,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitInquiry() async {
    FocusScope.of(context).unfocus();
    final purpose = _selectedPurpose;
    final message = _messageController.text.trim();

    if (purpose == null || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('profile.inquiry_validation_error'.tr()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      const String mutation = r'''
        mutation createInquiry($type: String!, $message: String!) {
          createInquiry(type: $type, message: $message)
        }
      ''';

      final client = buildGraphQLClient();
      final result = await client.mutate(MutationOptions(
        document: gql(mutation),
        variables: {
          'type': purpose,
          'message': message,
        },
        operationName: 'createInquiry',
      ));

      if (result.hasException) {
        throw result.exception!;
      }

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
        _selectedPurpose = null;
        _messageController.clear();
        _charCount = 0;
      });

      showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            backgroundColor: Theme.of(dialogContext).cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'profile.support'.tr(),
                    style: AppTextStyles.h3.copyWith(
                      color: Theme.of(dialogContext).textTheme.headlineMedium?.color,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              'profile.inquiry_success'.tr(),
              style: AppTextStyles.bodyMedium.copyWith(
                color: Theme.of(dialogContext).textTheme.bodyMedium?.color,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(
                  'common.yes'.tr(),
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().contains('Unauthenticated')
              ? 'error.unauthorized'.tr()
              : 'error.server'.tr()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _AnimatedScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _AnimatedScaleButton({
    required this.child,
    required this.onTap,
  });

  @override
  State<_AnimatedScaleButton> createState() => _AnimatedScaleButtonState();
}

class _AnimatedScaleButtonState extends State<_AnimatedScaleButton> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.onTap != null;
    return GestureDetector(
      onTapDown: !isEnabled ? null : (_) => setState(() => _scale = 0.96),
      onTapUp: !isEnabled ? null : (_) => setState(() => _scale = 1.0),
      onTapCancel: !isEnabled ? null : () => setState(() => _scale = 1.0),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        child: widget.child,
      ),
    );
  }
}
