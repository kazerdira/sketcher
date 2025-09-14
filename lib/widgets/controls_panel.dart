import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/sketch_controller.dart';

/// Controls panel for brush settings, color palette, and drawing options
class ControlsPanel extends StatelessWidget {
  const ControlsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final SketchController c = Get.find();

    return Obx(() {
      if (!c.controlsVisible.value) {
        return const SizedBox.shrink();
      }

      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image opacity control (only shown when image is loaded)
            _buildImageOpacityControl(),

            // Color palette
            _buildColorPalette(),

            const SizedBox(height: 8),

            // Brush size control
            _buildBrushSizeControl(),

            const SizedBox(height: 8),

            // Pressure simulation toggle
            _buildPressureSimControl(),
          ],
        ),
      );
    });
  }

  /// Build image opacity control slider
  Widget _buildImageOpacityControl() {
    final SketchController c = Get.find();

    return Obx(() {
      if (c.baseImageFile.value == null) {
        return const SizedBox.shrink();
      }

      return Column(
        children: [
          Row(
            children: [
              const Text('Image Opacity'),
              const Spacer(),
              Text('${(c.imageOpacity.value * 100).round()}%'),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: c.imageOpacity.value,
                  min: 0,
                  max: 1,
                  onChanged: c.imageVisible.value
                      ? (v) => c.imageOpacity.value = v
                      : null,
                ),
              ),
              IconButton(
                onPressed: c.toggleImageVisibility,
                icon: Icon(
                  c.imageVisible.value
                      ? Icons.visibility
                      : Icons.visibility_off,
                ),
                tooltip: c.imageVisible.value ? 'Hide Image' : 'Show Image',
              ),
            ],
          ),
          const Divider(),
        ],
      );
    });
  }

  /// Build color palette grid
  Widget _buildColorPalette() {
    final SketchController c = Get.find();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Colors', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: c.palette
              .map(
                (color) => Obx(
                  () =>
                      _buildColorButton(color, c.selectedColor.value == color),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  /// Build individual color button
  Widget _buildColorButton(Color color, bool selected) {
    final SketchController c = Get.find();

    return InkWell(
      onTap: () => c.selectedColor.value = color,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(
            color: selected ? Colors.blue : Colors.grey.shade300,
            width: selected ? 3 : 2,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.6),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: selected
            ? const Icon(Icons.check, color: Colors.white, size: 18)
            : null,
      ),
    );
  }

  /// Build brush size control slider
  Widget _buildBrushSizeControl() {
    final SketchController c = Get.find();

    return Obx(
      () => Column(
        children: [
          Row(
            children: [
              const Icon(Icons.brush, size: 18),
              const SizedBox(width: 8),
              const Text('Brush Size'),
              const Spacer(),
              Text(
                c.brushSize.value.toStringAsFixed(1),
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.radio_button_unchecked, size: 12),
              Expanded(
                child: Slider(
                  value: c.brushSize.value,
                  min: 1,
                  max: 20,
                  divisions: 19,
                  onChanged: (v) => c.brushSize.value = v,
                ),
              ),
              const Icon(Icons.circle, size: 20),
            ],
          ),
        ],
      ),
    );
  }

  /// Build pressure simulation toggle
  Widget _buildPressureSimControl() {
    final SketchController c = Get.find();

    return Obx(
      () => Row(
        children: [
          const Icon(Icons.speed, size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pressure Simulation'),
                Text(
                  'Vary line thickness based on drawing speed',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Switch(
            value: c.pressureSimEnabled.value,
            onChanged: (v) => c.pressureSimEnabled.value = v,
          ),
        ],
      ),
    );
  }
}
