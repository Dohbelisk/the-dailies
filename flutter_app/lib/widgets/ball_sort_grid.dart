import 'package:flutter/material.dart';
import '../models/game_models.dart';

class BallSortGrid extends StatefulWidget {
  final BallSortPuzzle puzzle;
  final int? selectedTube;
  final int undosRemaining;
  final Function(int tubeIndex) onTubeTap;
  final Function(int fromTube, int toTube)? onMoveAnimationStart;
  final VoidCallback onUndo;
  final VoidCallback onReset;

  const BallSortGrid({
    super.key,
    required this.puzzle,
    required this.selectedTube,
    required this.undosRemaining,
    required this.onTubeTap,
    this.onMoveAnimationStart,
    required this.onUndo,
    required this.onReset,
  });

  @override
  State<BallSortGrid> createState() => _BallSortGridState();
}

class _BallSortGridState extends State<BallSortGrid> with TickerProviderStateMixin {
  static const Map<String, Color> _ballColors = {
    'red': Color(0xFFE53935),
    'blue': Color(0xFF1E88E5),
    'green': Color(0xFF43A047),
    'yellow': Color(0xFFFDD835),
    'purple': Color(0xFF8E24AA),
    'orange': Color(0xFFFB8C00),
    'pink': Color(0xFFEC407A),
    'cyan': Color(0xFF00ACC1),
    'lime': Color(0xFFC0CA33),
    'teal': Color(0xFF00897B),
  };

  // Animation state
  AnimationController? _moveController;
  Animation<double>? _moveAnimation;
  List<_AnimatingBall>? _animatingBalls;
  int? _animatingFromTube;

  // Layout measurements for animation
  double _ballSize = 0;
  double _tubeWidth = 0;
  double _tubeHeight = 0;
  double _tubeSpacing = 12;
  double _rowSpacing = 24;
  int _tubesPerRow = 4;
  Offset _gridOffset = Offset.zero;

  Color _getBallColor(String colorName) {
    return _ballColors[colorName.toLowerCase()] ?? Colors.grey;
  }

  @override
  void dispose() {
    _moveController?.dispose();
    super.dispose();
  }

  void _handleTubeTap(int tubeIndex) {
    // If we're animating, ignore taps
    if (_animatingBalls != null) return;

    // If layout hasn't happened yet, skip animation
    if (_ballSize <= 0) {
      widget.onTubeTap(tubeIndex);
      return;
    }

    final selectedTube = widget.selectedTube;

    // Check if this is a valid move
    if (selectedTube != null && selectedTube != tubeIndex) {
      if (widget.puzzle.canMoveTo(selectedTube, tubeIndex)) {
        // Calculate how many balls will move
        final consecutiveBalls = widget.puzzle.getConsecutiveTopBalls(selectedTube);
        final availableSpace = widget.puzzle.tubeCapacity - widget.puzzle.currentState[tubeIndex].length;
        final ballsToMove = consecutiveBalls < availableSpace ? consecutiveBalls : availableSpace;

        if (ballsToMove > 0) {
          // Trigger animation
          _animateMove(selectedTube, tubeIndex, ballsToMove, () {
            // After animation, call the actual tap handler to update state
            widget.onTubeTap(tubeIndex);
          });
          return;
        }
      }
    }

    // Not a move, just forward the tap
    widget.onTubeTap(tubeIndex);
  }

