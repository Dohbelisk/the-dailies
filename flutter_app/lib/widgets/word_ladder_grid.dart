import 'package:flutter/material.dart';
import '../models/game_models.dart';
import 'keyboard_input.dart';

class WordLadderGrid extends StatefulWidget {
  final WordLadderPuzzle puzzle;
  final String currentInput;
  final Function(String) onLetterTap;
  final VoidCallback onDeleteTap;
  final VoidCallback onSubmit;
  final VoidCallback onUndo;
  final VoidCallback onReset;
  final String? message;
  final bool? messageSuccess;

  const WordLadderGrid({
    super.key,
    required this.puzzle,
    required this.currentInput,
    required this.onLetterTap,
    required this.onDeleteTap,
    required this.onSubmit,
    required this.onUndo,
    required this.onReset,
    this.message,
    this.messageSuccess,
  });

  @override
  State<WordLadderGrid> createState() => _WordLadderGridState();
}

class _WordLadderGridState extends State<WordLadderGrid> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _gapKey = GlobalKey();
  int _prevStartLen = 0;
  int _prevTargetLen = 0;

  @override
  void initState() {
    super.initState();
    _prevStartLen = widget.puzzle.pathFromStart.length;
    _prevTargetLen = widget.puzzle.pathFromTarget.length;
    _scrollToGapAfterBuild();
  }

  @override
  void didUpdateWidget(WordLadderGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newStartLen = widget.puzzle.pathFromStart.length;
    final newTargetLen = widget.puzzle.pathFromTarget.length;
    if (newStartLen != _prevStartLen || newTargetLen != _prevTargetLen) {
      _prevStartLen = newStartLen;
      _prevTargetLen = newTargetLen;
      _scrollToGapAfterBuild();
    }
  }

  void _scrollToGapAfterBuild() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToGap();
    });
  }

  void _scrollToGap() {
    final gapContext = _gapKey.currentContext;
    if (gapContext == null || !_scrollController.hasClients) return;

    final scrollBox = _scrollController.position.context.storageContext.findRenderObject();
    final gapBox = gapContext.findRenderObject();
    if (scrollBox == null || gapBox == null) return;

    final gapBoxRendered = gapBox as RenderBox;
    final scrollBoxRendered = scrollBox as RenderBox;

    // Get the gap's position relative to the scroll view
    final gapOffset = gapBoxRendered.localToGlobal(Offset.zero, ancestor: scrollBoxRendered);
    final gapHeight = gapBoxRendered.size.height;
    final viewportHeight = _scrollController.position.viewportDimension;

    // Calculate where we want to scroll: center the gap in the viewport
    final gapCenter = _scrollController.offset + gapOffset.dy + gapHeight / 2;
    final targetOffset = (gapCenter - viewportHeight / 2).clamp(
      _scrollController.position.minScrollExtent,
      _scrollController.position.maxScrollExtent,
    );

    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Info bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Steps: ${widget.puzzle.currentSteps}',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  FilledButton.tonal(
                    onPressed: (widget.puzzle.pathFromStart.length <= 1 && widget.puzzle.pathFromTarget.length <= 1) ? null : widget.onUndo,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.undo, size: 18),
                        SizedBox(width: 4),
                        Text('Undo'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    onPressed: (widget.puzzle.pathFromStart.length <= 1 && widget.puzzle.pathFromTarget.length <= 1) ? null : widget.onReset,
                    icon: const Icon(Icons.refresh, size: 20),
                    tooltip: 'Reset puzzle',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Word ladder display
        Expanded(
          child: _buildLadder(context),
        ),

        // Input area
        Padding(
          padding: const EdgeInsets.all(16),
          child: _buildInputArea(context),
        ),
      ],
    );
  }

  Widget _buildLadder(BuildContext context) {
    final theme = Theme.of(context);
    final puzzle = widget.puzzle;

    return SingleChildScrollView(
      controller: _scrollController,
      child: Column(
        children: [
          // Target path (building down from target)
          // Show in reverse order so target is at top
          for (int i = 0; i < puzzle.pathFromTarget.length; i++) ...[
            _buildWordCard(
              context,
              puzzle.pathFromTarget[i],
              isTarget: i == 0,
              isStart: false,
              isCurrent: i == puzzle.pathFromTarget.length - 1 && puzzle.pathFromTarget.length > 1,
            ),
            if (i < puzzle.pathFromTarget.length - 1) ...[
              Icon(
                Icons.arrow_downward,
                size: 20,
                color: theme.colorScheme.tertiary,
              ),
            ],
          ],

          // Gap between paths (if not complete)
          if (!puzzle.isComplete) ...[
            Column(
              key: _gapKey,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                for (int i = 0; i < 3; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.outline.withAlpha(77),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ] else ...[
            Icon(
              key: _gapKey,
              Icons.arrow_downward,
              size: 20,
              color: theme.colorScheme.primary,
            ),
          ],

          // Start path (building up from start)
          // Show in reverse order so most recent is at top (closest to target)
          for (int i = puzzle.pathFromStart.length - 1; i >= 0; i--) ...[
            _buildWordCard(
              context,
              puzzle.pathFromStart[i],
              isTarget: false,
              isStart: i == 0,
              isCurrent: i == puzzle.pathFromStart.length - 1 && puzzle.pathFromStart.length > 1,
            ),
            if (i > 0) ...[
              Icon(
                Icons.arrow_downward,
                size: 20,
                color: theme.colorScheme.primary,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildWordCard(
    BuildContext context,
    String word, {
    required bool isTarget,
    required bool isStart,
    required bool isCurrent,
  }) {
    final theme = Theme.of(context);

    Color bgColor;
    if (isTarget) {
      bgColor = theme.colorScheme.primaryContainer;
    } else if (isStart) {
      bgColor = theme.colorScheme.secondaryContainer;
    } else if (isCurrent) {
      bgColor = theme.colorScheme.tertiaryContainer;
    } else {
      bgColor = theme.colorScheme.surfaceContainerHigh;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: (isTarget || isCurrent)
            ? Border.all(
                color: theme.colorScheme.primary,
                width: 2,
              )
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < word.length; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Container(
              width: 36,
              height: 44,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  word[i],
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInputArea(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Message display
        if (widget.message != null && widget.message!.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: widget.messageSuccess == true
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.message!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: widget.messageSuccess == true
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onErrorContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        // Current input display
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(
                'Enter next word (change one letter)',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Letter boxes for input
                  for (int i = 0; i < widget.puzzle.wordLength; i++) ...[
                    if (i > 0) const SizedBox(width: 6),
                    Container(
                      width: 44,
                      height: 52,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: i < widget.currentInput.length
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline.withAlpha(128),
                          width: i < widget.currentInput.length ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          i < widget.currentInput.length ? widget.currentInput[i] : '',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 16),
                  // Add button
                  FilledButton(
                    onPressed: widget.currentInput.length == widget.puzzle.wordLength
                        ? widget.onSubmit
                        : null,
                    child: const Text('Add'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Keyboard
        KeyboardInput(
          onLetterTap: widget.onLetterTap,
          onDeleteTap: widget.onDeleteTap,
        ),
      ],
    );
  }
}
