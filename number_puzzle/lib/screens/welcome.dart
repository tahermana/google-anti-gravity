import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:math';
import 'puzzle.dart';

const _kBg   = Color(0xFF0D0D0D);
const _kMesh = Color(0xFF1C1C1C);
const _kStat = Color(0xFFF2F2F2);
const _kDark = Color(0xFF111111);

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final TextEditingController _nameController = TextEditingController();
  bool _hasSavedGame = false;

  @override
  void initState() {
    super.initState();
    _checkSavedGame();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _checkSavedGame() async {
    final prefs     = await SharedPreferences.getInstance();
    final hasGame   = prefs.getString('saved_board_state') != null;
    final savedName = prefs.getString('player_name') ?? '';
    setState(() {
      _hasSavedGame = hasGame;
      if (savedName.isNotEmpty) _nameController.text = savedName;
    });
  }

  void _startGame(bool resume) {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your name first!')),
      );
      return;
    }
    final playerName = _nameController.text.trim();
    SharedPreferences.getInstance().then((p) => p.setString('player_name', playerName));
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PuzzleScreen(playerName: playerName, resumeGame: resume),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Mesh background
          CustomPaint(painter: _WelcomeMeshPainter()),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Animated logo grid
                    const _AnimatedNumoLogo(),
                    const SizedBox(height: 28),

                    // Title
                    const Text('NUMO',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 3,
                        )),
                    const SizedBox(height: 4),
                    const Text('NUMBER SLIDER',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white38,
                          letterSpacing: 3,
                        )),
                    const SizedBox(height: 36),

                    // Name card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161616),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.07)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Your name, genius?',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.white38,
                                letterSpacing: 0.3,
                              )),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _nameController,
                            style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              hintText: 'Enter your name...',
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.22)),
                              filled: true,
                              fillColor: const Color(0xFF0D0D0D),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // NEW GAME — white pill
                    _PillButton(
                      label: 'NEW GAME',
                      dark: false,
                      onTap: () => _startGame(false),
                    ),
                    const SizedBox(height: 12),

                    // CONTINUE — dark pill
                    _PillButton(
                      label: _hasSavedGame ? 'CONTINUE GAME' : 'NO SAVED GAME',
                      dark: true,
                      onTap: _hasSavedGame ? () => _startGame(true) : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pill button ──────────────────────────────────────────────────────────────
class _PillButton extends StatelessWidget {
  final String label;
  final bool dark;
  final VoidCallback? onTap;

  const _PillButton({required this.label, required this.dark, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: onTap == null ? 0.4 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          height: 54,
          decoration: BoxDecoration(
            color: dark ? _kDark : _kStat,
            borderRadius: BorderRadius.circular(30),
            border: dark ? null : Border.all(color: Colors.white24, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(dark ? 0.5 : 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: dark ? Colors.white : _kDark,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Mesh painter ─────────────────────────────────────────────────────────────
class _WelcomeMeshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _kMesh
      ..strokeWidth = 0.6;

    const spacing = 38.0;

    for (double y = 0; y < size.height; y += spacing) {
      final path = Path();
      path.moveTo(0, y);
      for (double x = 0; x <= size.width; x += 4) {
        final waveY = y + sin(x * 0.018 + y * 0.008) * 10;
        path.lineTo(x, waveY);
      }
      canvas.drawPath(path, paint);
    }

    for (double x = 0; x < size.width; x += spacing) {
      final path = Path();
      path.moveTo(x, 0);
      for (double y = 0; y <= size.height; y += 4) {
        final waveX = x + sin(y * 0.018 + x * 0.008) * 10;
        path.lineTo(waveX, y);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Animated logo grid ────────────────────────────────────────────────────────
class _LogoTile {
  final int id;
  final String label;
  _LogoTile(this.id, this.label);
}

class _AnimatedNumoLogo extends StatefulWidget {
  const _AnimatedNumoLogo();

  @override
  State<_AnimatedNumoLogo> createState() => _AnimatedNumoLogoState();
}

class _AnimatedNumoLogoState extends State<_AnimatedNumoLogo> {
  late List<_LogoTile?> _board;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _board = [
      _LogoTile(1, '1'), _LogoTile(2, '6'), _LogoTile(3, '1'),
      _LogoTile(4, '1'), _LogoTile(5, '1'), _LogoTile(6, '9'),
      _LogoTile(7, '9'), _LogoTile(8, '9'), null,
    ];
    _timer = Timer.periodic(const Duration(milliseconds: 1200), (_) {
      if (mounted) _moveRandom();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _moveRandom() {
    final emptyIndex = _board.indexOf(null);
    final emptyRow   = emptyIndex ~/ 3;
    final emptyCol   = emptyIndex % 3;

    final moves = <int>[];
    if (emptyRow > 0) moves.add(emptyIndex - 3);
    if (emptyRow < 2) moves.add(emptyIndex + 3);
    if (emptyCol > 0) moves.add(emptyIndex - 1);
    if (emptyCol < 2) moves.add(emptyIndex + 1);

    final pick = moves[Random().nextInt(moves.length)];
    setState(() {
      _board[emptyIndex] = _board[pick];
      _board[pick]       = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    const double boardSize = 150.0;
    const double pad       = 8.0;
    const double gap       = 5.0;
    const double inner     = boardSize - pad * 2;
    const double tileSize  = (inner - gap * 2) / 3;

    return Center(
      child: Container(
        width: boardSize,
        height: boardSize,
        decoration: BoxDecoration(
          color: const Color(0xFF161616),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 24, offset: const Offset(0, 8)),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: _board.where((t) => t != null).map((t) {
            final tile  = t!;
            final index = _board.indexOf(tile);
            final row   = index ~/ 3;
            final col   = index % 3;

            return AnimatedPositioned(
              key: ValueKey(tile.id),
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutCubic,
              top:  pad + row * (tileSize + gap),
              left: pad + col * (tileSize + gap),
              width: tileSize,
              height: tileSize,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFEEEEEE), Color(0xFFCCCCCC)],
                  ),
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 3)),
                  ],
                ),
                child: Center(
                  child: Text(
                    tile.label,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF111111),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
