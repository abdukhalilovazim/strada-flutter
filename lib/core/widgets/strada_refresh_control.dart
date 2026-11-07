import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pizza_strada/core/extensions/string_extensions.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';
import 'package:pizza_strada/core/theme/app_text_styles.dart';

/// 🍕 Strada Custom Pull-to-Refresh Sliver Control
/// Replaces the generic Material spinner with an appetizing, interactive
/// spinning pizza loader with haptic feedback and dynamic state badges.
class StradaSliverRefreshControl extends StatelessWidget {
  final Future<void> Function()? onRefresh;
  final double refreshTriggerPullDistance;
  final double refreshIndicatorExtent;

  const StradaSliverRefreshControl({
    super.key,
    required this.onRefresh,
    this.refreshTriggerPullDistance = 80.0,
    this.refreshIndicatorExtent = 60.0,
  });

  @override
  Widget build(BuildContext context) {
    if (onRefresh == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return CupertinoSliverRefreshControl(
      refreshTriggerPullDistance: refreshTriggerPullDistance,
      refreshIndicatorExtent: refreshIndicatorExtent,
      onRefresh: onRefresh,
      builder: (
        BuildContext context,
        RefreshIndicatorMode refreshState,
        double pulledExtent,
        double refreshTriggerPullDistance,
        double refreshIndicatorExtent,
      ) {
        return StradaRefreshIndicatorView(
          refreshState: refreshState,
          pulledExtent: pulledExtent,
          refreshTriggerPullDistance: refreshTriggerPullDistance,
          refreshIndicatorExtent: refreshIndicatorExtent,
        );
      },
    );
  }
}

/// 🎨 Interactive Animated View for Strada Pull-to-Refresh
class StradaRefreshIndicatorView extends StatefulWidget {
  final RefreshIndicatorMode refreshState;
  final double pulledExtent;
  final double refreshTriggerPullDistance;
  final double refreshIndicatorExtent;

  const StradaRefreshIndicatorView({
    super.key,
    required this.refreshState,
    required this.pulledExtent,
    required this.refreshTriggerPullDistance,
    required this.refreshIndicatorExtent,
  });

