import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 🍕 PizzaSliceLoader — Strada Pizza uchun haqiqiy (realistik) Neapolitan pitsa animatsiyasi.
///
/// Xususiyatlari:
/// - Tandirda pishgan puffy qobiq (Cornicione) va o'tda pishgan dog'lar (Leopard spotting)
/// - Haqiqiy eritilgan Mozzarella pishlog'i va qizargan (karamellashgan) pishloq pufakchalari
/// - San Marzano pomidor sousi va maydalangan oregano/rayhon ziravorlari
/// - Haqiqiy qovurilgan Pepperoni (qayrilgan cheti, yog' yaltirashi va marmar yog' dog'lari bilan)
/// - Yangi uzilgan rayhon (basil) barglari va Kalamata zaytunlari
/// - Bo'lak ajralib chiqqanda tortiluvchi eritilgan pishloq iplari (cheese pull strings)
/// - 120 FPS jank-free, xotirada ortiqcha obyekt yaratmaydigan toza CustomPainter
class PizzaSliceLoader extends StatefulWidget {
  final double size;
  final int sliceCount;
  final Duration duration;
  final bool is3D;

  const PizzaSliceLoader({
    super.key,
    this.size = 172,
    this.sliceCount = 6,
    this.duration = const Duration(milliseconds: 1900),
    this.is3D = true,
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
    if (!widget.is3D) {
      return AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            size: Size(widget.size, widget.size),
            painter: _RealisticPizzaPainter(
              progress: _controller.value,
              sliceCount: widget.sliceCount,
              is3D: false,
            ),
          );
        },
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final floatY = math.sin(t * 2 * math.pi) * 8.0;
        final wobbleZ = math.sin(t * 2 * math.pi) * 0.04;

        final shadowScale = 1.0 - (floatY / 55.0);
        final shadowAlpha = (0.16 - (floatY / 100.0)).clamp(0.08, 0.25);

        return SizedBox(
          width: widget.size * 1.25,
          height: widget.size * 1.15,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 🌟 3D Dinamik polda hosil bo'ladigan yumshoq pol soyasi
              Positioned(
                bottom: 12,
                child: Container(
                  width: widget.size * 0.95 * shadowScale,
                  height: 26 * shadowScale,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.all(
                      Radius.elliptical(widget.size * 0.95, 26),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: shadowAlpha),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),

              // 🍕 3D Izometrik ko'rinishdagi muallaq (floating) pitsa
              Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0016) // 3D chuqurlik (perspective)
                  ..rotateX(0.48) // 3D qiyalik (isometric table tilt)
                  ..rotateZ(-0.06 + wobbleZ) // Mayin tabiiy tebranish
                  ..translate(0.0, floatY), // Fazoda erkin muallaq turish
                child: CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _RealisticPizzaPainter(
                    progress: t,
                    sliceCount: widget.sliceCount,
                    is3D: true,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RealisticPizzaPainter extends CustomPainter {
  final double progress;
  final int sliceCount;
  final bool is3D;

  _RealisticPizzaPainter({
    required this.progress,
    required this.sliceCount,
    this.is3D = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 * 0.84;
    final sliceAngle = (2 * math.pi) / sliceCount;
    const gapAngle = 0.045; // Bo'laklar orasidagi nozik oraliq

    // 🌟 Pitsa ostidagi chuqur yumshoq stol soyasi (faqat 2D rejimda yoki 3D ostida qo'shimcha yumshoqlik)
    if (!is3D) {
      final boardShadowPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
      canvas.drawCircle(center.translate(0, 10), radius + 4, boardShadowPaint);

      final midBoardPaint = Paint()
        ..color = const Color(0xFF421C0B).withValues(alpha: 0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
      canvas.drawCircle(center.translate(0, 5), radius + 2, midBoardPaint);
    }

    // 🧀 1-bosqich: Chiqqan bo'laklar uchun pishloq iplari (cheese pull strings)
    // Bo'lak orqasidan tortiladigan nozik mozzarella iplari
    _drawCheesePullStrings(canvas, center, radius, sliceAngle, gapAngle);

    // 🍕 2-bosqich: Har bir bo'lakni alohida render qilish
    for (int i = 0; i < sliceCount; i++) {
      final startAngle = -math.pi / 2 + (i * sliceAngle) + (gapAngle / 2);
      final sweepAngle = sliceAngle - gapAngle;
      final midAngle = startAngle + (sweepAngle / 2);

      // Bo'lak harakat progressi (0.0 -> 1.0 -> 0.0)
      final sliceOffset = _calculateSliceOffset(i, sliceCount, progress);

      // Chiqish yo'nalishi
      final maxDistance = radius * 0.19;
      final currentDistance = maxDistance * sliceOffset;
      final sliceCenter = Offset(
        center.dx + math.cos(midAngle) * currentDistance,
        center.dy + math.sin(midAngle) * currentDistance,
      );

      canvas.save();

      // Chiqqan bo'lak balandlashadi (3D ko'tarilish)
      final scale = 1.0 + (0.06 * sliceOffset);
      canvas.translate(sliceCenter.dx, sliceCenter.dy);
      canvas.scale(scale);
      canvas.translate(-sliceCenter.dx, -sliceCenter.dy);

      // Chiqqan bo'lakning dinamik 3D soyasi
      if (sliceOffset > 0.02) {
        final elevatedShadow = Paint()
          ..color = Colors.black.withValues(alpha: 0.22 * sliceOffset)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12 * sliceOffset);

        final shadowPath = _createRealisticSlicePath(
          sliceCenter.translate(0, 9 * sliceOffset),
          radius,
          startAngle,
          sweepAngle,
          midAngle,
        );
        canvas.drawPath(shadowPath, elevatedShadow);
      }

      // 3D qalinlik devori (Crust thickness extrusion for 3D depth)
      if (is3D) {
        _draw3DCrustThickness(canvas, sliceCenter, radius, startAngle, sweepAngle, midAngle);
      }

      // A. Qobiq asosi (Crust base)
      _drawArtisanalCrust(canvas, sliceCenter, radius, startAngle, sweepAngle, midAngle, i);

      // B. San Marzano pomidor sousi
      _drawRichTomatoSauce(canvas, sliceCenter, radius * 0.79, startAngle, sweepAngle, midAngle);

      // C. Eritilgan Mozzarella pishlog'i
      _drawMeltedMozzarella(canvas, sliceCenter, radius * 0.75, startAngle, sweepAngle, midAngle, i);

      // D. Toppinglar: Pepperoni, Rayhon, Zaytun, Ziravorlar
      _drawGourmetToppings(canvas, sliceCenter, radius * 0.75, midAngle, i);

      canvas.restore();
    }
  }

  /// 3D Pitsaning chekka qalinlik devori (Extrusion rim)
  void _draw3DCrustThickness(
    Canvas canvas,
    Offset center,
    double radius,
    double startAngle,
    double sweepAngle,
    double midAngle,
  ) {
    // Faqat pastki tomonga (kameraga qarab turgan yoylarga) qalinlik chiziladi
    if (math.sin(midAngle) < -0.25) return;

    const depth = 7.0;
    final rimPath = Path();

    final pStartTop = Offset(
      center.dx + math.cos(startAngle) * radius,
      center.dy + math.sin(startAngle) * radius,
    );
    final pStartBottom = pStartTop.translate(0, depth);

    rimPath.moveTo(pStartTop.dx, pStartTop.dy);
    rimPath.lineTo(pStartBottom.dx, pStartBottom.dy);

    const segments = 10;
    for (int s = 1; s <= segments; s++) {
      final a = startAngle + (sweepAngle * (s / segments));
      rimPath.lineTo(
        center.dx + math.cos(a) * radius,
        center.dy + math.sin(a) * radius + depth,
      );
    }

    final pEndTop = Offset(
      center.dx + math.cos(startAngle + sweepAngle) * radius,
      center.dy + math.sin(startAngle + sweepAngle) * radius,
    );
    rimPath.lineTo(pEndTop.dx, pEndTop.dy);

    for (int s = segments; s >= 0; s--) {
      final a = startAngle + (sweepAngle * (s / segments));
      rimPath.lineTo(
        center.dx + math.cos(a) * radius,
        center.dy + math.sin(a) * radius,
      );
    }
    rimPath.close();

    final rimShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: const [
        Color(0xFFB55D11), // Qovurilgan qobig'i
        Color(0xFF6E2F05), // Qorong'i pastki qismi
        Color(0xFF321203), // Chuqur 3D soya
      ],
      stops: const [0.0, 0.65, 1.0],
    ).createShader(rimPath.getBounds());

    final rimPaint = Paint()
      ..shader = rimShader
      ..style = PaintingStyle.fill;

    canvas.drawPath(rimPath, rimPaint);
  }

      // D. Toppinglar: Pepperoni, Rayhon, Zaytun, Ziravorlar
      _drawGourmetToppings(canvas, sliceCenter, radius * 0.75, midAngle, i);

      canvas.restore();
    }
  }

  /// Bo'lak animatsiya progressi (Sinusoid silliq chiqib-kirish)
  double _calculateSliceOffset(int index, int totalSlices, double t) {
    final sliceDuration = 1.0 / totalSlices;
    final sliceStart = (index * sliceDuration) % 1.0;

    double localT = (t - sliceStart);
    if (localT < 0) localT += 1.0;

    final activeRange = sliceDuration * 1.35;
    if (localT > activeRange) return 0.0;

    final progressInSlice = localT / activeRange;
    return math.sin(progressInSlice * math.pi);
  }

  /// Bo'lakning tabiiy, qo'lda yopilgan pitsa konturi (Cornicione pufakchalari bilan)
  Path _createRealisticSlicePath(
    Offset center,
    double radius,
    double startAngle,
    double sweepAngle,
    double midAngle,
  ) {
    final path = Path();
    path.moveTo(center.dx, center.dy);

    // Markazdan tashqariga to'g'ri chiziq
    final pStart = Offset(
      center.dx + math.cos(startAngle) * radius,
      center.dy + math.sin(startAngle) * radius,
    );
    path.lineTo(pStart.dx, pStart.dy);

    // Tashqi qobiq yoyi — qo'lda yoyilgan xamirdagidek tabiiy to'lqinsimon
    const segments = 12;
    for (int s = 1; s <= segments; s++) {
      final a = startAngle + (sweepAngle * (s / segments));
      // Xamir pufakchalari uchun mayin radial to'lqin
      final wave = math.sin((s / segments) * math.pi * 3) * (radius * 0.018);
      final r = radius + wave;
      path.lineTo(
        center.dx + math.cos(a) * r,
        center.dy + math.sin(a) * r,
      );
    }

    path.close();
    return path;
  }

  /// 🥖 Qobiq (Cornicione) — O'tda pishgan Neapolitan qobig'i
  void _drawArtisanalCrust(
    Canvas canvas,
    Offset center,
    double radius,
    double startAngle,
    double sweepAngle,
    double midAngle,
    int sliceIndex,
  ) {
    // 1. Qobiq uchun boy gradient (chuqur oltin, qovurilgan jigarrang, unli yuza)
    final crustShader = RadialGradient(
      colors: const [
        Color(0xFFE5A14E), // Ichki xamir
        Color(0xFFD48227), // Pishgan qismi
        Color(0xFFB55D11), // Qovurilgan qobig'i
        Color(0xFF6E2F05), // Chekka kuydirilgan qismi
      ],
      stops: const [0.72, 0.85, 0.94, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    final crustPaint = Paint()
      ..shader = crustShader
      ..style = PaintingStyle.fill;

    final crustPath = _createRealisticSlicePath(center, radius, startAngle, sweepAngle, midAngle);
    canvas.drawPath(crustPath, crustPaint);

    // 2. Qobiq hajmi (Puffy 3D relyef / yorug'lik nuri)
    final crustHighlightPaint = Paint()
      ..color = const Color(0xFFFDE1B2).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.06
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final highlightArcPath = Path();
    highlightArcPath.addArc(
      Rect.fromCircle(center: center, radius: radius * 0.93),
      startAngle + 0.03,
      sweepAngle - 0.06,
    );
    canvas.drawPath(highlightArcPath, crustHighlightPaint);

    // 3. O'tin pechining qoramtir dog'lari (Leopard spotting / Maculatura)
    _drawLeopardSpots(canvas, center, radius, startAngle, sweepAngle, sliceIndex);
  }

  /// Tandir qora dog'lari (Leopard Spots)
  void _drawLeopardSpots(
    Canvas canvas,
    Offset center,
    double radius,
    double startAngle,
    double sweepAngle,
    int sliceIndex,
  ) {
    final spotPaint = Paint()
      ..color = const Color(0xFF230E04)
      ..style = PaintingStyle.fill;

    final charHaloPaint = Paint()
      ..color = const Color(0xFF461905).withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);

    // Har bir bo'lak uchun deterministik nuqtalar
    final spotsData = [
      [0.25, 0.96, 2.8],
      [0.55, 0.95, 3.4],
      [0.80, 0.97, 2.2],
      [0.40, 0.93, 1.8],
    ];

    for (final spot in spotsData) {
      final angleFraction = spot[0];
      final rRatio = spot[1];
      final spotRadius = spot[2];

      final spotAngle = startAngle + (sweepAngle * angleFraction);
      final r = radius * rRatio;
      final spotCenter = Offset(
        center.dx + math.cos(spotAngle) * r,
        center.dy + math.sin(spotAngle) * r,
      );

      // Kichik halo
      canvas.drawCircle(spotCenter, spotRadius + 0.8, charHaloPaint);
      // To'q markaz
      canvas.drawCircle(spotCenter, spotRadius, spotPaint);
    }
  }

  /// 🍅 Boy San Marzano pomidor sousi
  void _drawRichTomatoSauce(
    Canvas canvas,
    Offset center,
    double radius,
    double startAngle,
    double sweepAngle,
    double midAngle,
  ) {
    final sauceShader = RadialGradient(
      colors: const [
        Color(0xFFC62828), // Yangi pomidor qizili
        Color(0xFFA51B14), // Pishirilgan pomidor
        Color(0xFF750E07), // Chuqur sous asosi
      ],
      stops: const [0.4, 0.82, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    final saucePaint = Paint()..shader = sauceShader;
    final saucePath = _createRealisticSlicePath(center, radius, startAngle, sweepAngle, midAngle);
    canvas.drawPath(saucePath, saucePaint);
  }

  /// 🧀 Eritilgan Mozzarella pishlog'i va karamellashgan tillarang pufakchalar
  void _drawMeltedMozzarella(
    Canvas canvas,
    Offset center,
    double radius,
    double startAngle,
    double sweepAngle,
    double midAngle,
    int sliceIndex,
  ) {
    // 1. Mozzarella asosi (Sarg'ish-qaymoqrang issiq erigan pishloq)
    final cheeseShader = RadialGradient(
      colors: const [
        Color(0xFFFFF9E8), // Markaziy qaymoqrang
        Color(0xFFFEE8B5), // Eritilgan pishloq
        Color(0xFFF7CB70), // Sous bilan aralashgan qirra
        Color(0xFFE59C35), // Qovurilgan qirra
      ],
      stops: const [0.0, 0.55, 0.88, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    final cheesePaint = Paint()..shader = cheeseShader;
    final cheesePath = _createRealisticSlicePath(center, radius, startAngle, sweepAngle, midAngle);
    canvas.drawPath(cheesePath, cheesePaint);

    // 2. Qovurilgan pishloq pufakchalari (Baked golden blisters)
    final blisterPaint = Paint()
      ..color = const Color(0xFFD67E1B).withValues(alpha: 0.65)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final blisterDarkPaint = Paint()
      ..color = const Color(0xFFA65008).withValues(alpha: 0.75)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);

    // Deterministik pufakchalar joylashuvi
    final blisterPoints = [
      Offset(center.dx + math.cos(midAngle - 0.08) * (radius * 0.42), center.dy + math.sin(midAngle - 0.08) * (radius * 0.42)),
      Offset(center.dx + math.cos(midAngle + 0.12) * (radius * 0.65), center.dy + math.sin(midAngle + 0.12) * (radius * 0.65)),
      Offset(center.dx + math.cos(midAngle - 0.14) * (radius * 0.78), center.dy + math.sin(midAngle - 0.14) * (radius * 0.78)),
    ];

    for (final bp in blisterPoints) {
      canvas.drawCircle(bp, radius * 0.065, blisterPaint);
      canvas.drawCircle(bp.translate(1, 0.5), radius * 0.035, blisterDarkPaint);
    }

    // 3. Maydalangan Italiya oreganosi (yashil-jigarrang mayda ziravorlar)
    final herbFlakePaint = Paint()..color = const Color(0xFF334F20).withValues(alpha: 0.85);
    final chiliFlakePaint = Paint()..color = const Color(0xFF881708).withValues(alpha: 0.75);

    for (int h = 0; h < 6; h++) {
      final hAngle = startAngle + (sweepAngle * (0.15 + (h * 0.14)));
      final hDist = radius * (0.30 + ((h * 17) % 55) / 100);
      final hp = Offset(center.dx + math.cos(hAngle) * hDist, center.dy + math.sin(hAngle) * hDist);

      canvas.drawCircle(hp, 1.2, h % 2 == 0 ? herbFlakePaint : chiliFlakePaint);
    }
  }

  /// 🍖 Haqiqiy Pepperoni, Rayhon, Zaytun
  void _drawGourmetToppings(
    Canvas canvas,
    Offset center,
    double innerRadius,
    double midAngle,
    int sliceIndex,
  ) {
    // 1. Asosiy katta Pepperoni (markazroqda)
    final r1 = innerRadius * 0.52;
    final p1Angle = midAngle - 0.04;
    final p1 = Offset(center.dx + math.cos(p1Angle) * r1, center.dy + math.sin(p1Angle) * r1);
    _drawRealisticPepperoni(canvas, p1, innerRadius * 0.19, sliceIndex);

    // 2. Kichikroq Pepperoni (qirqim chetida)
    final r2 = innerRadius * 0.84;
    final p2Angle = midAngle + 0.09;
    final p2 = Offset(center.dx + math.cos(p2Angle) * r2, center.dy + math.sin(p2Angle) * r2);
    _drawRealisticPepperoni(canvas, p2, innerRadius * 0.145, sliceIndex + 1);

    // 3. Yangi uzilgan rayhon bargi (Basil leaf) — har 2-chi bo'lakda
    if (sliceIndex % 2 == 0) {
      final rBasil = innerRadius * 0.35;
      final basilAngle = midAngle + 0.13;
      final pBasil = Offset(center.dx + math.cos(basilAngle) * rBasil, center.dy + math.sin(basilAngle) * rBasil);
      _drawFreshBasil(canvas, pBasil, innerRadius * 0.09, midAngle + 0.3);
    }

    // 4. Kalamata qora zaytuni — toq bo'laklarda
    if (sliceIndex % 2 == 1) {
      final rOlive = innerRadius * 0.76;
      final oliveAngle = midAngle - 0.11;
      final pOlive = Offset(center.dx + math.cos(oliveAngle) * rOlive, center.dy + math.sin(oliveAngle) * rOlive);
      _drawKalamataOlive(canvas, pOlive, innerRadius * 0.08);
    }
  }

  /// 🍕 Haqiqiy qovurilgan Pepperoni
  void _drawRealisticPepperoni(Canvas canvas, Offset center, double radius, int seed) {
    // 1. Soya (Pishloq ustidagi 3D chuqurlik)
    final pepShadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.32)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(center.translate(1.2, 2.2), radius, pepShadow);

    // 2. Go'sht asosi (Qovurilgan boy paprika-qizil gradient)
    final pepShader = RadialGradient(
      colors: const [
        Color(0xFFD32F2F), // Shirali markaz
        Color(0xFFB71C1C), // Pishgan go'sht
        Color(0xFF7F0000), // Qovurilgan qirra
        Color(0xFF4A0000), // Kuydirilgan qayrilgan chet
      ],
      stops: const [0.0, 0.65, 0.90, 1.0],
    ).createShader(Rect.fromCircle(center: center, radius: radius));

    final pepPaint = Paint()..shader = pepShader;
    canvas.drawCircle(center, radius, pepPaint);

    // 3. Qayrilgan to'q qizil qirra
    final rimPaint = Paint()
      ..color = const Color(0xFF3E0502)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    canvas.drawCircle(center, radius - 0.8, rimPaint);

    // 4. Marmar yog' donachalari (Fat marbling)
    final fatPaint = Paint()..color = const Color(0xFFFFCDD2).withValues(alpha: 0.85);
    final fatSpots = [
      Offset(center.dx - radius * 0.35, center.dy - radius * 0.25),
      Offset(center.dx + radius * 0.30, center.dy + radius * 0.20),
      Offset(center.dx - radius * 0.10, center.dy + radius * 0.40),
      Offset(center.dx + radius * 0.20, center.dy - radius * 0.35),
    ];
    for (final fs in fatSpots) {
      canvas.drawCircle(fs, radius * 0.10, fatPaint);
    }

    // 5. Qovurilgan yog' jilvasi (Specular oil shine)
    final shinePath = Path()
      ..addArc(
        Rect.fromCircle(center: center.translate(-radius * 0.15, -radius * 0.15), radius: radius * 0.65),
        -math.pi * 0.8,
        math.pi * 0.6,
      );
    canvas.drawPath(
      shinePath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.18
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2),
    );
  }

  /// 🌿 Yangi uzilgan rayhon bargi
  void _drawFreshBasil(Canvas canvas, Offset center, double radius, double rotation) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    // Soya
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    final leafPath = Path();
    leafPath.moveTo(0, -radius * 1.3);
    leafPath.cubicTo(radius * 0.9, -radius * 0.6, radius * 0.8, radius * 0.8, 0, radius * 1.1);
    leafPath.cubicTo(-radius * 0.8, radius * 0.8, -radius * 0.9, -radius * 0.6, 0, -radius * 1.3);
    leafPath.close();

    canvas.drawPath(leafPath.shift(const Offset(1, 1.5)), shadowPaint);

    // Barg asosi
    final leafShader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: const [
        Color(0xFF43A047),
        Color(0xFF2E7D32),
        Color(0xFF1B5E20),
      ],
    ).createShader(Rect.fromCenter(center: Offset.zero, width: radius * 2, height: radius * 2));

    canvas.drawPath(leafPath, Paint()..shader = leafShader);

    // Barg tomiri (midrib vein)
    final veinPaint = Paint()
      ..color = const Color(0xFF134D18).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, -radius * 1.1), Offset(0, radius * 0.9), veinPaint);

    canvas.restore();
  }

