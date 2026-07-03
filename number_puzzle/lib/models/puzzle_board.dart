import 'dart:math';

class PuzzleBoard {
  final int size;
  late List<int> tiles; // 0 represents the empty tile
  int moves = 0;

  PuzzleBoard({this.size = 4}) {
    _initBoard();
  }

  void _initBoard() {
    do {
      tiles = List.generate(size * size, (i) => i);
      _shuffle();
    } while (!_isSolvable() || isWin());
    moves = 0;
  }

  void _shuffle() {
    final rng = Random();
    for (int i = tiles.length - 1; i > 0; i--) {
      int j = rng.nextInt(i + 1);
      int temp = tiles[i];
      tiles[i] = tiles[j];
      tiles[j] = temp;
    }
  }

  // A 15-puzzle is solvable if:
  // - Grid width is odd: number of inversions must be even.
  // - Grid width is even: (inversions even && blank on odd row from bottom)
  //                    OR (inversions odd && blank on even row from bottom)
  bool _isSolvable() {
    int inversions = 0;
    final flatTiles = tiles.where((t) => t != 0).toList();
    for (int i = 0; i < flatTiles.length; i++) {
      for (int j = i + 1; j < flatTiles.length; j++) {
        if (flatTiles[i] > flatTiles[j]) inversions++;
      }
    }

    if (size % 2 != 0) {
      return inversions % 2 == 0;
    } else {
      int emptyRow = tiles.indexOf(0) ~/ size;
      int emptyRowFromBottom = size - emptyRow;
      if (emptyRowFromBottom % 2 != 0) {
        return inversions % 2 == 0;
      } else {
        return inversions % 2 != 0;
      }
    }
  }

  bool isWin() {
    for (int i = 0; i < tiles.length - 1; i++) {
      if (tiles[i] != i + 1) return false;
    }
    return tiles.last == 0;
  }

  // Returns true if the move was valid
  bool moveTile(int tileIndex) {
    int emptyIndex = tiles.indexOf(0);
    if (_isAdjacent(tileIndex, emptyIndex)) {
      tiles[emptyIndex] = tiles[tileIndex];
      tiles[tileIndex] = 0;
      moves++;
      return true;
    }
    return false;
  }

  bool _isAdjacent(int a, int b) {
    int rowA = a ~/ size, colA = a % size;
    int rowB = b ~/ size, colB = b % size;
    return (rowA == rowB && (colA - colB).abs() == 1) ||
        (colA == colB && (rowA - rowB).abs() == 1);
  }

  void reset() {
    _initBoard();
  }
}