  @override
  State<StradaRefreshIndicatorView> createState() => _StradaRefreshIndicatorViewState();
}

class _StradaRefreshIndicatorViewState extends State<StradaRefreshIndicatorView>
    with TickerProviderStateMixin {
  late final AnimationController _spinController;
  late final AnimationController _pulseController;
  bool _hasHapticed = false;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    if (widget.refreshState == RefreshIndicatorMode.refresh) {
      _spinController.repeat();
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant StradaRefreshIndicatorView oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Haptic feedback when pull threshold is reached
    if (widget.refreshState == RefreshIndicatorMode.armed && !_hasHapticed) {
      HapticFeedback.mediumImpact();
      _hasHapticed = true;
    } else if (widget.refreshState == RefreshIndicatorMode.inactive) {
      _hasHapticed = false;
    }

    // Spin animation management
    if (widget.refreshState == RefreshIndicatorMode.refresh) {
      if (!_spinController.isAnimating) {
        _spinController.repeat();
        _pulseController.repeat(reverse: true);
      }
    } else if (widget.refreshState == RefreshIndicatorMode.done ||
        widget.refreshState == RefreshIndicatorMode.inactive) {
      if (_spinController.isAnimating) {
        _spinController.stop();
        _pulseController.stop();
      }
    }
  }

  @override
  void dispose() {
    _spinController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pulled = widget.pulledExtent;

    if (pulled < 12.0) {
      return const SizedBox.shrink();
    }

    final progress = (pulled / widget.refreshTriggerPullDistance).clamp(0.0, 1.0);
    final opacity = ((pulled - 12.0) / 36.0).clamp(0.0, 1.0);
    final scale = (0.75 + (progress * 0.25)).clamp(0.75, 1.0);
    final isRefreshing = widget.refreshState == RefreshIndicatorMode.refresh;
    final isArmed = widget.refreshState == RefreshIndicatorMode.armed;
    final isDone = widget.refreshState == RefreshIndicatorMode.done;

    // Label and icon state
    String label;
    if (isDone) {
      label = 'refresh.done'.trOr('Tayyor! ✨');
    } else if (isRefreshing) {
      label = 'refresh.refreshing'.trOr('Sahifa yangilanmoqda');
    } else if (isArmed) {
      label = 'refresh.armed'.trOr('Qo\'yib yuboring! 🍕');
    } else {
      label = 'refresh.pull'.trOr('Yangilash uchun torting');
    }

    return Container(
      height: pulled,
      alignment: Alignment.center,
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: scale,
          child: AnimatedBuilder(
            animation: Listenable.merge([_spinController, _pulseController]),
            builder: (context, _) {
              final pulse = isRefreshing ? (_pulseController.value * 0.08) : 0.0;

              return Transform.scale(
                scale: 1.0 + pulse,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isRefreshing
                          ? AppColors.primary.withValues(alpha: 0.45)
                          : (isArmed
                              ? AppColors.primary
                              : (isDark ? AppColors.darkBorder : AppColors.neutral200)),
                      width: isArmed ? 1.5 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isRefreshing || isArmed
                            ? AppColors.primary.withValues(alpha: isDark ? 0.35 : 0.2)
                            : Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                        blurRadius: isRefreshing ? 14 : 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 🍕 Animated Pizza Ring & Icon
                      SizedBox(
                        width: 26,
                        height: 26,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Circular Progress Arc
                            CustomPaint(
                              size: const Size(26, 26),
                              painter: _PizzaProgressPainter(
                                progress: isRefreshing ? 1.0 : progress,
                                isRefreshing: isRefreshing,
                                spinValue: _spinController.value,
                                activeColor: AppColors.primary,
                                trackColor: isDark
                                    ? AppColors.darkBorder
                                    : AppColors.neutral200.withValues(alpha: 0.8),
                              ),
                            ),
                            // Pizza Disk / Icon
                            Transform.rotate(
                              angle: isRefreshing
                                  ? (_spinController.value * 2 * math.pi)
                                  : (progress * 2 * math.pi),
                              child: Image.asset(
                                'assets/icons/pizza_placeholder.png',
                                width: 17,
                                height: 17,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.local_pizza_rounded,
                                  color: AppColors.primary,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Text Label
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          label,
                          key: ValueKey(label),
                          style: AppTextStyles.bodyExtraSmall.copyWith(
                            fontWeight: (isArmed || isRefreshing || isDone)
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: (isArmed || isRefreshing)
                                ? AppColors.primary
                                : (isDone
                                    ? AppColors.success
                                    : (isDark ? AppColors.neutral300 : AppColors.neutral700)),
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
      ),
    );
  }
}

/// 🎨 Custom Painter that renders an elegant progress arc around the pizza
class _PizzaProgressPainter extends CustomPainter {
  final double progress;
  final bool isRefreshing;
  final double spinValue;
  final Color activeColor;
  final Color trackColor;

  _PizzaProgressPainter({
    required this.progress,
    required this.isRefreshing,
    required this.spinValue,
    required this.activeColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 2.2;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // 1. Draw subtle background track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    // 2. Draw active arc
    final activePaint = Paint()
      ..color = activeColor
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    if (isRefreshing) {
      // Rotating 270° arc during refresh
      final startAngle = (spinValue * 2 * math.pi);
      const sweepAngle = 1.5 * math.pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        activePaint,
      );
    } else {
      // Progress from top (-pi/2)
      const startAngle = -math.pi / 2;
      final sweepAngle = 2 * math.pi * progress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PizzaProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isRefreshing != isRefreshing ||
        oldDelegate.spinValue != spinValue ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.trackColor != trackColor;
  }
}
