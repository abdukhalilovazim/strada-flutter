import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/core/utils/phone_number_formatter.dart';
import 'package:pizza_strada/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:pizza_strada/core/di/injection.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final AuthCubit _authCubit;
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneFocus = FocusNode();
  final _nameFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _authCubit = getIt<AuthCubit>();
    _phoneController.addListener(_onFieldChanged);
    _nameController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _phoneController.removeListener(_onFieldChanged);
    _nameController.removeListener(_onFieldChanged);
    _authCubit.close();
    _phoneController.dispose();
    _nameController.dispose();
    _phoneFocus.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _onContinue(BuildContext ctx) {
    final digits = PhoneNumberFormatter.extractDigits(_phoneController.text);
    if (digits.length < 9) {
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
        content: Text('error.validation'.tr()),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    final phone = '+998$digits';
    _authCubit.login(
      fullName: _nameController.text.trim(),
      phone: phone,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider.value(
      value: _authCubit,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
        body: BlocConsumer<AuthCubit, AuthState>(
          listener: (ctx, state) {
            if (state is AuthOtpSent) {
              ctx.push('/auth/otp', extra: {
                'phone': state.phone,
                'fullName': _nameController.text.trim(),
              });
            } else if (state is AuthFailure) {
              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ));
            }
          },
          builder: (ctx, state) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),

                    // Til tanlash paneli
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _langButton(context, 'UZ',
                            context.locale.languageCode == 'uz', isDark),
                        const SizedBox(width: 8),
                        _langButton(context, 'RU',
                            context.locale.languageCode == 'ru', isDark),
                        const SizedBox(width: 8),
                        _langButton(context, 'EN',
                            context.locale.languageCode == 'en', isDark),
                      ],
                    ),

                    const SizedBox(height: 48),

                    // Logo
                    Image.asset(
                      'assets/icons/logo.png',
                      width: 100,
                      height: 100,
                      errorBuilder: (_, __, ___) => Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.local_pizza,
                            color: Colors.white, size: 40),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Sarlavha
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'auth.login_title'.tr(),
                        style: AppTextStyles.h1.copyWith(
                          color: isDark
                              ? Colors.white
                              : AppColors.neutral900,
                          fontSize: 28,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'auth.login_subtitle'.tr(),
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.neutral500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Ism maydoni
                    TextField(
                      controller: _nameController,
                      focusNode: _nameFocus,
                      autocorrect: false,
                      enableSuggestions: false,
                      spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => _phoneFocus.requestFocus(),
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: isDark ? Colors.white : AppColors.neutral900,
                      ),
                      decoration: _nameInputDecoration(isDark),
                    ),
                    const SizedBox(height: 16),

                    // Telefon maydoni (doimiy +998 prefiksi bilan)
                    TextField(
                      controller: _phoneController,
                      focusNode: _phoneFocus,
                      autocorrect: false,
                      enableSuggestions: false,
                      spellCheckConfiguration: const SpellCheckConfiguration.disabled(),
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      inputFormatters: const [
                        PhoneNumberFormatter(),
                      ],
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: isDark ? Colors.white : AppColors.neutral900,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                      decoration: _phoneInputDecoration(isDark),
                    ),
                    const SizedBox(height: 32),

                    // Kirish tugmasi
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: state is AuthLoading
                            ? null
                            : () => _onContinue(ctx),
                        child: state is AuthLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5),
                              )
                            : Text('auth.send_sms'.tr()),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Loginsiz davom etish tugmasi (Secondary Action)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          context.go('/home');
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: isDark ? AppColors.darkBorder : AppColors.neutral300,
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          foregroundColor: isDark ? Colors.white : AppColors.neutral800,
                          backgroundColor: isDark ? AppColors.darkCard : const Color(0xFFF9FAFB),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'auth.continue_as_guest'.tr(),
                              style: AppTextStyles.labelMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: isDark ? Colors.white : AppColors.neutral800,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: isDark ? AppColors.neutral400 : AppColors.neutral600,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _langButton(BuildContext context, String lang, bool active, bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        context.setLocale(Locale(lang.toLowerCase()));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary
              : (isDark ? AppColors.darkCard : const Color(0xFFF3F4F6)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? AppColors.primary
                : (isDark ? AppColors.darkBorder : AppColors.neutral200),
            width: 1.5,
          ),
        ),
        child: Text(
          lang,
          style: AppTextStyles.labelSmall.copyWith(
            color: active
                ? Colors.white
                : (isDark ? AppColors.neutral300 : AppColors.neutral700),
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  InputDecoration _nameInputDecoration(bool isDark) => InputDecoration(
        hintText: 'auth.name_hint'.tr(),
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: isDark ? AppColors.neutral500 : AppColors.neutral400,
        ),
        filled: true,
        fillColor: isDark ? AppColors.darkCard : const Color(0xFFF9FAFB),
        prefixIcon: Icon(Icons.person_outline_rounded,
            color: isDark ? AppColors.neutral400 : AppColors.neutral500, size: 20),
        suffixIcon: _nameController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                color: AppColors.neutral400,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _nameController.clear();
                },
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.neutral200,
            width: 1.2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.neutral200,
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.8,
          ),
        ),
      );

  InputDecoration _phoneInputDecoration(bool isDark) => InputDecoration(
        hintText: '(90) 123-45-67',
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: isDark ? AppColors.neutral500 : AppColors.neutral400,
          fontSize: 15,
          fontWeight: FontWeight.w400,
        ),
        filled: true,
        fillColor: isDark ? AppColors.darkCard : const Color(0xFFF9FAFB),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 14, right: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.phone_outlined,
                color: isDark ? AppColors.neutral400 : AppColors.neutral500,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '+998',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: isDark ? Colors.white : AppColors.neutral900,
                  fontWeight: FontWeight.w700,
                  fontSize: 15.5,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 1.2,
                height: 20,
                color: isDark ? AppColors.darkBorder : AppColors.neutral300,
              ),
            ],
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: _phoneController.text.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.close_rounded, size: 18),
                color: AppColors.neutral400,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _phoneController.clear();
                },
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.neutral200,
            width: 1.2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.neutral200,
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.8,
          ),
        ),
      );
}
