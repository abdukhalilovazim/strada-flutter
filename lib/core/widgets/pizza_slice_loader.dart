import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';

/// 🍕 PizzaSliceLoader — Strada Pizza'ning haqiqiy ishtahaochar pitsasini
/// 6 ta mustaqil bo'lakka (slices) bo'lib, har bir bo'lakni silliq (120 FPS),
/// 3D chuqurlikdagi radial to'lqin (wave) va ketma-ket yig'ilish (assembly)
/// orqali ko'rsatuvchi eng zamonaviy UI/UX loader komponenti.
class PizzaSliceLoader extends StatefulWidget {
  final double size;
  final int sliceCount;
  final bool animateIntro;
  final bool loopWave;
  final double baseSeparation;
  final double liftDistance;
  final Duration introDuration;
  final Duration waveDuration;

  const PizzaSliceLoader({
    super.key,
    this.size = 130,
    this.sliceCount = 6,
    this.animateIntro = true,
    this.loopWave = true,
    this.baseSeparation = 1.8,
    this.liftDistance = 6.0,
    this.introDuration = const Duration(milliseconds: 1100),
    this.waveDuration = const Duration(milliseconds: 1800),
    Duration? rotationDuration,
    Duration? pulseDuration,
    Duration? duration,
    bool? is3D,
  });

  @override
  State<PizzaSliceLoader> createState() => _PizzaSliceLoaderState();
}

