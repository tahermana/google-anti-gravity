import 'package:flutter/material.dart';

class PuzzleTile extends StatelessWidget {
  final int value;
  final bool isCorrect;
  final VoidCallback onTap;

  const PuzzleTile({
    super.key,
    required this.value,
    this.isCorrect = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = value == 0;

    if (isEmpty) {
      return _EmptyTile();
    }

    return _FilledTile(value: value, isCorrect: isCorrect, onTap: onTap);
  }
}

// ── Empty tile: dark + crosshair ─────────────────────────────────────────────
class _EmptyTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111111),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: CustomPaint(
          size: const Size(28, 28),
          painter: _CrosshairPainter(),
        ),
      ),
    );
  }
}

class _CrosshairPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final cy = size.height / 2;
    const gap = 4.0;

    // Horizontal
    canvas.drawLine(Offset(0, cy), Offset(cx - gap, cy), paint);
    canvas.drawLine(Offset(cx + gap, cy), Offset(size.width, cy), paint);

    // Vertical
    canvas.drawLine(Offset(cx, 0), Offset(cx, cy - gap), paint);
    canvas.drawLine(Offset(cx, cy + gap), Offset(cx, size.height), paint);

    // Center circle
    paint.style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(cx, cy), 3.5, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Filled tile: white/silver with corner brackets ───────────────────────────
class _FilledTile extends StatefulWidget {
  final int value;
  final bool isCorrect;
  final VoidCallback onTap;

  const _FilledTile({
    required this.value,
    required this.isCorrect,
    required this.onTap,
  });

  @override
  State<_FilledTile> createState() => _FilledTileState();
}

class _FilledTileState extends State<_FilledTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _ctrl.forward();
  void _onTapUp(TapUpDetails _) {
    _ctrl.reverse();
    widget.onTap();
  }

  void _onTapCancel() => _ctrl.reverse();

  @override
  Widget build(BuildContext context) {
    // Single-digit numbers get larger font
    final fontSize = widget.value < 10 ? 34.0 : 26.0;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF0F0F0), Color(0xFFD8D8D8)],
            ),
            border: Border.all(
              color: const Color(0xFF777777),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(1, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14.5),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Corner bracket decorations
                CustomPaint(painter: _CornerBracketPainter()),

                // Top highlight edge
                Positioned(
                  top: 0, left: 0, right: 0, height: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.6),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Number
                Center(
                  child: Text(
                    '${widget.value}',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF111111),
                      letterSpacing: -0.5,
                      height: 1.0,
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
}

// ── Corner bracket painter ───────────────────────────────────────────────────
class _CornerBracketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.07)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final len = w * 0.2;
    final inset = w * 0.12;

    // Top-left bracket
    canvas.drawLine(Offset(inset, inset), Offset(inset + len, inset), paint);
    canvas.drawLine(Offset(inset, inset), Offset(inset, inset + len), paint);

    // Top-right bracket
    canvas.drawLine(Offset(w - inset, inset), Offset(w - inset - len, inset), paint);
    canvas.drawLine(Offset(w - inset, inset), Offset(w - inset, inset + len), paint);

    // Bottom-left bracket
    canvas.drawLine(Offset(inset, h - inset), Offset(inset + len, h - inset), paint);
    canvas.drawLine(Offset(inset, h - inset), Offset(inset, h - inset - len), paint);

    // Bottom-right bracket
    canvas.drawLine(Offset(w - inset, h - inset), Offset(w - inset - len, h - inset), paint);
    canvas.drawLine(Offset(w - inset, h - inset), Offset(w - inset, h - inset - len), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
