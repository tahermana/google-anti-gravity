import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Animated three-arc calorie ring drawn with CustomPainter.
class CalorieRing extends StatefulWidget {
  final int eaten;
  final int burned;
  final int goal;
  final int kcalLeft;

  const CalorieRing({
    super.key,
    required this.eaten,
    required this.burned,
    required this.goal,
    required this.kcalLeft,
  });

  @override
  State<CalorieRing> createState() => _CalorieRingState();
}

class _CalorieRingState extends State<CalorieRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ── Ring ──────────────────────────────────────────────────────────────
        SizedBox(
          width: 130,
          height: 130,
          child: AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => CustomPaint(
              painter: _RingPainter(
                eatenPct:  widget.goal > 0
                    ? (widget.eaten  / widget.goal).clamp(0.0, 1.0) * _anim.value
                    : 0.0,
                burnedPct: widget.goal > 0
                    ? (widget.burned / widget.goal).clamp(0.0, 1.0) * _anim.value
                    : 0.0,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.kcalLeft.toString(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: kTextPrim,
                        letterSpacing: -1,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'KCAL LEFT',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: kTextSec,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        // ── Legend ────────────────────────────────────────────────────────────
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LegendRow(color: kBgCard3,  label: 'Goal',   value: widget.goal.toString()),
              const SizedBox(height: 6),
              _LegendRow(color: kAccent,   label: 'Eaten',  value: widget.eaten.toString()),
              const SizedBox(height: 6),
              _LegendRow(color: kTextMuted, label: 'Burned', value: widget.burned.toString()),
            ],
          ),
        ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color  color;
  final String label;
  final String value;
  const _LegendRow({required this.color, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: color == kAccent
                ? [BoxShadow(color: kAccent.withOpacity(0.45), blurRadius: 6)]
                : null,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: kTextSec))),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: kTextPrim)),
      ],
    );
  }
}

// ── Painter ───────────────────────────────────────────────────────────────────
class _RingPainter extends CustomPainter {
  final double eatenPct;
  final double burnedPct;

  const _RingPainter({required this.eatenPct, required this.burnedPct});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width  / 2;
    final cy = size.height / 2;
    final r  = (size.shortestSide / 2) - 12;
    const stroke = 10.0;
    const startAngle = -pi / 2;

    final bgPaint = Paint()
      ..color = const Color(0xFF2A2A30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final burnedPaint = Paint()
      ..color = kTextMuted
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    final eatenPaint = Paint()
      ..color = kAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final rect = Rect.fromCircle(center: Offset(cx, cy), radius: r);

    // Background track
    canvas.drawCircle(Offset(cx, cy), r, bgPaint);

    // Burned arc
    if (burnedPct > 0) {
      canvas.drawArc(rect, startAngle, 2 * pi * burnedPct, false, burnedPaint);
    }

    // Eaten arc (glow layer)
    if (eatenPct > 0) {
      canvas.drawArc(rect, startAngle, 2 * pi * eatenPct, false, eatenPaint);

      // Solid top layer without blur
      canvas.drawArc(
        rect, startAngle, 2 * pi * eatenPct, false,
        Paint()
          ..color = kAccent
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.eatenPct != eatenPct || old.burnedPct != burnedPct;
}