class _PizzaSliceLoaderState extends State<PizzaSliceLoader>
    with TickerProviderStateMixin {
  late final AnimationController _introController;
  late final AnimationController _waveController;
  late final AnimationController _ambientRotationController;
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Ketma-ket bo'laklar yig'ilishi (Intro Assembly)
    _introController = AnimationController(
      vsync: this,
      duration: widget.introDuration,
    );

    // 2. Soat mili bo'ylab silliq to'lqinsimon suzish (Clockwise Radial Wave)
    _waveController = AnimationController(
      vsync: this,
      duration: widget.waveDuration,
    );

    // 3. Butun pitsaning nafis 360° ambient aylanishi
    _ambientRotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat();

    // 4. Nafis nafas olish (breathing) pulsatsiyasi
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.98, end: 1.025).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOutSine,
      ),
    );

    if (widget.animateIntro) {
      _introController.forward().then((_) {
        if (mounted && widget.loopWave) {
          _waveController.repeat();
        }
      });
    } else {
      _introController.value = 1.0;
      if (widget.loopWave) {
        _waveController.repeat();
      }
    }
  }

  @override
  void dispose() {
    _introController.dispose();
    _waveController.dispose();
    _ambientRotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _introController,
          _waveController,
          _ambientRotationController,
          _pulseAnimation,
        ]),
        builder: (context, _) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: SizedBox(
              width: widget.size + 24,
              height: widget.size + 24,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 🌟 Orqa fon: Issiq pishgan pitsa nuri (Ambient Warm Glow)
                  _buildAmbientGlow(),

                  // 🍕 Asosiy aylanuvchi pitsa doskasi va bo'laklari
                  RotationTransition(
                    turns: _ambientRotationController,
                    child: SizedBox(
                      width: widget.size,
                      height: widget.size,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 🪵 Pitsa ostidagi nozik kesim chiziqlari va patnis (Platter Base)
                          CustomPaint(
                            size: Size(widget.size, widget.size),
                            painter: _PizzaBoardPainter(
                              sliceCount: widget.sliceCount,
                              isDark: isDark,
                            ),
                          ),

                          // 🍕 Bo'laklarga ajratilgan 6 ta haqiqiy pitsa qismlari (Slices)
                          ...List.generate(widget.sliceCount, (index) {
                            return _buildSlice(index, widget.size, isDark);
                          }),
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
    );
  }

  /// 🌟 Issiq pishgan pitsa atrofidagi yumshoq yog'du
  Widget _buildAmbientGlow() {
    return Container(
      width: widget.size + 16,
      height: widget.size + 16,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.16),
            const Color(0xFFFFA000).withValues(alpha: 0.08),
            Colors.transparent,
          ],
          stops: const [0.55, 0.82, 1.0],
        ),
      ),
    );
  }

  /// 🍕 Har bir alohida pitsa bo'lagini hisoblash va render qilish
  Widget _buildSlice(int index, double size, bool isDark) {
    final count = widget.sliceCount;
    final sweepAngle = (2 * math.pi) / count;
    // Soat 12 dan (yuqoridan) boshlanadi (-pi / 2)
    final startAngle = -math.pi / 2 + (index * sweepAngle);
    final midAngle = startAngle + (sweepAngle / 2);

    // 1. Intro Assembly qiymatlari (0.0 -> 1.0)
    final introVal = _introController.value;
    final sliceIntroStart = (index / count) * 0.75;
    final sliceIntroEnd = ((index + 1) / count).clamp(0.0, 1.0);
    final sliceIntroProgress = ((introVal - sliceIntroStart) /
            (sliceIntroEnd - sliceIntroStart))
        .clamp(0.0, 1.0);

    // Bouncy spring curve for slice drop-in
    final curvedIntro = Curves.easeOutBack.transform(sliceIntroProgress);

    // 2. Radial Wave qiymatlari (soat mili bo'yicha to'lqin)
    double waveLift = 0.0;
    if (_waveController.isAnimating) {
      final waveProgress = _waveController.value;
      final sliceNormMid = index / count;
      double diff = (waveProgress - sliceNormMid).abs();
      if (diff > 0.5) diff = 1.0 - diff;

      final waveWindow = 1.0 / count;
      if (diff < waveWindow) {
        final normalizedDist = diff / waveWindow;
        // Cosine bell curve (0.0 -> 1.0 -> 0.0)
        waveLift = (1.0 + math.cos(normalizedDist * math.pi)) / 2.0;
      }
    }

    // 3. Masofa, ko'lam va ko'tarilish (Elevation)
    // Asosiy bo'laklararo tirqish (2.5px) + to'lqindagi radial siljish
    final totalDistance = (widget.baseSeparation * curvedIntro) +
        (widget.liftDistance * waveLift * curvedIntro);
    final dx = math.cos(midAngle) * totalDistance;
    final dy = math.sin(midAngle) * totalDistance;

    final scale = (0.2 + (0.8 * curvedIntro)) + (0.06 * waveLift);
    final opacity = curvedIntro.clamp(0.0, 1.0);
    final elevation = (2.0 + (9.0 * waveLift)) * curvedIntro;

    // Sektorning geometrik og'irlik markazi (Centroid alignment)
    final alpha = sweepAngle / 2;
    final rCentroid = (2.0 / 3.0) * (math.sin(alpha) / alpha);
    final alignX = math.cos(midAngle) * rCentroid;
    final alignY = math.sin(midAngle) * rCentroid;

    final slicePath = _getSlicePath(Size(size, size), startAngle, sweepAngle);

    return Opacity(
      opacity: opacity,
      child: Transform.translate(
        offset: Offset(dx, dy),
        child: Transform.scale(
          scale: scale,
          alignment: Alignment(alignX, alignY),
          child: Stack(
            children: [
              // 3D Soya (Har bir bo'lakning o'ziga xos soyasi)
              CustomPaint(
                size: Size(size, size),
                painter: _SliceShadowPainter(
                  path: slicePath,
                  elevation: elevation,
                  shadowColor: isDark
                      ? Colors.black.withValues(alpha: 0.55)
                      : const Color(0xFF2C1810).withValues(alpha: 0.32),
                ),
              ),

              // Kesilgan haqiqiy pitsa surati
              ClipPath(
                clipper: _PizzaSliceClipper(
                  startAngle: startAngle,
                  sweepAngle: sweepAngle,
                ),
                child: Image.asset(
                  'assets/images/splash_pizza.png',
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.local_pizza_rounded,
                        size: 64, color: Colors.orange),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Path _getSlicePath(Size size, double startAngle, double sweepAngle) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final path = Path();
    path.moveTo(center.dx, center.dy);
    path.arcTo(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
    );
    path.close();
    return path;
  }
}

/// 📐 Pitsaning matematik aniq sektorini kesib oluvchi Clipper
class _PizzaSliceClipper extends CustomClipper<Path> {
  final double startAngle;
  final double sweepAngle;

  const _PizzaSliceClipper({
    required this.startAngle,
    required this.sweepAngle,
  });

  @override
  Path getClip(Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final path = Path();
    path.moveTo(center.dx, center.dy);
    path.arcTo(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
    );
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant _PizzaSliceClipper oldClipper) {
    return oldClipper.startAngle != startAngle ||
        oldClipper.sweepAngle != sweepAngle;
  }
}

/// 🌑 Har bir bo'lak ostiga realistik 3D Gaussian soya chizuvchi Painter
class _SliceShadowPainter extends CustomPainter {
  final Path path;
  final double elevation;
  final Color shadowColor;

  const _SliceShadowPainter({
    required this.path,
    required this.elevation,
    required this.shadowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (elevation > 0.1) {
      canvas.drawShadow(path, shadowColor, elevation, true);
    }
  }

  @override
  bool shouldRepaint(covariant _SliceShadowPainter oldDelegate) {
    return oldDelegate.elevation != elevation ||
        oldDelegate.shadowColor != shadowColor;
  }
}

/// 🪵 Pitsa ostidagi nafis patnis va kesim izlari (Cut Grooves)
class _PizzaBoardPainter extends CustomPainter {
  final int sliceCount;
  final bool isDark;

  const _PizzaBoardPainter({
    required this.sliceCount,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Patnis foni va cheti (Subtle board edge)
    final boardPaint = Paint()
      ..color = isDark
          ? const Color(0xFF1E1E24)
          : const Color(0xFFFFF3E0).withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius + 2, boardPaint);

    final rimPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: 0.08)
          : const Color(0xFFFFB74D).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius + 2, rimPaint);

    // 2. Markazdan chiquvchi pichoq kesimlari (Knife cut lines)
    final cutPaint = Paint()
      ..color = isDark
          ? Colors.black.withValues(alpha: 0.4)
          : const Color(0xFFD7CCC8).withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final sweepAngle = (2 * math.pi) / sliceCount;
    for (int i = 0; i < sliceCount; i++) {
      final angle = -math.pi / 2 + (i * sweepAngle);
      final p2 = Offset(
        center.dx + math.cos(angle) * (radius - 2),
        center.dy + math.sin(angle) * (radius - 2),
      );
      canvas.drawLine(center, p2, cutPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PizzaBoardPainter oldDelegate) {
    return oldDelegate.sliceCount != sliceCount ||
        oldDelegate.isDark != isDark;
  }
}
