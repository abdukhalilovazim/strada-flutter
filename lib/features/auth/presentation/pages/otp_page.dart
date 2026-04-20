import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:pizza_strada/core/di/injection.dart';

class OtpPage extends StatefulWidget {
  final String phone;
  const OtpPage({super.key, required this.phone});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  Timer? _timer;
  int _secondsRemaining = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 60;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        setState(() {
          _canResend = true;
          timer.cancel();
        });
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
    super.dispose();
  }

  void _onConfirm(BuildContext ctx) {
    final codeStr = _controllers.map((c) => c.text).join();
    if (codeStr.length == 4) {
      ctx.read<AuthCubit>().confirmOtp(phone: widget.phone, code: int.parse(codeStr));
    }
  }

  void _onResend(BuildContext ctx) {
    if (_canResend) {
      // API call to resend OTP
      ctx.read<AuthCubit>().login(phone: widget.phone, fullName: ""); // fullName empty because they already entered it
      _startTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AuthCubit>(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.neutral900, size: 20),
            onPressed: () => context.pop(),
          ),
        ),
        body: BlocConsumer<AuthCubit, AuthState>(
          listener: (ctx, state) {
            if (state is AuthSuccess) ctx.go('/home');
            if (state is AuthFailure) {
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Text("auth.otp_title".tr(), style: AppTextStyles.h1.copyWith(color: AppColors.neutral900, fontSize: 32)),
                    const SizedBox(height: 8),
                    Text(
                      "auth.otp_subtitle".tr(namedArgs: {"phone": widget.phone}),
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral600),
                    ),
                    const SizedBox(height: 48),

                    // OTP inputs
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(4, (i) {
                        return _buildOtpBox(
                          ctx,
                          controller: _controllers[i],
                          focusNode: _focusNodes[i],
                          index: i,
                        );
                      }),
                    ),
                    const SizedBox(height: 32),

                    // Timer and Resend
                    Center(
                      child: Column(
                        children: [
                          if (!_canResend)
                            Text(
                              "auth.timer".tr(namedArgs: {"seconds": _secondsRemaining.toString()}),
                              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.neutral500),
                            )
                          else
                            TextButton(
                              onPressed: () => _onResend(ctx),
                              child: Text(
                                "auth.resend".tr(),
                                style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    // Confirm button
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: state is AuthLoading ? null : () => _onConfirm(ctx),
                        child: state is AuthLoading
                            ? const SizedBox(
                                width: 22, height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : Text("auth.confirm".tr()),
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

  Widget _buildOtpBox(BuildContext ctx, {required TextEditingController controller, required FocusNode focusNode, required int index}) {
    return SizedBox(
      width: 68,
      height: 68,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        autofocus: index == 0,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        autofillHints: const [AutofillHints.oneTimeCode],
        maxLength: 1,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (val) {
          if (val.isNotEmpty && index < 3) {
            _focusNodes[index + 1].requestFocus();
          } else if (val.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          if (_controllers.every((c) => c.text.isNotEmpty)) {
            _onConfirm(ctx);
          }
        },
        style: AppTextStyles.h1.copyWith(color: AppColors.neutral900),
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: AppColors.neutral50,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.neutral200, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}
