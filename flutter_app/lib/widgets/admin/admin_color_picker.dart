import 'package:flutter/material.dart';

/// Reusable color picker widget for admin editors (Ball Sort, Pipes)
class AdminColorPicker extends StatelessWidget {
  final String? selectedColor;
  final void Function(String color) onColorSelect;
  final List<String> colors;

  const AdminColorPicker({
    super.key,
    required this.onColorSelect,
    this.selectedColor,
    this.colors = defaultColors,
  });

  static const List<String> defaultColors = [
    'red',
    'blue',
    'green',
    'yellow',
    'purple',
    'orange',
    'pink',
    'cyan',
    'lime',
    'brown',
  ];

  Color _getColor(String name) {
    switch (name.toLowerCase()) {
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'yellow':
        return Colors.yellow;
      case 'purple':
        return Colors.purple;
      case 'orange':
        return Colors.orange;
      case 'pink':
        return Colors.pink;
      case 'cyan':
        return Colors.cyan;
      case 'lime':
        return Colors.lime;
      case 'brown':
        return Colors.brown;
      case 'grey':
      case 'gray':
        return Colors.grey;
      case 'white':
        return Colors.white;
      case 'black':
        return Colors.black;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: colors.map((color) {
        final isSelected = selectedColor == color;
        return GestureDetector(
          onTap: () => onColorSelect(color),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _getColor(color),
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 3,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: _getColor(color).withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      )
                    ]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }
}
