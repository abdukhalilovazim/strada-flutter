import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 🍕 PizzaSliceLoader — Strada Pizza uchun maxsus interaktiv pitsa loading animatsiyasi.
/// Pitsa bo'laklari (6 ta bo'lak) birin-ketin tashqariga chiqib (pop-out)
/// va joyiga qaytib kiradi (pop-in), qobiq, pishloq va pepperoni detallari bilan.
class PizzaSliceLoader extends StatefulWidget {
  final double size;
  final int sliceCount;
  final Duration duration;

  const PizzaSliceLoader({
    super.key,
    this.size = 150,
    this.sliceCount = 6,
    this.duration = const Duration(milliseconds: 1800),
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
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _PizzaPainter(
            progress: _controller.value,
            sliceCount: widget.sliceCount,
          ),
        );
      },
    );
  }
}

class _PizzaPainter extends CustomPainter {
  final double progress;
  final int sliceCount;

  _PizzaPainter({
    required this.progress,
    required this.sliceCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 * 0.82;
    final sliceAngle = (2 * math.pi) / sliceCount;
    const gapAngle = 0.05; // Bo'laklar orasidagi bo'shliq (rad)

    // Pitsa tagidagi yengil umumiy soya
    final boardPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.06)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(center.translate(0, 8), radius + 6, boardPaint);

    for (int i = 0; i < sliceCount; i++) {
      // Har bir bo'lakning markaziy burchagi (tepadan boshlanadi: -pi / 2)
      final startAngle = -math.pi / 2 + (i * sliceAngle) + (gapAngle / 2);
      final sweepAngle = sliceAngle - gapAngle;
      final midAngle = startAngle + (sweepAngle / 2);

      // Bo'lakning chiqib-kirish animatsiya progressini hisoblash
      // Har bir bo'lak sikl davomida navbati bilan chiqib kiradi
      final sliceOffset = _calculateSliceOffset(i, sliceCount, progress);

      // Chiqish yo'nalishi (radial vektor)
      final maxDistance = radius * 0.18; // 18% ga tashqariga chiqadi
      final currentDistance = maxDistance * sliceOffset;
      final sliceCenter = Offset(
        center.dx + math.cos(midAngle) * currentDistance,
        center.dy + math.sin(midAngle) * currentDistance,
      );

      canvas.save();
      // Chiqqan bo'lak biroz kattalashadi
      final scale = 1.0 + (0.05 * sliceOffset);
      canvas.translate(sliceCenter.dx, sliceCenter.dy);
      canvas.scale(scale);
      canvas.translate(-sliceCenter.dx, -sliceCenter.dy);

      // Agar bo'lak tashqarida bo'lsa, uning tagiga alohida soya beramiz
      if (sliceOffset > 0.05) {
        final sliceShadowPaint = Paint()
          ..color = Colors.black.withValues(alpha: 0.18 * sliceOffset)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * sliceOffset);

        final shadowPath = _createSlicePath(
          sliceCenter.translate(0, 6 * sliceOffset),
          radius,
          startAngle,
          sweepAngle,
        );
        canvas.drawPath(shadowPath, sliceShadowPaint);
      }

      // 1. Qobiq (Crust)
      _drawCrust(canvas, sliceCenter, radius, startAngle, sweepAngle);

      // 2. Pomidor sousi (Sauce base)
      _drawSauce(canvas, sliceCenter, radius * 0.88, startAngle, sweepAngle);

      // 3. Pishloq (Melted Mozzarella)
      _drawCheese(canvas, sliceCenter, radius * 0.84, startAngle, sweepAngle);

      // 4. Pepperoni va Toppinglar
      _drawToppings(canvas, sliceCenter, radius * 0.80, midAngle, startAngle, sweepAngle, i);

      canvas.restore();
    }
  }

  /// Bo'lakning 0.0 -> 1.0 -> 0.0 animatsiya qiymatini hisoblash
  double _calculateSliceOffset(int index, int totalSlices, double t) {
    // Har bir bo'lak uchun faol vaqt oralig'i (overlap bilan)
    final sliceDuration = 1.0 / totalSlices;
    final sliceStart = (index * sliceDuration) % 1.0;

    // Normalizatsiya qilingan vaqt
    double localT = (t - sliceStart);
    if (localT < 0) localT += 1.0;

    // Har bir bo'lak faqat o'z navbatida 1.3 barobar davomida animatsiya qiladi
    final activeRange = sliceDuration * 1.3;
    if (localT > activeRange) return 0.0;

    final progressInSlice = localT / activeRange;
    // Sinus to'lqini bo'yicha silliq: 0 -> 1 -> 0
    return math.sin(progressInSlice * math.pi);
  }

  /// Bo'lak yoyi (wedge sector)
  Path _createSlicePath(
    Offset center,
    double radius,
    double startAngle,
    double sweepAngle,
  ) {
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

  /// Qobiq (Oltin-jigarrang pishgan qobiq)
  void _drawCrust(
    Canvas canvas,
    Offset center,
    double radius,
    double startAngle,
    double sweepAngle,
  ) {
    final crustPaint = Paint()
      ..shader = RadialGradient(
        colors: const [
          Color(0xFFE59838),
          Color(0xFFD6791E),
          Color(0xFFB55D10),
        ],
        stops: const [0.7, 0.9, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    final path = _createSlicePath(center, radius, startAngle, sweepAngle);
    canvas.drawPath(path, crustPaint);
  }

  /// Pomidor sousi
  void _drawSauce(
    Canvas canvas,
    Offset center,
    double radius,
    double startAngle,
    double sweepAngle,
  ) {
    final saucePaint = Paint()..color = const Color(0xFFD32F2F);
    final path = _createSlicePath(center, radius, startAngle, sweepAngle);
    canvas.drawPath(path, saucePaint);
  }

  /// Mozzarella pishlog'i
  void _drawCheese(
    Canvas canvas,
    Offset center,
    double radius,
    double startAngle,
    double sweepAngle,
  ) {
    final cheesePaint = Paint()
      ..shader = RadialGradient(
        colors: const [
          Color(0xFFFFEE58),
          Color(0xFFFFCA28),
          Color(0xFFFFA000),
        ],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    final path = _createSlicePath(center, radius, startAngle, sweepAngle);
    canvas.drawPath(path, cheesePaint);
  }

  /// Pepperoni va bezaklar
  void _drawToppings(
    Canvas canvas,
    Offset center,
    double innerRadius,
    double midAngle,
    double startAngle,
    double sweepAngle,
    int sliceIndex,
  ) {
    // 1. Katta Pepperoni (markazga yaqinroq)
    final r1 = innerRadius * 0.58;
    final p1Angle = midAngle - 0.04;
    final p1 = Offset(
      center.dx + math.cos(p1Angle) * r1,
      center.dy + math.sin(p1Angle) * r1,
    );
    _drawPepperoni(canvas, p1, innerRadius * 0.17);

    // 2. Kichikroq Pepperoni (chetga yaqinroq)
    final r2 = innerRadius * 0.82;
    final p2Angle = midAngle + 0.08;
    final p2 = Offset(
      center.dx + math.cos(p2Angle) * r2,
      center.dy + math.sin(p2Angle) * r2,
    );
    _drawPepperoni(canvas, p2, innerRadius * 0.13);

    // 3. Yashil ko'kat / rayhon bargchasi
    final rHerb = innerRadius * 0.38;
    final herbAngle = midAngle + 0.12;
    final pHerb = Offset(
      center.dx + math.cos(herbAngle) * rHerb,
      center.dy + math.sin(herbAngle) * rHerb,
    );
    _drawHerb(canvas, pHerb, innerRadius * 0.07, midAngle);

    // 4. Qora zaytun halqasi (boshqa bo'laklarda tartib bilan)
    if (sliceIndex % 2 == 0) {
      final rOlive = innerRadius * 0.76;
      final oliveAngle = midAngle - 0.10;
      final pOlive = Offset(
        center.dx + math.cos(oliveAngle) * rOlive,
        center.dy + math.sin(oliveAngle) * rOlive,
      );
      _drawOlive(canvas, pOlive, innerRadius * 0.08);
    }
  }

  void _drawPepperoni(Canvas canvas, Offset center, double radius) {
    // Asosiy qizil aylana
    final pepPaint = Paint()
      ..color = const Color(0xFFC62828)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, pepPaint);

    // Cheti to'q qizil qovurilgan aylana
    final borderPaint = Paint()
      ..color = const Color(0xFF8E0000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, radius, borderPaint);

    // Ichidagi mayda yog'/ziravor nuqtalari
    final dotPaint = Paint()..color = const Color(0xFFFFCDD2);
    canvas.drawCircle(center.translate(-radius * 0.35, -radius * 0.2), radius * 0.18, dotPaint);
    canvas.drawCircle(center.translate(radius * 0.25, radius * 0.3), radius * 0.14, dotPaint);
  }

  void _drawHerb(Canvas canvas, Offset center, double radius, double rotation) {
    final herbPaint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    final path = Path()
      ..moveTo(0, -radius)
      ..quadraticBezierTo(radius * 0.8, 0, 0, radius)
      ..quadraticBezierTo(-radius * 0.8, 0, 0, -radius);
    canvas.drawPath(path, herbPaint);
    canvas.restore();
  }

  void _drawOlive(Canvas canvas, Offset center, double radius) {
    final olivePaint = Paint()
      ..color = const Color(0xFF212121)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.45;
    canvas.drawCircle(center, radius * 0.75, olivePaint);
  }

  @override
  bool shouldRepaint(covariant _PizzaPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.sliceCount != sliceCount;
  }
}

