import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

/// 🔄 Full-Screen SDUI Interface Update View
/// Displayed whenever a server version mismatch is detected:
/// 1. Loader with "UI yangilanmoqda..."
/// 2. Smoothly transitions to Green Checkmark with "UI yangilandi!"
class SDUIUpdateView extends StatefulWidget {
  final bool isSuccess;
  final String title;
  final String? subtitle;

  const SDUIUpdateView({
    super.key,
    required this.isSuccess,
    this.title = 'UI yangilanmoqda...',
    this.subtitle,
  });

  @override
  State<SDUIUpdateView> createState() => _SDUIUpdateViewState();
}

class _SDUIUpdateViewState extends State<SDUIUpdateView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
    if (widget.isSuccess) {
      _triggerSuccess();
    }
  }

  @override
  void didUpdateWidget(covariant SDUIUpdateView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isSuccess && widget.isSuccess) {
      _triggerSuccess();
    }
  }

  void _triggerSuccess() {
    HapticFeedback.mediumImpact();
    _animController.forward(from: 0.0);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkSurface : Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Top Brand Mark
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'S',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 28,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                // Animated Indicator (Loader vs Success Checkmark)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                  child: widget.isSuccess
                      ? ScaleTransition(
                          key: const ValueKey('success_state'),
                          scale: _scaleAnimation,
                          child: Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.success.withValues(alpha: 0.5),
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.check_circle_rounded,
                              size: 56,
                              color: AppColors.success,
                            ),
                          ),
                        )
                      : Container(
                          key: const ValueKey('loading_state'),
                          width: 84,
                          height: 84,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : const Color(0xFFF8F9FA),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? AppColors.darkBorder : AppColors.neutral200,
                              width: 1.5,
                            ),
                          ),
                          child: const CircularProgressIndicator(
                            strokeWidth: 3.2,
                            color: AppColors.primary,
                          ),
                        ),
                ),
                const SizedBox(height: 28),

                // Title
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    widget.isSuccess ? 'UI yangilandi!' : widget.title,
                    key: ValueKey(widget.isSuccess ? 'title_success' : 'title_loading'),
                    style: AppTextStyles.h3.copyWith(
                      fontWeight: FontWeight.w800,
                      color: widget.isSuccess
                          ? AppColors.success
                          : (isDark ? Colors.white : AppColors.neutral900),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    widget.isSuccess
                        ? 'Yangi interfeys muvaffaqiyatli yuklandi'
                        : (widget.subtitle ?? 'Yangi dizayn va menyu yangilanmoqda...'),
                    key: ValueKey(widget.isSuccess ? 'sub_success' : 'sub_loading'),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isDark ? AppColors.neutral400 : AppColors.neutral500,
                    ),
                    textAlign: TextAlign.center,
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

