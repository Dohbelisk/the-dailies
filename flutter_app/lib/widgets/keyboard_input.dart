import 'package:flutter/material.dart';

class KeyboardInput extends StatelessWidget {
  final Function(String) onLetterTap;
  final VoidCallback onDeleteTap;

  const KeyboardInput({
    super.key,
    required this.onLetterTap,
    required this.onDeleteTap,
  });

  static const _row1 = ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'];
  static const _row2 = ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'];
  static const _row3 = ['Z', 'X', 'C', 'V', 'B', 'N', 'M'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate responsive key size based on available width
          // Row 1 has 10 keys, which is the widest row (without delete)
          final availableWidth = constraints.maxWidth;

          // Calculate key width to fit 10 keys with small gaps
          // Each key gets a slot of (availableWidth / 10)
          final slotWidth = availableWidth / 10;
          final keyWidth = (slotWidth - 2).clamp(22.0, 32.0); // Leave 2px for gaps
          final keyHeight = (keyWidth * 1.4).clamp(30.0, 44.0);
          final fontSize = (keyWidth * 0.5).clamp(11.0, 16.0);

          return Column(
            children: [
              _buildRow(context, _row1, slotWidth, keyWidth, keyHeight, fontSize),
              const SizedBox(height: 4),
              _buildRow(context, _row2, slotWidth, keyWidth, keyHeight, fontSize),
              const SizedBox(height: 4),
              _buildRow(context, _row3, slotWidth, keyWidth, keyHeight, fontSize, includeDelete: true),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRow(BuildContext context, List<String> letters, double slotWidth, double keyWidth, double keyHeight, double fontSize, {bool includeDelete = false}) {
    final theme = Theme.of(context);

    // Calculate width for delete key (approximately 1.5x a regular key slot)
    final deleteWidth = slotWidth * 1.5;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ...letters.map((letter) => SizedBox(
          width: slotWidth,
          child: Center(
            child: _buildKey(context, letter, keyWidth, keyHeight, fontSize),
          ),
        )),
        if (includeDelete)
          SizedBox(
            width: deleteWidth,
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onDeleteTap,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    width: deleteWidth - 4,
                    height: keyHeight,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: theme.colorScheme.error.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      Icons.backspace_outlined,
                      size: fontSize * 1.25,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildKey(BuildContext context, String letter, double width, double height, double fontSize) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onLetterTap(letter),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              letter,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
