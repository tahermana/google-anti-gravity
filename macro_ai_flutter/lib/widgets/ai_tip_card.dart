import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Pulsing red dot + AI suggestion text card.
class AiTipCard extends StatefulWidget {
  final String message;
  const AiTipCard({super.key, required this.message});

  @override
  State<AiTipCard> createState() => _AiTipCardState();
}

class _AiTipCardState extends State<AiTipCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _glow = Tween<double>(begin: 4, end: 12).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(40, 14, 14, 14),
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E0A0B), Color(0xFF2A0D0F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kAccent.withOpacity(0.25)),
      ),
      child: Stack(
        children: [
          // Pulsing dot
          Positioned(
            left: -26,
            top: 0,
            bottom: 0,
            child: Center(
              child: AnimatedBuilder(
                animation: _glow,
                builder: (_, __) => Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: kAccent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: kAccent.withOpacity(0.6),
                        blurRadius: _glow.value,
                        spreadRadius: _glow.value / 4,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Text
          Text.rich(
            _buildSpan(widget.message),
            style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFFCCCCCC),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  TextSpan _buildSpan(String msg) {
    // Bold the part before " —"
    final idx = msg.indexOf(' —');
    if (idx < 0) return TextSpan(text: msg);
    return TextSpan(children: [
      TextSpan(
        text: msg.substring(0, idx),
        style: const TextStyle(fontWeight: FontWeight.w700, color: kTextPrim),
      ),
      TextSpan(text: msg.substring(idx)),
    ]);
  }
}
