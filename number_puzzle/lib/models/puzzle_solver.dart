import 'package:collection/collection.dart';
import 'dart:collection';

class PuzzleNode implements Comparable<PuzzleNode> {
  final List<int> state;
  final int g; // Cost from start
  final int h; // Heuristic cost to goal
  final int f; // Total cost (g + h)
  final int emptyIndex;
  final PuzzleNode? parent;
  final int move; // The index of the tile moved to reach this state

  PuzzleNode({
    required this.state,
    required this.g,
    required this.h,
    required this.emptyIndex,
    this.parent,
    this.move = -1,
  }) : f = g + 3 * h; // Weighted A* for much faster solving

  @override
  int compareTo(PuzzleNode other) {
    if (f == other.f) {
      return other.g
          .compareTo(g); // Tie-breaker: prefer states further from start
    }
    return f.compareTo(other.f);
  }

  // To store in visited set efficiently
  String get stateString => state.join(',');
}

class PuzzleSolver {
  final int size;
  static const int _maxNodes = 500000; // Increased limit for complex puzzles

  PuzzleSolver({this.size = 4});

  /// Computes the sequence of moves (tile indices) to solve the board.
  /// If [initialTiles] is already solved, returns an empty list.
  /// If no solution can be found within the limit, returns null.
  List<int>? solve(List<int> initialTiles) {
    if (_isSolved(initialTiles)) return [];

    final startEmptyIndex = initialTiles.indexOf(0);
    final startNode = PuzzleNode(
      state: List.from(initialTiles),
      g: 0,
      h: _calculateManhattan(initialTiles),
      emptyIndex: startEmptyIndex,
    );

    final openSet = PriorityQueue<PuzzleNode>();
    final closedSet = HashSet<String>();

    openSet.add(startNode);
    int nodesExpanded = 0;

    while (openSet.isNotEmpty) {
      if (nodesExpanded > _maxNodes) return null; // Safety break

      final current = openSet.removeFirst();
      nodesExpanded++;

      final stateStr = current.stateString;
      if (closedSet.contains(stateStr)) continue;

      if (_isSolved(current.state)) {
        return _reconstructPath(current);
      }

      closedSet.add(stateStr);

      for (final neighbor in _getNeighbors(current)) {
        if (!closedSet.contains(neighbor.stateString)) {
          openSet.add(neighbor);
        }
      }
    }

    return null; // No solution found
  }

  List<int> _reconstructPath(PuzzleNode node) {
    final path = <int>[];
    PuzzleNode? curr = node;
    while (curr != null && curr.parent != null) {
      path.add(curr.move);
      curr = curr.parent;
    }
    return path.reversed.toList();
  }

  bool _isSolved(List<int> state) {
    for (int i = 0; i < state.length - 1; i++) {
      if (state[i] != i + 1) return false;
    }
    return state.last == 0;
  }

  int _calculateManhattan(List<int> state) {
    int distance = 0;
    for (int i = 0; i < state.length; i++) {
      final value = state[i];
      if (value == 0) continue; // Don't count the empty tile

      // Expected position (0-indexed based on value)
      final targetIdx = value - 1;

      final currRow = i ~/ size;
      final currCol = i % size;
      final targetRow = targetIdx ~/ size;
      final targetCol = targetIdx % size;

      distance += (currRow - targetRow).abs() + (currCol - targetCol).abs();
    }
    return distance;
  }

  List<PuzzleNode> _getNeighbors(PuzzleNode node) {
    final neighbors = <PuzzleNode>[];
    final emptyRow = node.emptyIndex ~/ size;
    final emptyCol = node.emptyIndex % size;

    // Deltas: Up, Down, Left, Right
    final moves = [
      [-1, 0],
      [1, 0],
      [0, -1],
      [0, 1]
    ];

    for (final dir in moves) {
      final newRow = emptyRow + dir[0];
      final newCol = emptyCol + dir[1];

      if (newRow >= 0 && newRow < size && newCol >= 0 && newCol < size) {
        final newEmptyIndex = newRow * size + newCol;
        final newState = List<int>.from(node.state);

        // Swap empty tile (0) with the adjacent tile
        final movedTileValue = newState[newEmptyIndex];
        newState[node.emptyIndex] = movedTileValue;
        newState[newEmptyIndex] = 0;

        final h = _calculateManhattan(newState);

        neighbors.add(PuzzleNode(
          state: newState,
          g: node.g + 1,
          h: h,
          emptyIndex: newEmptyIndex,
          parent: node,
          // The move recorded is the *original* position of the tile we just moved
          move: newEmptyIndex,
        ));
      }
    }
    return neighbors;
  }
}

/// Helper method to be used with Isolate.run() for computing the solution off the main thread.
List<int>? solvePuzzleAsync(Map<String, dynamic> args) {
  final tiles = args['tiles'] as List<int>;
  final size = args['size'] as int;
  final solver = PuzzleSolver(size: size);
  return solver.solve(tiles);
}
