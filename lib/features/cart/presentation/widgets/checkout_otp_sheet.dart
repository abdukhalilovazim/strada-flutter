import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pizza_strada/core/di/injection.dart';
import 'package:pizza_strada/core/network/api_client.dart';
import 'package:pizza_strada/core/storage/secure_storage.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';
import 'package:pizza_strada/core/utils/phone_number_formatter.dart';
import 'package:pizza_strada/core/widgets/app_button.dart';
import 'package:pizza_strada/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:url_launcher/url_launcher.dart';

/// Checkout sahifasidan chiqmasdan OTP kodni tasdiqlash uchun pastki oyna (BottomSheet).
class CheckoutOtpSheet extends StatefulWidget {
  final String phone;
  final String fullName;
  final String initialChannel;

  const CheckoutOtpSheet({
    super.key,
    required this.phone,
    required this.fullName,
    this.initialChannel = 'sms',
  });

  static Future<bool?> show(
    BuildContext context, {
    required String phone,
    required String fullName,
    String initialChannel = 'sms',
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CheckoutOtpSheet(
        phone: phone,
        fullName: fullName,
        initialChannel: initialChannel,
      ),
    );
  }

  @override
  State<CheckoutOtpSheet> createState() => _CheckoutOtpSheetState();
}

class _CheckoutOtpSheetState extends State<CheckoutOtpSheet> {
  late String _channel;
  final List<TextEditingController> _controllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());

  Timer? _timer;
  int _secondsRemaining = 60;
  bool _canResend = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _channel = widget.initialChannel;
    _startTimer();
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 60;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
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
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> _resendCode({bool forceS = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authDs = getIt<AuthRemoteDataSource>();
      final res = await authDs.loginWithChannel(
        fullName: widget.fullName.trim().isNotEmpty ? widget.fullName.trim() : 'Mijoz',
        phone: widget.phone,
        forceSms: forceS,
      );

      final newChannel = res['channel']?.toString() ?? (forceS ? 'sms' : _channel);
      if (mounted) {
        setState(() {
          _channel = newChannel;
          _isLoading = false;
          for (final c in _controllers) {
            c.clear();
          }
        });
        _startTimer();
        _focusNodes[0].requestFocus();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e is ApiException ? e.message : 'auth.login_error'.tr();
        });
      }
    }
  }

  Future<void> _confirmOtp() async {
    final code = _controllers.map((c) => c.text).join();
    if (code.length != 4) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authDs = getIt<AuthRemoteDataSource>();
      final userModel = await authDs.confirmOtp(
        phone: widget.phone,
        code: code,
      );

      await SecureStorage.saveToken(userModel.token);
      await SecureStorage.saveUserInfo(
        name: userModel.fullName,
        phone: userModel.phone,
      );

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e is ApiException ? e.message : 'auth.otp_invalid'.tr();
          for (final c in _controllers) {
            c.clear();
          }
        });
        _focusNodes[0].requestFocus();
      }
    }
  }

  Future<void> _openTelegramBot() async {
    final tgUri = Uri.parse('https://t.me/StradaPizzaBot');
    try {
      if (await canLaunchUrl(tgUri)) {
        await launchUrl(tgUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isTelegram = _channel == 'telegram';

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 16,
        bottom: 24 + bottomInset,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.neutral700 : AppColors.neutral300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Channel Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isTelegram
                    ? const Color(0xFF0088CC).withValues(alpha: 0.12)
                    : AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isTelegram ? Icons.send_rounded : Icons.sms_rounded,
                size: 32,
                color: isTelegram ? const Color(0xFF0088CC) : AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              isTelegram
                  ? 'checkout.otp_title_telegram'.tr()
                  : 'checkout.otp_title_sms'.tr(),
              style: AppTextStyles.h2.copyWith(
                color: Theme.of(context).textTheme.headlineMedium?.color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              isTelegram
                  ? 'checkout.otp_sent_telegram'.tr()
                  : 'checkout.otp_sent_sms'.tr(
                      namedArgs: {'phone': PhoneNumberFormatter.formatFull(widget.phone)},
                    ),
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDark ? AppColors.neutral400 : AppColors.neutral600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Telegram Bot Quick Button
            if (isTelegram) ...[
              OutlinedButton.icon(
                onPressed: _openTelegramBot,
                icon: const Icon(Icons.telegram_rounded, color: Color(0xFF0088CC), size: 20),
                label: Text(
                  'checkout.open_telegram_bot'.tr(),
                  style: AppTextStyles.labelMedium.copyWith(
                    color: const Color(0xFF0088CC),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF0088CC), width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Error Message
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _errorMessage!,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            const SizedBox(height: 12),

            // 4-digit PIN Inputs
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(4, (index) {
                return SizedBox(
                  width: 62,
                  height: 62,
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
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
                        _confirmOtp();
                      }
                    },
                    style: AppTextStyles.h1.copyWith(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: isDark ? AppColors.darkSurface : AppColors.neutral50,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: isDark ? AppColors.neutral800 : AppColors.neutral200,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                      ),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),

            // Timer / Resend
            Center(
              child: Column(
                children: [
                  if (!_canResend)
                    Text(
                      'auth.timer'.tr(namedArgs: {'seconds': _secondsRemaining.toString()}),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isDark ? AppColors.neutral400 : AppColors.neutral500,
                      ),
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: _isLoading ? null : () => _resendCode(),
                          child: Text(
                            'auth.resend'.tr(),
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (isTelegram) ...[
                          const Text(' • '),
                          TextButton(
                            onPressed: _isLoading ? null : () => _resendCode(forceS: true),
                            child: Text(
                              'checkout.resend_via_sms'.tr(),
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Confirm Button
            AppButton(
              text: 'auth.confirm'.tr(),
              isLoading: _isLoading,
              onTap: _isLoading ? null : _confirmOtp,
            ),
          ],
        ),
      ),
    );
  }
}
