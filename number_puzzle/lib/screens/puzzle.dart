import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:math';

import '../models/puzzle_board.dart';
import '../models/puzzle_solver.dart';
import '../widgets/puzzle_tile.dart';

// ── Colour tokens ────────────────────────────────────────────────────────────
const _kBg      = Color(0xFF0D0D0D);
const _kBoard   = Color(0xFF161616);
const _kStat    = Color(0xFFF2F2F2);
const _kDark    = Color(0xFF111111);
const _kMesh    = Color(0xFF1C1C1C);

class PuzzleScreen extends StatefulWidget {
  final String playerName;
  final bool resumeGame;

  const PuzzleScreen({
    super.key,
    required this.playerName,
    this.resumeGame = false,
  });

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  late PuzzleBoard _board;
  Timer? _timer;
  int _seconds = 0;
  bool _gameWon = false;

  // Solver state
  List<int>? _solutionPath;
  bool _isComputingSolution = false;

  // Auto-solve limiter
  int _totalSolveUses     = 0;
  int _currentStreakCount = 0;
  static const int _solveUseLimit        = 20;
  static const int _solveCooldownSeconds = 120;
  int   _solveCooldownRemaining = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _board = PuzzleBoard();
    if (widget.resumeGame) _loadGameState();
    _startTimer();
  }

  // ── Persistence ─────────────────────────────────────────────────────────
  Future<void> _loadGameState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedBoard   = prefs.getString('saved_board_state');
    final savedMoves   = prefs.getInt('saved_moves')   ?? 0;
    final savedSeconds = prefs.getInt('saved_seconds') ?? 0;
    if (savedBoard != null && mounted) {
      setState(() {
        _board.tiles  = savedBoard.split(',').map(int.parse).toList();
        _board.moves  = savedMoves;
        _seconds      = savedSeconds;
      });
    }
  }

  Future<void> _saveGameState() async {
    final prefs = await SharedPreferences.getInstance();
    if (_gameWon) {
      await prefs.remove('saved_board_state');
      await prefs.remove('saved_moves');
      await prefs.remove('saved_seconds');
    } else {
      await prefs.setString('saved_board_state', _board.tiles.join(','));
      await prefs.setInt('saved_moves',   _board.moves);
      await prefs.setInt('saved_seconds', _seconds);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  // ── Timer ────────────────────────────────────────────────────────────────
  void _startTimer() {
    _timer?.cancel();
    _seconds = widget.resumeGame ? _seconds : 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_gameWon) {
        setState(() => _seconds++);
        if (_seconds % 5 == 0) _saveGameState();
      }
    });
  }

  // ── Game control ─────────────────────────────────────────────────────────
  void _resetGame() {
    setState(() {
      _board.reset();
      _seconds                = 0;
      _gameWon                = false;
      _solutionPath           = null;
      _isComputingSolution    = false;
      _totalSolveUses         = 0;
      _currentStreakCount      = 0;
      _solveCooldownRemaining = 0;
    });
    _cooldownTimer?.cancel();
    _saveGameState();
    _startTimer();
  }

  void _onTileTap(int index) {
    if (_gameWon || _isComputingSolution) return;
    final moved = _board.moveTile(index);
    if (moved) {
      setState(() => _solutionPath = null);
      _saveGameState();
      if (_board.isWin()) {
        _timer?.cancel();
        _saveGameState();
        setState(() => _gameWon = true);
        Future.delayed(const Duration(milliseconds: 400), _showWinDialog);
      }
    }
  }

  // ── Auto-solve ───────────────────────────────────────────────────────────
  Future<void> _handleSolveStep() async {
    if (_gameWon || _isComputingSolution) return;
    if (_solveCooldownRemaining > 0) return;

    if (_currentStreakCount >= _solveUseLimit) {
      setState(() {
        _currentStreakCount      = 0;
        _solveCooldownRemaining = _solveCooldownSeconds;
      });
      _cooldownTimer?.cancel();
      _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        setState(() => _solveCooldownRemaining--);
        if (_solveCooldownRemaining <= 0) t.cancel();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Auto-Solve cooldown: 2 minutes')),
      );
      return;
    }

    _currentStreakCount++;
    setState(() => _totalSolveUses++);

    if (_solutionPath != null && _solutionPath!.isNotEmpty) {
      _performNextStep();
    } else {
      await _computeSolutionPath();
    }
  }

  Future<void> _computeSolutionPath() async {
    setState(() => _isComputingSolution = true);
    try {
      final args = {'tiles': List<int>.from(_board.tiles), 'size': _board.size};
      final path = await compute(solvePuzzleAsync, args);
      if (!mounted) return;
      setState(() {
        _isComputingSolution = false;
        if (path != null && path.isNotEmpty) {
          _solutionPath = path;
          _performNextStep();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not find a solution quickly enough.')),
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isComputingSolution = false);
    }
  }

  void _performNextStep() {
    if (_solutionPath == null || _solutionPath!.isEmpty) return;
    _onTileTap(_solutionPath!.removeAt(0));
  }

  // ── Dialogs ──────────────────────────────────────────────────────────────
  void _showHowToPlayDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: const Color(0xFF1A1A1A),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('How to Play',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildStep('1. First Row', 'Get 1–3 in place. Put 4 under 3, move 3 left of 4, then slide up.'),
                _buildStep('2. Second Row', 'Same strategy for 5–8.'),
                _buildStep('3. Columns', 'Work in columns on the bottom-left for 9, 13 then 10, 14.'),
                _buildStep('4. Final Pieces', 'Rotate the last three in a 2×2 circle.'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(String title, String desc) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white70)),
        const SizedBox(height: 4),
        Text(desc, style: const TextStyle(fontSize: 13, color: Colors.white38, height: 1.4)),
      ],
    ),
  );

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: const Color(0xFF1A1A1A),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Settings',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('Player', style: TextStyle(fontSize: 12, color: Colors.white38, letterSpacing: 1)),
              const SizedBox(height: 6),
              Text(widget.playerName,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pushReplacementNamed('/');
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white24),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Back to Home', style: TextStyle(color: Colors.white70)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWinDialog() {
    final quotes = [
      "Great job, ${widget.playerName}!",
      "You're a genius, ${widget.playerName}!",
      "ترييييس يا نمر, ${widget.playerName}!",
      "Outstanding logic, ${widget.playerName}!",
      "Masterfully done, ${widget.playerName}!",
    ];
    final quote = quotes[Random().nextInt(quotes.length)];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: const Color(0xFF1A1A1A),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 52)),
              const SizedBox(height: 12),
              const Text('You Won!',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 12),
              Text(quote,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15, fontStyle: FontStyle.italic, color: Colors.white54)),
              const SizedBox(height: 14),
              Text('${_board.moves} moves  •  ${_formatTime(_seconds)}',
                  style: const TextStyle(fontSize: 15, color: Colors.white38)),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () { Navigator.of(ctx).pop(); _resetGame(); },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: _kDark,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Play Again',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Mesh background
          CustomPaint(painter: _MeshPainter()),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Column(
                children: [
                  _buildTopBar(),
                  const SizedBox(height: 18),
                  _buildPuzzleGrid(),
                  const SizedBox(height: 20),
                  _buildBottomButtons(),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),

        ],
      ),
    );
  }

  // ── Top Bar ──────────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Logo
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('NUMO',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1,
                  height: 1.0,
                )),
            Text('NUMBER SLIDER',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: Colors.white38,
                  letterSpacing: 2,
                )),
          ],
        ),

        const SizedBox(width: 12),

        // Stats pill (center)
        Expanded(
          child: _StatsPill(
            moves: _board.moves,
            solves: _totalSolveUses,
            time: _formatTime(_seconds),
          ),
        ),

        const SizedBox(width: 12),

        // Icon buttons right
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _IconBtn(icon: Icons.help_outline_rounded, onTap: _showHowToPlayDialog),
            const SizedBox(width: 4),
            _IconBtn(icon: Icons.refresh_rounded, onTap: _resetGame),
            const SizedBox(width: 4),
            _IconBtn(icon: Icons.settings_outlined, onTap: _showSettingsDialog),
          ],
        ),
      ],
    );
  }

  // ── Puzzle Grid ──────────────────────────────────────────────────────────
  Widget _buildPuzzleGrid() {
    return Expanded(
      child: Center(
        child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _kBoard,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withOpacity(0.06), width: 1),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.55), blurRadius: 30, offset: const Offset(0, 10)),
              ],
            ),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _board.size,
                mainAxisSpacing: 7,
                crossAxisSpacing: 7,
              ),
              itemCount: _board.size * _board.size,
              itemBuilder: (context, index) {
                final value     = _board.tiles[index];
                final isCorrect = value == index + 1;
                return PuzzleTile(
                  value: value,
                  isCorrect: isCorrect,
                  onTap: () => _onTileTap(index),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ── Bottom Buttons ───────────────────────────────────────────────────────
  Widget _buildBottomButtons() {
    final solveLabel = _isComputingSolution
        ? 'Thinking...'
        : _solveCooldownRemaining > 0
            ? 'Cooldown ${_solveCooldownRemaining}s'
            : (_solutionPath != null && _solutionPath!.isNotEmpty)
                ? 'Next Step (${_solutionPath!.length})'
                : 'AUTO-SOLVE ($_currentStreakCount/$_solveUseLimit)';

    final canSolve = !_isComputingSolution && _solveCooldownRemaining <= 0 && !_gameWon;

    return Row(
      children: [
        // NEW GAME — white outline pill
        Expanded(
          child: _PillButton(
            label: 'NEW GAME',
            dark: false,
            onTap: _resetGame,
          ),
        ),
        const SizedBox(width: 10),
        // AUTO-SOLVE — dark filled pill
        Expanded(
          child: _PillButton(
            label: solveLabel,
            dark: true,
            onTap: canSolve ? _handleSolveStep : null,
            loading: _isComputingSolution,
          ),
        ),
      ],
    );
  }
}

// ── Stats pill widget ────────────────────────────────────────────────────────
class _StatsPill extends StatelessWidget {
  final int moves;
  final int solves;
  final String time;

  const _StatsPill({required this.moves, required this.solves, required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: _kStat,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 11, color: Color(0xFF555555), fontFamily: 'Roboto'),
                    children: [
                      const TextSpan(text: 'MOVES: ', style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                      TextSpan(
                          text: '$moves',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF111111))),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 10, color: Color(0xFF888888), fontFamily: 'Roboto'),
                    children: [
                      const TextSpan(text: 'SOLVES ', style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                      TextSpan(
                          text: '$solves',
                          style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF333333))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 32, color: const Color(0xFFCCCCCC)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('TIME:',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF555555), letterSpacing: 0.5)),
              Text(time,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF111111), height: 1.1)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Icon button ──────────────────────────────────────────────────────────────
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white12),
        ),
        child: Icon(icon, color: Colors.white60, size: 20),
      ),
    );
  }
}

// ── Pill button ──────────────────────────────────────────────────────────────
class _PillButton extends StatelessWidget {
  final String label;
  final bool dark;
  final VoidCallback? onTap;
  final bool loading;

  const _PillButton({
    required this.label,
    required this.dark,
    this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: onTap == null ? 0.45 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          height: 52,
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
            child: loading
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: dark ? Colors.white : _kDark,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Mesh background painter ──────────────────────────────────────────────────
class _MeshPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _kMesh
      ..strokeWidth = 0.6;

    const spacing = 38.0;

    // Horizontal lines with wave distortion
    for (double y = 0; y < size.height; y += spacing) {
      final path = Path();
      path.moveTo(0, y);
      for (double x = 0; x <= size.width; x += 4) {
        final waveY = y + sin(x * 0.018 + y * 0.008) * 10;
        path.lineTo(x, waveY);
      }
      canvas.drawPath(path, paint);
    }

    // Vertical lines with wave distortion
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

