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
    return BlocProvider(
      create: (_) => getIt<AuthCubit>(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: BlocConsumer<AuthCubit, AuthState>(
          listener: (ctx, state) {
            if (state is AuthOtpSent) {
              ctx.push('/auth/otp', extra: state.phone);
            } else if (state is AuthFailure) {
              ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ));
            }
          },
          builder: (ctx, state) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    // Language Switcher
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _langButton(context, 'UZ', context.locale.languageCode == 'uz'),
                        const SizedBox(width: 8),
                        _langButton(context, 'RU', context.locale.languageCode == 'ru'),
                        const SizedBox(width: 8),
                        _langButton(context, 'EN', context.locale.languageCode == 'en'),
                      ],
                    ),
                    const SizedBox(height: 60),

                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Вход', style: AppTextStyles.h1.copyWith(color: AppColors.neutral900, fontSize: 32)),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Введите свои данные, чтобы продолжить',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral600),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Name field
                    TextField(
                      controller: _nameController,
                      focusNode: _nameFocus,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => _phoneFocus.requestFocus(),
                      style: AppTextStyles.bodyLarge.copyWith(color: AppColors.neutral900),
                      decoration: _inputDecoration('Ваше имя'),
                    ),
                    const SizedBox(height: 16),

                    // Phone field
                    TextField(
                      controller: _phoneController,
                      focusNode: _phoneFocus,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.done,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      maxLength: 9,
                      style: AppTextStyles.bodyLarge.copyWith(color: AppColors.neutral900),
                      decoration: _inputDecoration('').copyWith(
                        counterText: '',
                        prefixText: '+998 ',
                        prefixStyle: AppTextStyles.bodyLarge.copyWith(color: AppColors.neutral900),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: state is AuthLoading ? null : () => _onContinue(ctx),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.primaryLight,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: state is AuthLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : Text('Отправить SMS', style: AppTextStyles.labelLarge.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.neutral100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.neutral200),
        ),
        child: Text(
          lang,
          style: AppTextStyles.labelSmall.copyWith(
            color: active ? Colors.white : AppColors.neutral600,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.bodyLarge.copyWith(color: AppColors.neutral400),
        filled: true,
        fillColor: AppColors.neutral50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.neutral200, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      );
}
