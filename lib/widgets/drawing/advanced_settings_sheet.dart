import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/sketch_controller.dart';
import 'color_picker_dialog.dart';
import 'image_picker_widget.dart';

class AdvancedSettingsSheet {
  static void showAdvancedSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AdvancedSettingsPanel(),
    );
  }
}

class _AdvancedSettingsPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: GetBuilder<SketchController>(
            builder: (controller) {
              return Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Text(
                          'Brush Settings',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                  // Settings content
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildModernSlider(
                            'Brush Size',
                            controller.brushSize.value,
                            1.0,
                            50.0,
                            (value) => controller.setBrushSize(value),
                            Icons.brush,
                            sliderKey: const Key('brush-size-slider-modal'),
                          ),
                          const SizedBox(height: 24),
                          _buildModernSlider(
                            'Stroke Opacity',
                            controller.toolOpacity.value,
                            0.0,
                            1.0,
                            (value) => controller.setOpacity(value),
                            Icons.opacity,
                            sliderKey: const Key('stroke-opacity-slider-modal'),
                          ),
                          if (controller.backgroundImage.value != null) ...[
                            const SizedBox(height: 24),
                            _buildModernSlider(
                              'Image Opacity',
                              controller.imageOpacity.value,
                              0.0,
                              1.0,
                              (value) => controller.setImageOpacity(value),
                              Icons.image,
                              sliderKey:
                                  const Key('image-opacity-slider-modal'),
                            ),
                          ],
                          const SizedBox(height: 32),
                          _buildColorSection(context, controller),
                          const SizedBox(height: 24),
                          _buildInputSection(controller),
                          const SizedBox(height: 32),
                          _buildActionSection(context, controller),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildModernSlider(String label, double value, double min, double max,
      Function(double) onChanged, IconData icon,
      {Key? sliderKey, bool compact = false}) {
    return Builder(
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!compact) ...[
            Row(
              children: [
                Icon(icon, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    value.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.blue[600],
              inactiveTrackColor: Colors.grey[300],
              thumbColor: Colors.blue[600],
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
              trackHeight: 4,
            ),
            child: Slider(
              key: sliderKey,
              value: value,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorSection(BuildContext context, SketchController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.palette, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 8),
            const Text(
              'Color',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Current color display with professional picker
        GestureDetector(
          onTap: () => ColorPickerDialog.showColorPicker(context),
          child: Container(
            width: double.infinity,
            height: 60,
            decoration: BoxDecoration(
              color: controller.currentColor.value,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.colorize,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Tap to Pick Color',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getColorHex(controller.currentColor.value),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Quick action buttons for color
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Color Picker',
                Icons.colorize,
                Colors.purple,
                () => ColorPickerDialog.showColorPicker(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'HSV Picker',
                Icons.tune,
                Colors.indigo,
                () => ColorPickerDialog.showHSVColorPicker(context),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInputSection(SketchController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.gesture, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 8),
            const Text(
              'Input',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: SwitchListTile.adaptive(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            title: const Text('Stylus-only (Palm rejection)'),
            subtitle: const Text(
                'Ignore finger touches for drawing; still allow two-finger pan/zoom.'),
            value: controller.stylusOnlyMode.value,
            onChanged: controller.setStylusOnlyMode,
            secondary: const Icon(Icons.edit),
          ),
        ),
      ],
    );
  }

  Widget _buildActionSection(
      BuildContext context, SketchController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Save Sketch',
                Icons.save_alt,
                Colors.green,
                () => _saveSketch(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Background',
                Icons.image,
                Colors.blue,
                () => ImagePickerWidget.showImagePicker(context),
              ),
            ),
          ],
        ),
        if (controller.backgroundImage.value != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  controller.isImageVisible.value ? 'Hide Image' : 'Show Image',
                  controller.isImageVisible.value
                      ? Icons.visibility_off
                      : Icons.visibility,
                  Colors.orange,
                  controller.toggleImageVisibility,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionCard(
                  'Remove Image',
                  Icons.close,
                  Colors.red,
                  () {
                    controller.setBackgroundImage(null);
                    controller.isImageVisible.value = false;
                    controller.update();
                    Navigator.pop(context);
                  },
                  key: const Key('remove-background-button'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildActionCard(
      String title, IconData icon, Color color, VoidCallback onTap,
      {Key? key}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        key: key,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveSketch(BuildContext context) async {
    try {
      // TODO: This needs access to the RepaintBoundary key from the main widget
      // For now, show a message about the save functionality
      Get.snackbar(
        'Save Feature',
        'Save functionality needs to be implemented with proper RepaintBoundary access',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        'Save Error',
        'Failed to save sketch: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  String _getColorHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }
}
