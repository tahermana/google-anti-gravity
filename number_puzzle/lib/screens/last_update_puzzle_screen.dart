import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../models/puzzle_board.dart';
import '../models/puzzle_solver.dart';
import '../widgets/puzzle_tile.dart';

class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({super.key});

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  late PuzzleBoard _board;
  Timer? _timer;
  int _seconds = 0;
  bool _gameWon = false;
  bool _showHint = false;

  // Solver state
  List<int>? _solutionPath;
  bool _isComputingSolution = false;

  static const _accentColor = Color(0xFF7C6EFF);
  static const _bgColor = Color(0xFF0F0F1A);
  static const _cardColor = Color(0xFF1A1A2E);

  @override
  void initState() {
    super.initState();
    _board = PuzzleBoard();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _seconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_gameWon) setState(() => _seconds++);
    });
  }

  void _resetGame() {
    setState(() {
      _board.reset();
      _gameWon = false;
      _solutionPath = null;
      _isComputingSolution = false;
    });
    _startTimer();
  }

  void _onTileTap(int index) {
    if (_gameWon || _isComputingSolution) return;
    final moved = _board.moveTile(index);
    if (moved) {
      setState(() {
        // Invalidate solution path if user makes a manual move
        _solutionPath = null;
      });
      if (_board.isWin()) {
        _timer?.cancel();
        setState(() => _gameWon = true);
        Future.delayed(const Duration(milliseconds: 400), _showWinDialog);
      }
    }
  }

  Future<void> _handleSolveStep() async {
    if (_gameWon || _isComputingSolution) return;

    if (_solutionPath != null && _solutionPath!.isNotEmpty) {
      _performNextStep();
    } else {
      await _computeSolutionPath();
    }
  }

  Future<void> _computeSolutionPath() async {
    setState(() {
      _isComputingSolution = true;
    });

    try {
      // Extract arguments outside of the closure so it can be cleanly sent
      final args = {
        'tiles': List<int>.from(_board.tiles),
        'size': _board.size,
      };

      // Run the solver in a background isolate to avoid freezing the UI
      final path = await compute(solvePuzzleAsync, args);

      if (!mounted) return;

      setState(() {
        _isComputingSolution = false;
        if (path != null && path.isNotEmpty) {
          _solutionPath = path;
          _performNextStep();
        } else if (path == null) {
          // If solver returns null, it hit the max node limit or failed
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Could not find a solution quickly enough.')),
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isComputingSolution = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error solving puzzle: $e')),
      );
    }
  }

  void _performNextStep() {
    if (_solutionPath == null || _solutionPath!.isEmpty) return;

    // The A* algorithm records the index of the tile that moved
    final nextTileIndex = _solutionPath!.removeAt(0);
    _onTileTap(nextTileIndex);
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: _cardColor,
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              const Text(
                'You Won!',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_board.moves} moves  •  ${_formatTime(_seconds)}',
                style: const TextStyle(fontSize: 16, color: Colors.white60),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _resetGame();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Play Again',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16),
          child: Column(
            children: [
              // ─── Header ───
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NUMBER',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 4,
                          color: _accentColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'PUZZLE',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Toggle Hint',
                        icon: Icon(
                          _showHint ? Icons.lightbulb : Icons.lightbulb_outline,
                          color: _showHint ? Colors.amber : Colors.white70,
                          size: 28,
                        ),
                        onPressed: () {
                          setState(() {
                            _showHint = !_showHint;
                          });
                        },
                      ),
                      IconButton(
                        tooltip: 'New Game',
                        icon: const Icon(Icons.refresh_rounded,
                            color: Colors.white70, size: 28),
                        onPressed: _resetGame,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ─── Stats Row ───
              Row(
                children: [
                  _StatCard(
                    icon: Icons.swap_horiz_rounded,
                    label: 'MOVES',
                    value: '${_board.moves}',
                    color: _cardColor,
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    icon: Icons.timer_outlined,
                    label: 'TIME',
                    value: _formatTime(_seconds),
                    color: _cardColor,
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ─── Puzzle Grid ───
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: _board.size,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemCount: _board.size * _board.size,
                      itemBuilder: (context, index) {
                        final value = _board.tiles[index];
                        final isCorrect = _showHint && value == index + 1;
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

              const SizedBox(height: 24),

              // ─── New Game Button ───
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _resetGame,
                  icon: const Icon(Icons.shuffle_rounded,
                      size: 20, color: Colors.white),
                  label: const Text(
                    'New Game',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: _accentColor.withOpacity(0.5),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ─── Solve / Next Step Button ───
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isComputingSolution ? null : _handleSolveStep,
                  icon: _isComputingSolution
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.psychology_rounded,
                          size: 20, color: Colors.white),
                  label: Text(
                    _isComputingSolution
                        ? 'Thinking...'
                        : (_solutionPath != null && _solutionPath!.isNotEmpty)
                            ? 'Next Step (${_solutionPath!.length} left)'
                            : 'Auto-Solve',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                        0xFF4CAF50), // Green to indicate it's helpful
                    disabledBackgroundColor:
                        const Color(0xFF4CAF50).withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF7C6EFF), size: 22),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.5,
                    color: Colors.white38,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
