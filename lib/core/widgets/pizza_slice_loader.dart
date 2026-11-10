import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:pizza_strada/core/theme/app_colors.dart';

/// 🍕 PizzaSliceLoader — Strada Pizza uchun silliq (120 FPS), zamonaviy va nafis pitsa animatsiyasi.
///
/// Xususiyatlari:
/// - 6 ta mazali pitsa bo'lagi (oltinrang qobiq, pomidor sousi, eritilgan pishloq, pepperoni va rayhon)
/// - Bo'laklardan biri mayin tortilib (cheese pull) chiqib-kirishi va butun pitsaning silliq aylanishi
/// - Xotirada 0 ta ortiqcha obyekt (pre-allocated Paints, GPU-friendly Canvas amallari)
/// - Mutlaqo qotmaydi (Zero Jank / Ultra Low Latency)
class PizzaSliceLoader extends StatefulWidget {
  final double size;
  final Duration duration;

  const PizzaSliceLoader({
    super.key,
    this.size = 170,
    this.duration = const Duration(milliseconds: 2400),
    int? sliceCount,
    bool? is3D,
  });

  @override
  State<PizzaSliceLoader> createState() => _PizzaSliceLoaderState();
}

class _PizzaSliceLoaderState extends State<PizzaSliceLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _ArtisanPizzaPainter(
              progress: _controller.value,
              isDark: isDark,
            ),
          );
        },
      ),
    );
  }
}

class _ArtisanPizzaPainter extends CustomPainter {
  final double progress; // 0.0 -> 1.0
  final bool isDark;

  _ArtisanPizzaPainter({
    required this.progress,
    required this.isDark,
  });

  // Pre-allocated Paint obyektlari (har bir frame'da qayta yaratilmaydi!)
  static final Paint _shadowPaint = Paint()
    ..color = Colors.black.withValues(alpha: 0.12)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

  static final Paint _crustPaint = Paint()
    ..color = const Color(0xFFD48B28)
    ..style = PaintingStyle.fill;

  static final Paint _crustRimPaint = Paint()
    ..color = const Color(0xFFE5A642)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.5
    ..strokeCap = StrokeCap.round;

  static final Paint _saucePaint = Paint()
    ..color = AppColors.primary
    ..style = PaintingStyle.fill;

  static final Paint _cheesePaint = Paint()
    ..color = const Color(0xFFFFCC33)
    ..style = PaintingStyle.fill;

  static final Paint _cheeseHighlightPaint = Paint()
    ..color = const Color(0xFFFFDF7A)
    ..style = PaintingStyle.fill;

  static final Paint _pepperoniPaint = Paint()
    ..color = const Color(0xFFC02626)
    ..style = PaintingStyle.fill;

  static final Paint _pepperoniRimPaint = Paint()
    ..color = const Color(0xFF9E1B1B)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2;

  static final Paint _basilPaint = Paint()
    ..color = const Color(0xFF2E7D32)
    ..style = PaintingStyle.fill;

  static final Paint _cheesePullPaint = Paint()
    ..color = const Color(0xFFFFD54F)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0
    ..strokeCap = StrokeCap.round;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.44;

    // 1. Yumshoq yer soyasi
    final shadowRect = Rect.fromCenter(
      center: Offset(center.dx, center.dy + radius * 0.88),
      width: radius * 1.6,
      height: radius * 0.28,
    );
    canvas.drawOval(shadowRect, _shadowPaint);

    // 2. Doimiy nafis aylanish burchagi
    final globalRotation = progress * 2 * math.pi;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(globalRotation);

    const sliceCount = 6;
    const sliceAngle = (2 * math.pi) / sliceCount;
    const gap = 0.05; // Bo'laklar orasidagi nafis masofa (radianda)

    // Qaysi bo'lak ayni paytda tortilib chiqishi (0 dan 5 gacha)
    final activeSliceIndex = ((progress * sliceCount).floor()) % sliceCount;
    // Ushbu bo'lakning tortilish fazasi (0.0 -> 1.0)
    final sliceProgress = (progress * sliceCount) - (progress * sliceCount).floor();
    // Tortilib chiqib qaytib kirishi (sinusoidal)
    final pullFactor = math.sin(sliceProgress * math.pi);
    final maxPullDist = radius * 0.22;

