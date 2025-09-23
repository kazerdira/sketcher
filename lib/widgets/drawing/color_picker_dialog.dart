import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:get/get.dart';
import '../../controllers/sketch_controller.dart';

class ColorPickerDialog {
  static void showColorPicker(BuildContext context) {
    final controller = Get.find<SketchController>();
    Color selectedColor = controller.currentColor.value;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 420,
                  maxHeight: 600,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header with current color preview
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: selectedColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Color Picker',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  _getColorHex(selectedColor),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                            iconSize: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              // Professional Color Palette with Full Shades
                              _buildProfessionalColorPalette(selectedColor,
                                  (color) {
                                setState(() {
                                  selectedColor = color;
                                });
                              }),

                              const SizedBox(height: 16),

                              // Additional Custom Colors Section
                              const Text(
                                'Custom Colors',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildCustomColorsGrid(selectedColor, (color) {
                                setState(() {
                                  selectedColor = color;
                                });
                              }),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.grey[600],
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                controller.setColor(selectedColor);
                                Navigator.of(context).pop();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: selectedColor,
                                foregroundColor:
                                    selectedColor.computeLuminance() > 0.5
                                        ? Colors.black
                                        : Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Select Color'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  static void showHSVColorPicker(BuildContext context) {
    final controller = Get.find<SketchController>();
    Color selectedColor = controller.currentColor.value;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'HSV Color Picker',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 300,
              height: 400,
              child: ColorPicker(
                pickerColor: selectedColor,
                onColorChanged: (Color color) {
                  selectedColor = color;
                },
                colorPickerWidth: 300.0,
                pickerAreaHeightPercent: 0.7,
                enableAlpha: false,
                displayThumbColor: true,
                showLabel: false,
                paletteType: PaletteType.hsvWithHue,
                pickerAreaBorderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                controller.setColor(selectedColor);
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo[600],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Select'),
            ),
          ],
        );
      },
    );
  }

  static Widget _buildProfessionalColorPalette(
      Color selectedColor, Function(Color) onColorSelected) {
    // Base colors for generating complete shade ranges
    final baseColors = [
      Colors.red,
      Colors.pink,
      Colors.purple,
      Colors.deepPurple,
      Colors.indigo,
      Colors.blue,
      Colors.lightBlue,
      Colors.cyan,
      Colors.teal,
      Colors.green,
      Colors.lightGreen,
      Colors.lime,
      Colors.yellow,
      Colors.amber,
      Colors.orange,
      Colors.deepOrange,
      Colors.brown,
      Colors.grey,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Professional Color Palette',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),

        // Grayscale spectrum
        _buildColorRow(
            'Grayscale',
            [
              Colors.black,
              const Color(0xFF1C1C1C),
              const Color(0xFF2E2E2E),
              const Color(0xFF404040),
              const Color(0xFF525252),
              const Color(0xFF737373),
              const Color(0xFF949494),
              const Color(0xFFB6B6B6),
              const Color(0xFFD1D1D1),
              const Color(0xFFE8E8E8),
              const Color(0xFFF5F5F5),
              Colors.white,
            ],
            selectedColor,
            onColorSelected),

        const SizedBox(height: 8),

        // Color palette with complete shades (first 14 colors for better fit)
        ...baseColors.take(14).map((baseColor) {
          final colorName = _getColorName(baseColor);
          return _buildColorRow(
              colorName,
              [
                baseColor[900] ?? _adjustBrightness(baseColor, -0.4),
                baseColor[800] ?? _adjustBrightness(baseColor, -0.3),
                baseColor[700] ?? _adjustBrightness(baseColor, -0.2),
                baseColor[600] ?? _adjustBrightness(baseColor, -0.1),
                baseColor[500] ?? baseColor,
                baseColor[400] ?? _adjustBrightness(baseColor, 0.1),
                baseColor[300] ?? _adjustBrightness(baseColor, 0.2),
                baseColor[200] ?? _adjustBrightness(baseColor, 0.3),
                baseColor[100] ?? _adjustBrightness(baseColor, 0.4),
                baseColor[50] ?? _adjustBrightness(baseColor, 0.5),
              ],
              selectedColor,
              onColorSelected);
        }).toList(),
      ],
    );
  }

  static Widget _buildColorRow(String name, List<Color> colors,
      Color selectedColor, Function(Color) onColorSelected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: colors
            .map((color) =>
                _buildColorSwatch(color, selectedColor, onColorSelected))
            .toList(),
      ),
    );
  }

  static Widget _buildColorSwatch(
      Color color, Color selectedColor, Function(Color) onColorSelected) {
    final isSelected = _colorsEqual(selectedColor, color);
    return Expanded(
      child: GestureDetector(
        onTap: () => onColorSelected(color),
        child: Container(
          height: 22,
          margin: const EdgeInsets.only(right: 1),
          decoration: BoxDecoration(
            color: color,
            border: Border.all(
              color: isSelected
                  ? Colors.blue[600]!
                  : color == Colors.white
                      ? Colors.grey[300]!
                      : Colors.transparent,
              width: isSelected ? 2 : 0.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: isSelected
              ? Icon(
                  Icons.check,
                  color: color.computeLuminance() > 0.5
                      ? Colors.black87
                      : Colors.white,
                  size: 10,
                )
              : null,
        ),
      ),
    );
  }

  static Widget _buildCustomColorsGrid(
      Color selectedColor, Function(Color) onColorSelected) {
    // Additional vibrant and unique colors not in the main palette
    final customColors = [
      // Vibrant colors
      const Color(0xFF6A1B9A), // Deep Purple
      const Color(0xFF00695C), // Dark Cyan
      const Color(0xFFBF360C), // Deep Orange Red
      const Color(0xFF263238), // Blue Grey Dark
      const Color(0xFF827717), // Lime Dark
      const Color(0xFFE65100), // Orange Dark
      const Color(0xFF1A237E), // Indigo Dark
      const Color(0xFF880E4F), // Pink Dark
      const Color(0xFF006064), // Cyan Dark
      const Color(0xFF33691E), // Light Green Dark
      const Color(0xFFFF6F00), // Amber Dark
      const Color(0xFF4A148C), // Purple Dark

      // Soft pastels
      const Color(0xFFF8BBD9), // Light Pink
      const Color(0xFFE1BEE7), // Light Purple
      const Color(0xFFB39DDB), // Light Deep Purple
      const Color(0xFF9FA8DA), // Light Indigo
      const Color(0xFF90CAF9), // Light Blue
      const Color(0xFF81D4FA), // Light Light Blue
      const Color(0xFF80CBC4), // Light Cyan
      const Color(0xFFA5D6A7), // Light Green
      const Color(0xFFC5E1A5), // Light Light Green
      const Color(0xFFDCE775), // Light Lime
      const Color(0xFFFFF176), // Light Yellow
      const Color(0xFFFFCC02), // Light Amber

      // Rich earth tones
      const Color(0xFF8D6E63), // Brown
      const Color(0xFF795548), // Brown Dark
      const Color(0xFF6D4C41), // Brown Darker
      const Color(0xFF5D4037), // Brown Darkest
      const Color(0xFF8BC34A), // Light Green
      const Color(0xFF689F38), // Light Green Dark
    ];

    return GridView.count(
      crossAxisCount: 6,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      childAspectRatio: 1.0,
      children: customColors.map((color) {
        final isSelected = _colorsEqual(selectedColor, color);
        return GestureDetector(
          onTap: () => onColorSelected(color),
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected ? Colors.blue[600]! : Colors.grey[300]!,
                width: isSelected ? 2 : 0.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 1,
                        offset: const Offset(0, 0.5),
                      ),
                    ],
            ),
            child: isSelected
                ? Icon(
                    Icons.check,
                    color: color.computeLuminance() > 0.5
                        ? Colors.black87
                        : Colors.white,
                    size: 12,
                  )
                : null,
          ),
        );
      }).toList(),
    );
  }

  // Helper method to compare colors with tolerance for similar shades
  static bool _colorsEqual(Color color1, Color color2) {
    return (color1.red - color2.red).abs() < 5 &&
        (color1.green - color2.green).abs() < 5 &&
        (color1.blue - color2.blue).abs() < 5;
  }

  // Helper method to adjust color brightness
  static Color _adjustBrightness(Color color, double factor) {
    if (factor > 0) {
      // Lighten
      return Color.fromARGB(
        color.alpha,
        (color.red + (255 - color.red) * factor).round().clamp(0, 255),
        (color.green + (255 - color.green) * factor).round().clamp(0, 255),
        (color.blue + (255 - color.blue) * factor).round().clamp(0, 255),
      );
    } else {
      // Darken
      final positive = -factor;
      return Color.fromARGB(
        color.alpha,
        (color.red * (1 - positive)).round().clamp(0, 255),
        (color.green * (1 - positive)).round().clamp(0, 255),
        (color.blue * (1 - positive)).round().clamp(0, 255),
      );
    }
  }

  // Helper method to get color name
  static String _getColorName(MaterialColor color) {
    if (color == Colors.red) return 'Red';
    if (color == Colors.pink) return 'Pink';
    if (color == Colors.purple) return 'Purple';
    if (color == Colors.deepPurple) return 'Deep Purple';
    if (color == Colors.indigo) return 'Indigo';
    if (color == Colors.blue) return 'Blue';
    if (color == Colors.lightBlue) return 'Light Blue';
    if (color == Colors.cyan) return 'Cyan';
    if (color == Colors.teal) return 'Teal';
    if (color == Colors.green) return 'Green';
    if (color == Colors.lightGreen) return 'Light Green';
    if (color == Colors.lime) return 'Lime';
    if (color == Colors.yellow) return 'Yellow';
    if (color == Colors.amber) return 'Amber';
    if (color == Colors.orange) return 'Orange';
    if (color == Colors.deepOrange) return 'Deep Orange';
    if (color == Colors.brown) return 'Brown';
    if (color == Colors.grey) return 'Grey';
    return 'Color';
  }

  static String _getColorHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }
}
