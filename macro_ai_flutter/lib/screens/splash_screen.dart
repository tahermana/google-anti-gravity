import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'welcome_screen.dart';

// ── Macro AI Splash Screen ────────────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Master timeline — 2 400 ms total
  late AnimationController _master;

  // Individual animated values
  late Animation<double> _flashOpacity;       // 0→0.6→0   (0–80ms)
  late Animation<double> _scanPos;            // top=-2→102%  (80–780ms)
  late Animation<double> _wheelEntry;         // scale+rot  (200–1100ms)
  late Animation<double> _outerRing;          // dashoffset draw (400–1100ms)
  late Animation<double> _innerRing;          // dashoffset draw (500–1000ms)
  late Animation<double> _wedgeScale;         // wedges pop  (700–1000ms)
  late Animation<double> _centerCircle;       // center pop  (950–1350ms)
  late Animation<double> _centerSym;          // center symbol (1150–1450ms)
  late Animation<double> _brandReveal;        // clip wipe   (900–1600ms)
  late Animation<double> _taglineOpacity;     // fade+slide  (1300–1800ms)
  late Animation<double> _taglineSlide;
  late Animation<double> _ruleWidth;          // rule line   (1500–2300ms)
  late Animation<double> _bracketsOpacity;    // brackets    (1600–1900ms)

  // Particle animation
  late AnimationController _particles;

  static const int _totalMs = 2400;

  Interval _i(int startMs, int endMs) =>
      Interval(startMs / _totalMs, endMs / _totalMs);

  @override
  void initState() {
    super.initState();

    _master = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _totalMs),
    );

    _particles = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Flash
    _flashOpacity = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.6), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.6, end: 0.0), weight: 3),
    ]).animate(CurvedAnimation(parent: _master, curve: _i(0, 200)));

    // Scan line: 0→1 (maps to -2px→screen height+2)
    _scanPos = CurvedAnimation(
      parent: _master,
      curve: _i(80, 780),
    );

    // Wheel entry: rotates from -π/2 to 0, scales 0.6→1
    _wheelEntry = CurvedAnimation(
      parent: _master,
      curve: const Interval(200 / _totalMs, 1100 / _totalMs,
          curve: Curves.elasticOut),
    );

    // Outer ring draw (dashoffset 553→0)
    _outerRing = CurvedAnimation(
      parent: _master,
      curve: const Interval(400 / _totalMs, 1100 / _totalMs,
          curve: Cubic(0.22, 1, 0.36, 1)),
    );

    // Inner ring draw (dashoffset 478→0)
    _innerRing = CurvedAnimation(
      parent: _master,
      curve: const Interval(500 / _totalMs, 1000 / _totalMs,
          curve: Cubic(0.22, 1, 0.36, 1)),
    );

    // Wedges scale
    _wedgeScale = CurvedAnimation(
      parent: _master,
      curve: const Interval(700 / _totalMs, 1050 / _totalMs,
          curve: Curves.elasticOut),
    );

    // Center circle
    _centerCircle = CurvedAnimation(
      parent: _master,
      curve: const Interval(950 / _totalMs, 1350 / _totalMs,
          curve: Curves.elasticOut),
    );

    // Center symbol
    _centerSym = CurvedAnimation(
      parent: _master,
      curve: const Interval(1150 / _totalMs, 1450 / _totalMs,
          curve: Curves.easeOut),
    );

    // Brand reveal (clip)
    _brandReveal = CurvedAnimation(
      parent: _master,
      curve: const Interval(900 / _totalMs, 1600 / _totalMs,
          curve: Cubic(0.22, 1, 0.36, 1)),
    );

    // Tagline
    _taglineOpacity = CurvedAnimation(
      parent: _master,
      curve: const Interval(1300 / _totalMs, 1800 / _totalMs, curve: Curves.easeOut),
    );
    _taglineSlide = CurvedAnimation(
      parent: _master,
      curve: const Interval(1300 / _totalMs, 1800 / _totalMs,
          curve: Cubic(0.22, 1, 0.36, 1)),
    );

    // Rule line
    _ruleWidth = CurvedAnimation(
      parent: _master,
      curve: const Interval(1500 / _totalMs, 2300 / _totalMs,
          curve: Cubic(0.22, 1, 0.36, 1)),
    );

    // Brackets
    _bracketsOpacity = CurvedAnimation(
      parent: _master,
      curve: const Interval(1600 / _totalMs, 1900 / _totalMs, curve: Curves.easeOut),
    );

    _master.forward();

    // Navigate after animation
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const WelcomeScreen(),
            transitionsBuilder: (_, a, __, child) =>
                FadeTransition(opacity: a, child: child),
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _master.dispose();
    _particles.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: AnimatedBuilder(
          animation: _master,
          builder: (context, _) {
            return Stack(
              children: [
                // ── Particles ─────────────────────────────────────────────
                AnimatedBuilder(
                  animation: _particles,
                  builder: (_, __) => CustomPaint(
                    size: size,
                    painter: _ParticlePainter(_particles.value),
                  ),
                ),

                // ── Vignette ──────────────────────────────────────────────
                IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.3,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.75),
                        ],
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),
                ),

                // ── Corner Brackets ───────────────────────────────────────
                ..._buildBrackets(_bracketsOpacity.value),

                // ── Scan Line ─────────────────────────────────────────────
                Positioned(
                  left: 0,
                  right: 0,
                  top: -2 + (size.height + 4) * _scanPos.value,
                  child: Container(
                    height: 1,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Color(0x99D42020),
                          Color(0xE6FFFFFF),
                          Color(0x99D42020),
                          Colors.transparent,
                        ],
                        stops: [0.0, 0.3, 0.5, 0.7, 1.0],
                      ),
                    ),
                  ),
                ),

                // ── Main Content ──────────────────────────────────────────
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo row: wheel + text
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Wheel
                          SizedBox(
                            width: 160,
                            height: 160,
                            child: Transform.rotate(
                              angle: (1 - _wheelEntry.value) * (-math.pi / 2),
                              child: Transform.scale(
                                scale: 0.6 + 0.4 * _wheelEntry.value,
                                child: Opacity(
                                  opacity: _wheelEntry.value.clamp(0.0, 1.0),
                                  child: CustomPaint(
                                    size: const Size(160, 160),
                                    painter: _WheelPainter(
                                      outerProgress: _outerRing.value,
                                      innerProgress: _innerRing.value,
                                      wedgeScale: _wedgeScale.value,
                                      centerScale: _centerCircle.value,
                                      centerSymOpacity: _centerSym.value,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 28),

                          // Text column
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Brand — clip wipe reveal
                              ClipRect(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: _brandReveal.value,
                                  child: const Text(
                                    'MACRO AI',
                                    style: TextStyle(
                                      fontSize: 68,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: 4,
                                      height: 0.9,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Tagline
                              Opacity(
                                opacity: _taglineOpacity.value,
                                child: Transform.translate(
                                  offset: Offset(
                                      0, 10 * (1 - _taglineSlide.value)),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _tagWord('Calculate'),
                                      const SizedBox(width: 8),
                                      _tagDot(),
                                      const SizedBox(width: 8),
                                      _tagWord('Track'),
                                      const SizedBox(width: 8),
                                      _tagDot(),
                                      const SizedBox(width: 8),
                                      _tagWord('Fuel'),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Rule line
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          width: 420 * _ruleWidth.value,
                          height: 1,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFFD42020), Colors.transparent],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Flash overlay ─────────────────────────────────────────
                IgnorePointer(
                  child: Opacity(
                    opacity: _flashOpacity.value,
                    child: Container(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Helper: tag word
  Widget _tagWord(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          letterSpacing: 4,
          color: Color(0xFFAAAAAA),
          fontWeight: FontWeight.w400,
        ),
      );

  // Helper: tag dot
  Widget _tagDot() => Container(
        width: 5,
        height: 5,
        decoration: const BoxDecoration(
          color: Color(0xFFD42020),
          shape: BoxShape.circle,
        ),
      );

  // Helper: corner brackets
  List<Widget> _buildBrackets(double opacity) {
    final o = opacity.clamp(0.0, 1.0);
    final scale = 0.5 + 0.5 * o;
    const size = 22.0;
    const margin = 24.0;
    const color = Color(0xB3D42020);
    const bWidth = 1.5;

    Widget bracket({
      required Alignment alignment,
      required BorderRadius radius,
      required Border border,
    }) =>
        Positioned.fill(
          child: Align(
            alignment: alignment,
            child: Padding(
              padding: const EdgeInsets.all(margin),
              child: Opacity(
                opacity: o,
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(border: border),
                  ),
                ),
              ),
            ),
          ),
        );

    return [
      bracket(
        alignment: Alignment.topLeft,
        radius: BorderRadius.zero,
        border: const Border(
          top: BorderSide(color: color, width: bWidth),
          left: BorderSide(color: color, width: bWidth),
        ),
      ),
      bracket(
        alignment: Alignment.topRight,
        radius: BorderRadius.zero,
        border: const Border(
          top: BorderSide(color: color, width: bWidth),
          right: BorderSide(color: color, width: bWidth),
        ),
      ),
      bracket(
        alignment: Alignment.bottomLeft,
        radius: BorderRadius.zero,
        border: const Border(
          bottom: BorderSide(color: color, width: bWidth),
          left: BorderSide(color: color, width: bWidth),
        ),
      ),
      bracket(
        alignment: Alignment.bottomRight,
        radius: BorderRadius.zero,
        border: const Border(
          bottom: BorderSide(color: color, width: bWidth),
          right: BorderSide(color: color, width: bWidth),
        ),
      ),
    ];
  }
}

// ── Wheel CustomPainter ───────────────────────────────────────────────────────
class _WheelPainter extends CustomPainter {
  final double outerProgress;
  final double innerProgress;
  final double wedgeScale;
  final double centerScale;
  final double centerSymOpacity;

  const _WheelPainter({
    required this.outerProgress,
    required this.innerProgress,
    required this.wedgeScale,
    required this.centerScale,
    required this.centerSymOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 200; // normalised to 200×200 design coords

    canvas.save();
    canvas.scale(scale);

    const center = Offset(100, 100);

    // ── Outer shadow ring ──────────────────────────────────────────────────
    canvas.drawCircle(
      center,
      90,
      Paint()
        ..color = Colors.black.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    // ── Outer red ring (arc sweep) ─────────────────────────────────────────
    const outerRect = Rect.fromLTWH(12, 12, 176, 176); // r=88
    final outerPaint = Paint()
      ..color = const Color(0xFFD42020)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.butt
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    if (outerProgress > 0) {
      canvas.drawArc(
        outerRect,
        -math.pi / 2,
        2 * math.pi * outerProgress,
        false,
        outerPaint,
      );
    }

    // ── White inner border ─────────────────────────────────────────────────
    canvas.drawCircle(
      center,
      83,
      Paint()
        ..color = Colors.white.withOpacity(0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // ── BG fill ───────────────────────────────────────────────────────────
    canvas.drawCircle(
      center,
      78,
      Paint()..color = const Color(0xFF1A1A1A),
    );

    // ── Wedges (clipped to r=76) ───────────────────────────────────────────
    final clipPath = Path()..addOval(const Rect.fromLTWH(24, 24, 152, 152));
    canvas.save();
    canvas.clipPath(clipPath);

    final ws = wedgeScale.clamp(0.0, 1.0);

    if (ws > 0) {
      // Draw wedges with scale from center
      canvas.save();
      canvas.translate(100, 100);
      canvas.scale(ws);
      canvas.translate(-100, -100);

      // Draw each wedge as a sector
      void drawSector(double startDeg, double sweepDeg, Color color) {
        final path = Path();
        path.moveTo(100, 100);
        path.arcTo(
          const Rect.fromLTWH(22, 22, 156, 156),
          startDeg * math.pi / 180,
          sweepDeg * math.pi / 180,
          false,
        );
        path.close();
        canvas.drawPath(path, Paint()..color = color);
      }

      // Teal: -90° to -30° (270 to 330 = -90° for 60°)
      drawSector(-90, 60, const Color(0xFF3BBFBF));
      // Dark top-right: -30° to 30°
      drawSector(-30, 60, const Color(0xFF2A2A2A));
      // Dark right: 30° to 90°
      drawSector(30, 60, const Color(0xFF111111));
      // Yellow bottom: 90° to 270°
      drawSector(90, 180, const Color(0xFFE8B830));
      // Green left: 210° to 270° (going from -150° for 60°)
      drawSector(210, 60, const Color(0xFF3DAB6E));

      // Dividers
      final divPaint = Paint()
        ..color = const Color(0xFF0A0A0A)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;
      final divAngles = [-90.0, -30.0, 30.0, 90.0, 210.0];
      for (final angle in divAngles) {
        final rad = angle * math.pi / 180;
        canvas.drawLine(
          const Offset(100, 100),
          Offset(100 + 78 * math.cos(rad), 100 + 78 * math.sin(rad)),
          divPaint,
        );
      }

      canvas.restore();
    }

    canvas.restore(); // clip

    // ── Inner ring ─────────────────────────────────────────────────────────
    if (innerProgress > 0) {
      canvas.drawArc(
        const Rect.fromLTWH(24, 24, 152, 152), // r=76
        -math.pi / 2,
        2 * math.pi * innerProgress,
        false,
        Paint()
          ..color = Colors.white.withOpacity(0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    // ── Center white circle ────────────────────────────────────────────────
    if (centerScale > 0) {
      canvas.save();
      canvas.translate(100, 100);
      canvas.scale(centerScale.clamp(0.0, 1.5));
      canvas.translate(-100, -100);
      canvas.drawCircle(
        center,
        30,
        Paint()..color = Colors.white,
      );
      canvas.restore();
    }

    // ── Center symbol (Amazigh Yaz — ⵣ shape) ─────────────────────────────
    if (centerSymOpacity > 0) {
      final symPaint = Paint()
        ..color =
            const Color(0xFFD42020).withOpacity(centerSymOpacity.clamp(0.0, 1.0))
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.square
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      // Vertical line
      canvas.drawLine(const Offset(100, 82), const Offset(100, 118), symPaint);
      // Top-left arm
      canvas.drawLine(const Offset(100, 94), const Offset(87, 82), symPaint);
      // Top-right arm
      canvas.drawLine(const Offset(100, 94), const Offset(113, 82), symPaint);
      // Bottom-left arm
      canvas.drawLine(const Offset(100, 106), const Offset(87, 118), symPaint);
      // Bottom-right arm
      canvas.drawLine(const Offset(100, 106), const Offset(113, 118), symPaint);
    }

    // ── Wedge letters ──────────────────────────────────────────────────────
    if (wedgeScale > 0.3) {
      final letOpacity = ((wedgeScale - 0.3) / 0.7).clamp(0.0, 1.0);
      final textStyle = TextStyle(
        color: Colors.white.withOpacity(letOpacity),
        fontSize: 20,
        fontWeight: FontWeight.w900,
        letterSpacing: 1,
      );

      void drawLetter(String letter, Offset pos, {Color? color}) {
        final tp = TextPainter(
          text: TextSpan(
            text: letter,
            style: color != null
                ? textStyle.copyWith(
                    color: color.withOpacity(letOpacity))
                : textStyle,
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(
            canvas, pos - Offset(tp.width / 2, tp.height / 2));
      }

      drawLetter('P', const Offset(73, 55));
      drawLetter('F', const Offset(127, 55));
      drawLetter('C', const Offset(100, 152),
          color: const Color(0xFF1A1A1A));
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_WheelPainter old) =>
      old.outerProgress != outerProgress ||
      old.innerProgress != innerProgress ||
      old.wedgeScale != wedgeScale ||
      old.centerScale != centerScale ||
      old.centerSymOpacity != centerSymOpacity;
}

// ── Particle Background Painter ───────────────────────────────────────────────
class _ParticlePainter extends CustomPainter {
  final double t;
  static final _rng = math.Random(42);
  static final _particles = List.generate(80, (_) {
    return [
      _rng.nextDouble(), // x 0..1
      _rng.nextDouble(), // y 0..1
      (_rng.nextDouble() - 0.5) * 0.0003, // vx per frame (normalised)
      (_rng.nextDouble() - 0.5) * 0.0003, // vy per frame
      _rng.nextDouble() * 1.5 + 0.3,      // radius px
      _rng.nextDouble(),                   // alpha
    ];
  });

  const _ParticlePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (final p in _particles) {
      double x = ((p[0] + p[2] * t * 10000) % 1.0) * size.width;
      double y = ((p[1] + p[3] * t * 10000) % 1.0) * size.height;
      if (x < 0) x += size.width;
      if (y < 0) y += size.height;
      paint.color = Colors.white.withOpacity(p[5] * 0.6 * 0.18);
      canvas.drawCircle(Offset(x, y), p[4], paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.t != t;
}
