import 'package:flutter/material.dart';
import '../models/game_models.dart';

class BallSortGrid extends StatelessWidget {
  final BallSortPuzzle puzzle;
  final int? selectedTube;
  final int undosRemaining;
  final Function(int tubeIndex) onTubeTap;
  final VoidCallback onUndo;
  final VoidCallback onReset;

  const BallSortGrid({
    super.key,
    required this.puzzle,
    required this.selectedTube,
    required this.undosRemaining,
    required this.onTubeTap,
    required this.onUndo,
    required this.onReset,
  });

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

  Color _getBallColor(String colorName) {
    return _ballColors[colorName.toLowerCase()] ?? Colors.grey;
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
                    'Moves: ${puzzle.moveCount}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Optimal: ${puzzle.minMoves}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              // Control buttons
              Row(
                children: [
                  // Undo button
                  FilledButton.tonal(
                    onPressed: puzzle.moveHistory.isEmpty || undosRemaining <= 0
                        ? null
                        : onUndo,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.undo, size: 18),
                        const SizedBox(width: 4),
                        Text('$undosRemaining'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Reset button
                  IconButton.outlined(
                    onPressed: puzzle.moveCount == 0 ? null : onReset,
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
    final theme = Theme.of(context);
    final tubeCount = puzzle.tubeCount;

    // Calculate tube dimensions
    // We want tubes to be arranged in rows, with max 6 tubes per row
    final tubesPerRow = tubeCount <= 6 ? tubeCount : (tubeCount / 2).ceil();
    final rows = (tubeCount / tubesPerRow).ceil();

    final maxTubeWidth = (constraints.maxWidth - (tubesPerRow - 1) * 8) / tubesPerRow;
    final tubeWidth = maxTubeWidth.clamp(40.0, 60.0);
    final ballSize = tubeWidth * 0.85;
    final tubeHeight = ballSize * puzzle.tubeCapacity + 20;

    final totalHeight = rows * (tubeHeight + 20);
    final availableHeight = constraints.maxHeight;
    final scale = availableHeight < totalHeight ? availableHeight / totalHeight : 1.0;

    final scaledTubeWidth = tubeWidth * scale;
    final scaledBallSize = ballSize * scale;
    final scaledTubeHeight = tubeHeight * scale;

    return Center(
      child: SingleChildScrollView(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 8 * scale,
          runSpacing: 20 * scale,
          children: [
            for (int i = 0; i < tubeCount; i++)
              _buildTube(
                context,
                i,
                scaledTubeWidth,
                scaledTubeHeight,
                scaledBallSize,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTube(
    BuildContext context,
    int tubeIndex,
    double tubeWidth,
    double tubeHeight,
    double ballSize,
  ) {
    final theme = Theme.of(context);
    final tube = puzzle.currentState[tubeIndex];
    final isSelected = selectedTube == tubeIndex;
    final isComplete = puzzle.isTubeComplete(tubeIndex);

    // Check if this tube is a valid drop target
    bool isValidTarget = false;
    if (selectedTube != null && selectedTube != tubeIndex) {
      isValidTarget = puzzle.canMoveTo(selectedTube!, tubeIndex);
    }

    return GestureDetector(
      onTap: () => onTubeTap(tubeIndex),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: tubeWidth,
        height: tubeHeight,
        decoration: BoxDecoration(
          color: isComplete
              ? theme.colorScheme.primaryContainer.withOpacity(0.3)
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
                    : theme.colorScheme.outline.withOpacity(0.5),
            width: isSelected ? 3 : isValidTarget ? 2 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Balls (bottom to top)
            for (int i = 0; i < tube.length; i++)
              _buildBall(
                context,
                tube[i],
                ballSize,
                isTopBall: i == tube.length - 1,
                isSelected: isSelected && i == tube.length - 1,
              ),
            // Empty space for remaining capacity
            SizedBox(
              height: (puzzle.tubeCapacity - tube.length) * ballSize + 10,
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
    final color = _getBallColor(colorName);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: size,
      height: size,
      margin: EdgeInsets.only(
        bottom: 2,
        top: isSelected ? 0 : 2,
      ),
      transform: isSelected
          ? Matrix4.translationValues(0, -8, 0)
          : Matrix4.identity(),
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
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
          if (isSelected)
            BoxShadow(
              color: color.withOpacity(0.5),
              blurRadius: 8,
              spreadRadius: 2,
            ),
        ],
      ),
    );
  }
}
