import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';

/// 🔐 Bottom Sheet prompting unauthenticated users to confirm login before checkout.
/// Birdan o'tkazib yubormasdan, foydalanuvchiga nima uchun login qilish kerakligini tushuntiradi.
class LoginPromptBottomSheet extends StatelessWidget {
  const LoginPromptBottomSheet({super.key});

  /// Opens the login prompt modal bottom sheet.
  /// Returns `true` if the user opted to log in, `false` or `null` otherwise.
  static Future<bool?> show(
    BuildContext context, {
    String? title,
    String? description,
    IconData? icon,
  }) {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Drag Handle
                Center(
                  child: Container(
                    width: 38,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.neutral700 : AppColors.neutral300,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 2. Icon Badge
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      icon ?? Icons.person_pin_circle_rounded,
                      color: AppColors.primary,
                      size: 34,
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // 3. Title
                Text(
                  title ?? 'checkout.login_prompt_title'.tr(),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.h3.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: 18.5,
                    color: isDark ? Colors.white : AppColors.neutral900,
                  ),
                ),
                const SizedBox(height: 10),

                // 4. Description
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    description ?? 'checkout.login_prompt_desc'.tr(),
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark ? AppColors.neutral400 : AppColors.neutral600,
                      height: 1.45,
                      fontSize: 13.5,
                    ),
                  ),
                ),
                const SizedBox(height: 26),

                // 5. Primary CTA (Tizimga kirish)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      Navigator.of(ctx).pop(true);
                      context.push('/auth/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.login_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'checkout.login_btn'.tr(),
                          style: AppTextStyles.labelLarge.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // 6. Secondary / Cancel CTA (Keyinroq)
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: TextButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.of(ctx).pop(false);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: isDark ? AppColors.neutral400 : AppColors.neutral600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'checkout.cancel_btn'.tr(),
                      style: AppTextStyles.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14.5,
                      ),
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

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

