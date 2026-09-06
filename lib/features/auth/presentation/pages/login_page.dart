import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:pizza_strada/core/di/injection.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _phoneController = TextEditingController(text: '997775443');
  final _nameController = TextEditingController(text: 'Azim');
  final _phoneFocus = FocusNode();
  final _nameFocus = FocusNode();

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _phoneFocus.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _onContinue(BuildContext ctx) {
    String digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('998') && digits.length > 9) {
      digits = digits.substring(3);
    }
    final phone = '+998$digits';
    ctx.read<AuthCubit>().login(
      fullName: _nameController.text.trim(),
      phone: phone,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider(
      create: (_) => getIt<AuthCubit>(),
      child: Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
        body: BlocConsumer<AuthCubit, AuthState>(
          listener: (ctx, state) {
            if (state is AuthOtpSent) {
              ctx.push('/auth/otp', extra: state.phone);
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

                    // Til tanlash tugmalar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _langButton(context, 'UZ',
                            context.locale.languageCode == 'uz'),
                        const SizedBox(width: 8),
                        _langButton(context, 'RU',
                            context.locale.languageCode == 'ru'),
                        const SizedBox(width: 8),
                        _langButton(context, 'EN',
                            context.locale.languageCode == 'en'),
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
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => _phoneFocus.requestFocus(),
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: isDark ? Colors.white : AppColors.neutral900,
                      ),
                      decoration: _inputDecoration(
                        'auth.name_hint'.tr(),
                        Icons.person_outline_rounded,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Telefon maydoni
                    TextField(
                      controller: _phoneController,
                      focusNode: _phoneFocus,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      maxLength: 9,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: isDark ? Colors.white : AppColors.neutral900,
                      ),
                      decoration: _inputDecoration(
                        '',
                        Icons.phone_outlined,
                      ).copyWith(
                        counterText: '',
                        prefixText: '+998 ',
                        prefixStyle: AppTextStyles.bodyLarge.copyWith(
                          color: isDark ? Colors.white : AppColors.neutral900,
                        ),
                      ),
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
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _langButton(BuildContext context, String lang, bool active) {
    return GestureDetector(
      onTap: () {
        context.setLocale(Locale(lang.toLowerCase()));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppColors.primary : AppColors.neutral300,
            width: 1.5,
          ),
        ),
        child: Text(
          lang,
          style: AppTextStyles.labelSmall.copyWith(
            color: active ? Colors.white : AppColors.neutral500,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) =>
      InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.neutral400, size: 20),
      );
}