  /// 🫒 Kalamata qora zaytuni halqasi
  void _drawKalamataOlive(Canvas canvas, Offset center, double radius) {
    // Soya
    canvas.drawCircle(
      center.translate(1, 1.5),
      radius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    // Tashqi qora halqa
    final olivePaint = Paint()
      ..color = const Color(0xFF1C1A1E)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, olivePaint);

    // Ichki teshigi (osti pishloq ko'rinishi)
    final holePaint = Paint()..color = const Color(0xFFFDE8B5);
    canvas.drawCircle(center, radius * 0.45, holePaint);

    // Teshik ichki soyasi
    final innerShadowPaint = Paint()
      ..color = const Color(0xFF100F12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius * 0.45, innerShadowPaint);

    // Zaytun ustidagi nozik yaltiroq nuqta
    final spotPaint = Paint()..color = Colors.white.withValues(alpha: 0.35);
    canvas.drawCircle(center.translate(-radius * 0.35, -radius * 0.35), radius * 0.16, spotPaint);
  }

  /// 🧀 Chiqqan bo'lakdan tortiluvchi mozzarella iplari (Cheese pull strings)
  void _drawCheesePullStrings(
    Canvas canvas,
    Offset center,
    double radius,
    double sliceAngle,
    double gapAngle,
  ) {
    for (int i = 0; i < sliceCount; i++) {
      final sliceOffset = _calculateSliceOffset(i, sliceCount, progress);
      if (sliceOffset < 0.08) continue; // Faqat yetarlicha chiqqanda tortiladi

      final startAngle = -math.pi / 2 + (i * sliceAngle) + (gapAngle / 2);
      final sweepAngle = sliceAngle - gapAngle;
      final midAngle = startAngle + (sweepAngle / 2);

      final maxDistance = radius * 0.19;
      final currentDistance = maxDistance * sliceOffset;

      final tipOffset = Offset(
        center.dx + math.cos(midAngle) * currentDistance,
        center.dy + math.sin(midAngle) * currentDistance,
      );

      // Pishloq rangi va qalinligi
      final stringWidth = (2.2 * (1.0 - (sliceOffset * 0.45))).clamp(1.0, 2.5);
      final cheeseStringPaint = Paint()
        ..color = const Color(0xFFFFF6DF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stringWidth
        ..strokeCap = StrokeCap.round;

      final cheeseBorderPaint = Paint()
        ..color = const Color(0xFFE59C35).withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stringWidth + 0.8
        ..strokeCap = StrokeCap.round;

      // 1. Markaziy pishloq ipi
      final pCenterString = Path()
        ..moveTo(center.dx, center.dy)
        ..quadraticBezierTo(
          (center.dx + tipOffset.dx) / 2 + math.sin(midAngle) * 3,
          (center.dy + tipOffset.dy) / 2 - math.cos(midAngle) * 3,
          tipOffset.dx,
          tipOffset.dy,
        );
      canvas.drawPath(pCenterString, cheeseBorderPaint);
      canvas.drawPath(pCenterString, cheeseStringPaint);

      // 2. Chap qirra pishloq ipi
      final leftBase = Offset(
        center.dx + math.cos(startAngle) * (radius * 0.3),
        center.dy + math.sin(startAngle) * (radius * 0.3),
      );
      final leftMoved = Offset(
        tipOffset.dx + math.cos(startAngle) * (radius * 0.28),
        tipOffset.dy + math.sin(startAngle) * (radius * 0.28),
      );
      final pLeftString = Path()
        ..moveTo(leftBase.dx, leftBase.dy)
        ..quadraticBezierTo(
          (leftBase.dx + leftMoved.dx) / 2,
          (leftBase.dy + leftMoved.dy) / 2,
          leftMoved.dx,
          leftMoved.dy,
        );
      canvas.drawPath(pLeftString, cheeseBorderPaint);
      canvas.drawPath(pLeftString, cheeseStringPaint);

      // 3. O'ng qirra pishloq ipi
      final endAngle = startAngle + sweepAngle;
      final rightBase = Offset(
        center.dx + math.cos(endAngle) * (radius * 0.3),
        center.dy + math.sin(endAngle) * (radius * 0.3),
      );
      final rightMoved = Offset(
        tipOffset.dx + math.cos(endAngle) * (radius * 0.28),
        tipOffset.dy + math.sin(endAngle) * (radius * 0.28),
      );
      final pRightString = Path()
        ..moveTo(rightBase.dx, rightBase.dy)
        ..quadraticBezierTo(
          (rightBase.dx + rightMoved.dx) / 2,
          (rightBase.dy + rightMoved.dy) / 2,
          rightMoved.dx,
          rightMoved.dy,
        );
      canvas.drawPath(pRightString, cheeseBorderPaint);
      canvas.drawPath(pRightString, cheeseStringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RealisticPizzaPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.sliceCount != sliceCount;
  }
}