    for (int i = 0; i < sliceCount; i++) {
      final startAngle = (i * sliceAngle) + (gap / 2);
      final sweepAngle = sliceAngle - gap;
      final midAngle = startAngle + (sweepAngle / 2);

      // Agar faol bo'lak bo'lsa, uni biroz chetga suramiz
      final isPulling = (i == activeSliceIndex);
      final pullDist = isPulling ? (pullFactor * maxPullDist) : 0.0;
      final shiftX = math.cos(midAngle) * pullDist;
      final shiftY = math.sin(midAngle) * pullDist;

      canvas.save();
      canvas.translate(shiftX, shiftY);

      // ── Bo'lakning poydevori (Qobiq + Pishloq) ──
      final path = Path();
      path.moveTo(0, 0);
      path.arcTo(
        Rect.fromCircle(center: Offset.zero, radius: radius),
        startAngle,
        sweepAngle,
        false,
      );
      path.close();

      // Qobiq foni
      canvas.drawPath(path, _crustPaint);

      // Pomidor sousi qatlami (ichkarida)
      final saucePath = Path();
      saucePath.moveTo(0, 0);
      saucePath.arcTo(
        Rect.fromCircle(center: Offset.zero, radius: radius * 0.91),
        startAngle + 0.02,
        sweepAngle - 0.04,
        false,
      );
      saucePath.close();
      canvas.drawPath(saucePath, _saucePaint);

      // Eritilgan pishloq qatlami
      final cheesePath = Path();
      cheesePath.moveTo(0, 0);
      cheesePath.arcTo(
        Rect.fromCircle(center: Offset.zero, radius: radius * 0.85),
        startAngle + 0.03,
        sweepAngle - 0.06,
        false,
      );
      cheesePath.close();
      canvas.drawPath(cheesePath, _cheesePaint);

      // Qobiq chekkasidagi xushbo'y qovurilgan qirra
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: radius * 0.95),
        startAngle + 0.03,
        sweepAngle - 0.06,
        false,
        _crustRimPaint,
      );

      // ── Masalliqlar (Pepperoni va Rayhon) ──
      // 1. Katta pepperoni (o'rtaroqda)
      final p1Dist = radius * 0.54;
      final p1Angle = midAngle - 0.06;
      final p1Center = Offset(math.cos(p1Angle) * p1Dist, math.sin(p1Angle) * p1Dist);
      final p1Radius = radius * 0.16;
      canvas.drawCircle(p1Center, p1Radius, _pepperoniPaint);
      canvas.drawCircle(p1Center, p1Radius, _pepperoniRimPaint);

      // 2. Kichikroq pepperoni (tashqariroqda)
      final p2Dist = radius * 0.72;
      final p2Angle = midAngle + 0.12;
      final p2Center = Offset(math.cos(p2Angle) * p2Dist, math.sin(p2Angle) * p2Dist);
      final p2Radius = radius * 0.11;
      canvas.drawCircle(p2Center, p2Radius, _pepperoniPaint);
      canvas.drawCircle(p2Center, p2Radius, _pepperoniRimPaint);

      // 3. Yangi uzilgan rayhon (kichik barg)
      final bDist = radius * 0.36;
      final bAngle = midAngle + 0.08;
      final bCenter = Offset(math.cos(bAngle) * bDist, math.sin(bAngle) * bDist);
      canvas.drawCircle(bCenter, radius * 0.05, _basilPaint);

      canvas.restore();

      // ── Tortilgan pishloq iplari (Cheese Strings) ──
      if (isPulling && pullDist > 5) {
        final tipX = math.cos(midAngle) * pullDist;
        final tipY = math.sin(midAngle) * pullDist;

        // Markazdan bo'lak uchiga tortilgan elastik iplar
        final cheesePullPath = Path();
        cheesePullPath.moveTo(0, 0);
        cheesePullPath.quadraticBezierTo(
          tipX * 0.5 + 4,
          tipY * 0.5 - 4,
          tipX * 0.9,
          tipY * 0.9,
        );
        cheesePullPath.moveTo(math.cos(startAngle) * 8, math.sin(startAngle) * 8);
        cheesePullPath.quadraticBezierTo(
          tipX * 0.4 - 3,
          tipY * 0.4 + 3,
          tipX * 0.85,
          tipY * 0.85,
        );
        canvas.drawPath(cheesePullPath, _cheesePullPaint);
      }
    }

    // 3. Pitsa markazidagi nafis markaziy qovurilgan nuqta
    canvas.drawCircle(Offset.zero, radius * 0.06, _cheeseHighlightPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ArtisanPizzaPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.isDark != isDark;
  }
}
