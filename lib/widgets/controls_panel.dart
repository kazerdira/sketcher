import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/sketch_controller.dart';
import '../models/stroke.dart';

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

            // Brush type selector
            _buildBrushTypeSelector(),

            const SizedBox(height: 8),

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
                  () => _buildColorButton(color, c.selectedColor == color),
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
      onTap: () => c.setBrushColor(color),
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
              const Icon(Icons.line_weight, size: 18),
              const SizedBox(width: 8),
              const Text('Brush Size'),
              const Spacer(),
              Text(
                '${c.brushSize.toStringAsFixed(1)}px',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          Row(
            children: [
              Icon(
                Icons.radio_button_unchecked,
                size: 8 + (c.minBrushSize * 2),
              ),
              Expanded(
                child: Slider(
                  value: c.brushSize.clamp(c.minBrushSize, c.maxBrushSize),
                  min: c.minBrushSize,
                  max: c.maxBrushSize,
                  divisions: ((c.maxBrushSize - c.minBrushSize) * 2).round(),
                  onChanged: (v) => c.setBrushSize(v),
                ),
              ),
              Icon(Icons.circle, size: 8 + (c.maxBrushSize * 0.8)),
            ],
          ),
          // Show brush type specific range
          Text(
            '${c.selectedBrushType.name}: ${c.minBrushSize.toStringAsFixed(1)} - ${c.maxBrushSize.toStringAsFixed(1)}px',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  /// Build brush type selector
  Widget _buildBrushTypeSelector() {
    final SketchController c = Get.find();

    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.brush, size: 18),
              const SizedBox(width: 8),
              const Text('Brush Type'),
              const Spacer(),
              Text(
                c.selectedBrushType.name,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Brush type buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: BrushType.values.map((brushType) {
                final isSelected = c.selectedBrushType == brushType;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildBrushTypeButton(brushType, isSelected),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Build individual brush type button
  Widget _buildBrushTypeButton(BrushType brushType, bool selected) {
    final SketchController c = Get.find();

    return GestureDetector(
      onTap: () => c.selectBrushType(brushType),
      child: Container(
        width: 60,
        height: 50,
        decoration: BoxDecoration(
          color: selected ? Colors.blue.shade50 : Colors.grey.shade100,
          border: Border.all(
            color: selected ? Colors.blue : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              brushType.icon,
              size: 20,
              color: selected ? Colors.blue : Colors.grey.shade600,
            ),
            const SizedBox(height: 2),
            Text(
              brushType.name,
              style: TextStyle(
                fontSize: 10,
                color: selected ? Colors.blue : Colors.grey.shade600,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pressure Simulation'),
                Text(
                  c.isPressureSupported
                      ? 'Vary line thickness based on drawing speed'
                      : 'Not supported by ${c.selectedBrushType.name}',
                  style: TextStyle(
                    fontSize: 12,
                    color: c.isPressureSupported ? Colors.grey : Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: c.pressureSimEnabled.value && c.isPressureSupported,
            onChanged: c.isPressureSupported
                ? (v) => c.pressureSimEnabled.value = v
                : null,
          ),
        ],
      ),
    );
  }
}