  void _animateMove(int fromTube, int toTube, int ballCount, VoidCallback onComplete) {
    _moveController?.dispose();
    _moveController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _moveAnimation = CurvedAnimation(
      parent: _moveController!,
      curve: Curves.easeOut,
    );

    // Calculate positions
    final fromPos = _getTubePosition(fromTube);
    final toPos = _getTubePosition(toTube);

    final fromTubeData = widget.puzzle.currentState[fromTube];
    final toTubeData = widget.puzzle.currentState[toTube];

    // Create animating balls (they're at the top of the source tube)
    _animatingBalls = [];
    for (int i = 0; i < ballCount; i++) {
      final ballIndex = fromTubeData.length - 1 - i;
      if (ballIndex >= 0) {
        final color = fromTubeData[ballIndex];
        // Start Y: position in source tube (selected, so offset up)
        final isTopBall = i == 0; // Only the very top ball is visually selected
        final startBallY = _getBallYPosition(fromTubeData.length, ballIndex, isSelected: isTopBall);
        // End Y: position in destination tube (after balls are added)
        final endBallIndex = toTubeData.length + (ballCount - 1 - i);
        final endBallY = _getBallYPosition(toTubeData.length + ballCount, endBallIndex);

        _animatingBalls!.add(_AnimatingBall(
          color: color,
          startX: fromPos.dx,
          startY: fromPos.dy + startBallY,
          endX: toPos.dx,
          endY: toPos.dy + endBallY,
        ));
      }
    }

    _animatingFromTube = fromTube;

    _moveController!.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _animatingBalls = null;
          _animatingFromTube = null;
        });
        onComplete();
      }
    });

    setState(() {});
    _moveController!.forward();
  }

  Offset _getTubePosition(int tubeIndex) {
    final row = tubeIndex ~/ _tubesPerRow;
    final col = tubeIndex % _tubesPerRow;
    final x = _gridOffset.dx + col * (_tubeWidth + _tubeSpacing);
    final y = _gridOffset.dy + row * (_tubeHeight + _rowSpacing);
    return Offset(x, y);
  }

  double _getBallYPosition(int tubeLength, int ballIndex, {bool isSelected = false}) {
    // Ball positions from top of tube
    // Empty space at top: (capacity - length) * ballSize + 8
    // Then balls stack downward
    // ballIndex 0 = bottom, ballIndex length-1 = top
    // Visual order: top ball first, so position = emptySpace + (length-1 - ballIndex) * ballSize
    final emptySpace = (widget.puzzle.tubeCapacity - tubeLength) * _ballSize + 8;
    final positionFromTop = tubeLength - 1 - ballIndex; // 0 for top ball, increases going down
    final y = emptySpace + positionFromTop * _ballSize;
    // Selected balls are visually offset upward by 6
    return isSelected ? y - 6 : y;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Info bar with moves and controls
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Move counter
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Moves: ${widget.puzzle.moveCount}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              // Control buttons
              Row(
                children: [
                  // Undo button
                  FilledButton.tonal(
                    onPressed: widget.puzzle.moveHistory.isEmpty || widget.undosRemaining <= 0
                        ? null
                        : widget.onUndo,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.undo, size: 18),
                        const SizedBox(width: 4),
                        Text('${widget.undosRemaining}'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Reset button
                  IconButton.outlined(
                    onPressed: widget.puzzle.moveCount == 0 ? null : widget.onReset,
                    icon: const Icon(Icons.refresh, size: 20),
                    tooltip: 'Reset puzzle',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Tubes grid
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return _buildTubesGrid(context, constraints);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTubesGrid(BuildContext context, BoxConstraints constraints) {
    final tubeCount = widget.puzzle.tubeCount;

    // Arrange tubes: up to 6 per row for small counts, otherwise split into 2 rows
    _tubesPerRow = tubeCount <= 6 ? tubeCount : (tubeCount / 2).ceil();
    final rows = (tubeCount / _tubesPerRow).ceil();

    // Calculate dimensions based on available space
    final availableWidth = constraints.maxWidth - 32;
    final availableHeight = constraints.maxHeight - 32;

    // Calculate max tube width based on how many fit per row
    final maxTubeWidth = (availableWidth - (_tubesPerRow - 1) * _tubeSpacing) / _tubesPerRow;

    // Calculate max tube height based on number of rows
    final maxTubeHeight = (availableHeight - (rows - 1) * _rowSpacing) / rows;

    // Ball size determines tube dimensions
    // Each ball slot = ballSize (no extra margin to prevent overflow)
    // tubeHeight = ballSize * capacity + padding(16)
    final ballSizeFromHeight = (maxTubeHeight - 16) / widget.puzzle.tubeCapacity;
    final ballSizeFromWidth = maxTubeWidth * 0.75;

    // Use the smaller constraint, with a reasonable max size
    _ballSize = [ballSizeFromHeight, ballSizeFromWidth, 36.0].reduce((a, b) => a < b ? a : b).clamp(14.0, 36.0);
    _tubeWidth = _ballSize / 0.75;
    _tubeHeight = _ballSize * widget.puzzle.tubeCapacity + 16;

    // Calculate grid offset for centering
    final totalWidth = _tubesPerRow * _tubeWidth + (_tubesPerRow - 1) * _tubeSpacing;
    final totalHeight = rows * _tubeHeight + (rows - 1) * _rowSpacing;
    _gridOffset = Offset(
      (constraints.maxWidth - totalWidth) / 2,
      (constraints.maxHeight - totalHeight) / 2,
    );

    // Position tubes manually for precise animation control
    return Stack(
      children: [
        // Static tubes - positioned manually
        for (int i = 0; i < tubeCount; i++)
          Positioned(
            left: _gridOffset.dx + (i % _tubesPerRow) * (_tubeWidth + _tubeSpacing),
            top: _gridOffset.dy + (i ~/ _tubesPerRow) * (_tubeHeight + _rowSpacing),
            child: _buildTube(context, i),
          ),
        // Animating balls overlay
        if (_animatingBalls != null && _moveAnimation != null)
          ..._animatingBalls!.map((ball) => AnimatedBuilder(
            animation: _moveAnimation!,
            builder: (context, child) {
              final t = _moveAnimation!.value;
              final x = ball.startX + (ball.endX - ball.startX) * t;
              // Arc motion: ball goes up then down
              final arcHeight = 40.0;
              final arc = -4 * arcHeight * t * (t - 1); // Parabola peaking at t=0.5
              final y = ball.startY + (ball.endY - ball.startY) * t - arc;
              return Positioned(
                left: x + (_tubeWidth - _ballSize) / 2,
                top: y,
                child: _buildBallWidget(ball.color, _ballSize, false),
              );
            },
          )),
      ],
    );
  }

  Widget _buildTube(BuildContext context, int tubeIndex) {
    final theme = Theme.of(context);
    final tube = widget.puzzle.currentState[tubeIndex];
    final isSelected = widget.selectedTube == tubeIndex;
    final isComplete = widget.puzzle.isTubeComplete(tubeIndex);

    // Hide TOP balls that are currently animating (they're shown in the overlay)
    final isAnimatingFrom = _animatingFromTube == tubeIndex && _animatingBalls != null;
    final ballsToHide = isAnimatingFrom ? _animatingBalls!.length : 0;

    // Check if this tube is a valid drop target
    bool isValidTarget = false;
    if (widget.selectedTube != null && widget.selectedTube != tubeIndex) {
      isValidTarget = widget.puzzle.canMoveTo(widget.selectedTube!, tubeIndex);
    }

    return GestureDetector(
      onTap: () => _handleTubeTap(tubeIndex),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: _tubeWidth,
        height: _tubeHeight,
        decoration: BoxDecoration(
          color: isComplete
              ? theme.colorScheme.primaryContainer.withAlpha(77)
              : theme.colorScheme.surface,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
          ),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : isValidTarget
                    ? theme.colorScheme.tertiary
                    : theme.colorScheme.outline.withAlpha(128),
            width: isSelected ? 3 : isValidTarget ? 2 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withAlpha(77),
                    blurRadius: 8,
                    spreadRadius: 2,
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Empty space at top for remaining capacity + space for hidden animating balls
            SizedBox(
              height: (widget.puzzle.tubeCapacity - tube.length) * _ballSize + 8 + (ballsToHide * _ballSize),
            ),
            // Balls (top to bottom in visual order, skipping the top N that are animating)
            // tube[length-1] is top, tube[0] is bottom
            // Skip indices from (length - ballsToHide) to (length - 1), show indices 0 to (length - ballsToHide - 1)
            for (int i = tube.length - 1 - ballsToHide; i >= 0; i--)
              Padding(
                padding: EdgeInsets.zero,
                child: _buildBall(
                  context,
                  tube[i],
                  _ballSize,
                  isTopBall: i == tube.length - 1 - ballsToHide,
                  isSelected: false, // Not selected during animation
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBall(
    BuildContext context,
    String colorName,
    double size,
    {bool isTopBall = false, bool isSelected = false}
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: size,
      height: size,
      transform: isSelected
          ? Matrix4.translationValues(0, -6, 0)
          : Matrix4.identity(),
      child: _buildBallWidget(colorName, size, isSelected),
    );
  }

  Widget _buildBallWidget(String colorName, double size, bool isSelected) {
    final color = _getBallColor(colorName);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.3),
          colors: [
            Color.lerp(color, Colors.white, 0.4)!,
            color,
            Color.lerp(color, Colors.black, 0.2)!,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(51),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
          if (isSelected)
            BoxShadow(
              color: color.withAlpha(128),
              blurRadius: 8,
              spreadRadius: 2,
            ),
        ],
      ),
    );
  }
}

class _AnimatingBall {
  final String color;
  final double startX;
  final double startY;
  final double endX;
  final double endY;

  _AnimatingBall({
    required this.color,
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
  });
}
