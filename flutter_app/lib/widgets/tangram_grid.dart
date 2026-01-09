import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/game_models.dart';

/// Tangram grid widget - arrange pieces to form shapes
class TangramGrid extends StatefulWidget {
  final TangramPuzzle puzzle;
  final VoidCallback? onComplete;
  final VoidCallback? onMove;

  const TangramGrid({
    super.key,
    required this.puzzle,
    this.onComplete,
    this.onMove,
  });

  @override
  State<TangramGrid> createState() => _TangramGridState();
}

class _TangramGridState extends State<TangramGrid> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final puzzle = widget.puzzle;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Target silhouette display
        Container(
          margin: const EdgeInsets.all(16),
          height: 150,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Center(
            child: CustomPaint(
              size: const Size(120, 120),
              painter: _TargetPainter(
                target: puzzle.target,
                isDark: isDark,
              ),
            ),
          ),
        ),

        // Target name
        Text(
          'Make: ${puzzle.name}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 8),

        // Play area
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  // Background grid
                  Positioned.fill(
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.grey.shade900
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? Colors.grey.shade700
                              : Colors.grey.shade300,
                        ),
                      ),
                    ),
                  ),

                  // Pieces
                  ...puzzle.pieces.map((piece) => _buildDraggablePiece(
                        piece,
                        constraints,
                        theme,
                      )),
                ],
              );
            },
          ),
        ),

        // Controls
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: puzzle.selectedPiece != null
                    ? () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          puzzle.rotateSelectedPiece();
                        });
                        widget.onMove?.call();
                      }
                    : null,
                icon: const Icon(Icons.rotate_right),
                label: const Text('Rotate'),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: puzzle.selectedPiece?.type ==
                        TangramPieceType.parallelogram
                    ? () {
                        HapticFeedback.lightImpact();
                        setState(() {
                          puzzle.flipSelectedPiece();
                        });
                        widget.onMove?.call();
                      }
                    : null,
                icon: const Icon(Icons.flip),
                label: const Text('Flip'),
              ),
            ],
          ),
        ),

        // Instructions
        Padding(
          padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
          child: Text(
            'Drag pieces to arrange. Tap to select, then rotate or flip.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildDraggablePiece(
    TangramPiece piece,
    BoxConstraints constraints,
    ThemeData theme,
  ) {
    final puzzle = widget.puzzle;
    final isSelected = puzzle.selectedPiece == piece;
    final size = _getPieceSize(piece.type);

    return Positioned(
      left: piece.x,
      top: piece.y,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            if (isSelected) {
              puzzle.deselectPiece();
            } else {
              puzzle.selectPiece(piece);
            }
          });
        },
        onPanUpdate: (details) {
          setState(() {
            piece.x += details.delta.dx;
            piece.y += details.delta.dy;

            // Keep within bounds
            piece.x = piece.x.clamp(0, constraints.maxWidth - size);
            piece.y = piece.y.clamp(0, constraints.maxHeight - size);
          });
          widget.onMove?.call();
        },
        onPanEnd: (_) {
          if (puzzle.isComplete) {
            HapticFeedback.mediumImpact();
            widget.onComplete?.call();
          }
        },
        child: Transform.rotate(
          angle: piece.rotation * math.pi / 180,
          child: Container(
            decoration: BoxDecoration(
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.5),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(2, 2),
                      ),
                    ],
            ),
            child: CustomPaint(
              size: Size(size, size),
              painter: _TangramPiecePainter(
                piece: piece,
                isSelected: isSelected,
              ),
            ),
          ),
        ),
      ),
    );
  }

  double _getPieceSize(TangramPieceType type) {
    switch (type) {
      case TangramPieceType.largeTriangle1:
      case TangramPieceType.largeTriangle2:
        return 80;
      case TangramPieceType.mediumTriangle:
        return 60;
      case TangramPieceType.smallTriangle1:
      case TangramPieceType.smallTriangle2:
        return 40;
      case TangramPieceType.square:
        return 40;
      case TangramPieceType.parallelogram:
        return 60;
    }
  }
}

class _TargetPainter extends CustomPainter {
  final TangramTarget target;
  final bool isDark;

  _TargetPainter({required this.target, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (target.vertices.isEmpty) return;

    final paint = Paint()
      ..color = isDark ? Colors.grey.shade600 : Colors.grey.shade400
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = isDark ? Colors.grey.shade500 : Colors.grey.shade500
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Scale vertices to fit in the canvas
    final path = Path();
    final scale = size.width / 200; // Assuming 200 is the base size

    path.moveTo(
      target.vertices[0][0] * scale,
      target.vertices[0][1] * scale,
    );

    for (int i = 1; i < target.vertices.length; i++) {
      path.lineTo(
        target.vertices[i][0] * scale,
        target.vertices[i][1] * scale,
      );
    }
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _TargetPainter oldDelegate) {
    return target != oldDelegate.target;
  }
}

class _TangramPiecePainter extends CustomPainter {
  final TangramPiece piece;
  final bool isSelected;

  _TangramPiecePainter({required this.piece, required this.isSelected});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(piece.colorValue)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = isSelected ? Colors.white : Colors.black.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 3 : 1;

    final path = Path();

    switch (piece.type) {
      case TangramPieceType.largeTriangle1:
      case TangramPieceType.largeTriangle2:
      case TangramPieceType.mediumTriangle:
      case TangramPieceType.smallTriangle1:
      case TangramPieceType.smallTriangle2:
        // Right triangle
        path.moveTo(0, size.height);
        path.lineTo(size.width, size.height);
        path.lineTo(size.width / 2, 0);
        path.close();
        break;

      case TangramPieceType.square:
        // Square
        path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));
        break;

      case TangramPieceType.parallelogram:
        // Parallelogram
        final offset = size.width * 0.3;
        if (piece.isFlipped) {
          path.moveTo(0, 0);
          path.lineTo(size.width - offset, 0);
          path.lineTo(size.width, size.height);
          path.lineTo(offset, size.height);
        } else {
          path.moveTo(offset, 0);
          path.lineTo(size.width, 0);
          path.lineTo(size.width - offset, size.height);
          path.lineTo(0, size.height);
        }
        path.close();
        break;
    }

    canvas.drawPath(path, paint);
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _TangramPiecePainter oldDelegate) {
    return piece != oldDelegate.piece || isSelected != oldDelegate.isSelected;
  }
}

// =============================================================================
// TEST SCREEN
// =============================================================================

class TangramTestScreen extends StatefulWidget {
  const TangramTestScreen({super.key});

  @override
  State<TangramTestScreen> createState() => _TangramTestScreenState();
}

class _TangramTestScreenState extends State<TangramTestScreen> {
  late TangramPuzzle _puzzle;
  int _currentLevel = 1;

  @override
  void initState() {
    super.initState();
    _loadLevel(1);
  }

  void _loadLevel(int level) {
    setState(() {
      _currentLevel = level;
      switch (level) {
        case 1:
          _puzzle = TangramPuzzle.sampleLevel1();
        case 2:
          _puzzle = TangramPuzzle.sampleLevel2();
        case 3:
          _puzzle = TangramPuzzle.sampleLevel3();
        default:
          _puzzle = TangramPuzzle.sampleLevel1();
      }
    });
  }

  void _onComplete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tangram Complete!'),
        content: Text('You made the ${_puzzle.name}!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _puzzle.reset());
            },
            child: const Text('Play Again'),
          ),
          if (_currentLevel < 3)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _loadLevel(_currentLevel + 1);
              },
              child: const Text('Next Shape'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tangram'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() => _puzzle.reset()),
            tooltip: 'Reset',
          ),
        ],
      ),
      body: Column(
        children: [
          // Level selector
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 1; i <= 3; i++) ...[
                  if (i > 1) const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(_getLevelName(i)),
                    selected: _currentLevel == i,
                    onSelected: (_) => _loadLevel(i),
                  ),
                ],
              ],
            ),
          ),

          // Game grid
          Expanded(
            child: TangramGrid(
              key: ValueKey('tangram-$_currentLevel'),
              puzzle: _puzzle,
              onComplete: _onComplete,
            ),
          ),
        ],
      ),
    );
  }

  String _getLevelName(int level) {
    switch (level) {
      case 1:
        return 'Square';
      case 2:
        return 'House';
      case 3:
        return 'Cat';
      default:
        return 'Level $level';
    }
  }
}
