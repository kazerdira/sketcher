import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/sketch_controller.dart';
import '../../models/drawing_tool.dart';
import '../../models/brush_mode.dart';

class DrawingToolbar extends StatelessWidget {
  final VoidCallback? onColorTap;

  const DrawingToolbar({
    super.key,
    this.onColorTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: GetBuilder<SketchController>(
            builder: (controller) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      // Tool Selector (iPhone-style segmented control)
                      SizedBox(
                        width: 280, // Fixed width for tool selector
                        child: _buildToolSelector(controller),
                      ),
                      const SizedBox(width: 16),
                      // Color Picker Icon (Professional color palette access)
                      _buildColorPickerButton(controller),
                      const SizedBox(width: 16),
                      // Brush mode selector (shown only for Brush tool)
                      if (controller.currentTool.value == DrawingTool.brush)
                        _buildBrushModeSelector(controller),
                      const SizedBox(width: 16), // Extra space at the end
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // Modern iPhone-style segmented tool selector
  Widget _buildToolSelector(SketchController controller) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          _buildSegmentedButton(
            Icons.edit,
            'Pencil',
            controller.currentTool.value == DrawingTool.pencil,
            () => controller.setTool(DrawingTool.pencil),
          ),
          _buildSegmentedButton(
            Icons.create,
            'Pen',
            controller.currentTool.value == DrawingTool.pen,
            () => controller.setTool(DrawingTool.pen),
          ),
          _buildSegmentedButton(
            Icons.brush,
            'Marker',
            controller.currentTool.value == DrawingTool.marker,
            () => controller.setTool(DrawingTool.marker),
          ),
          _buildSegmentedButton(
            Icons.cleaning_services,
            'Eraser',
            controller.currentTool.value == DrawingTool.eraser,
            () => controller.setTool(DrawingTool.eraser),
          ),
          _buildSegmentedButton(
            Icons.brush_outlined,
            'Brush',
            controller.currentTool.value == DrawingTool.brush,
            () => controller.setTool(DrawingTool.brush),
          ),
        ],
      ),
    );
  }

  Widget _buildBrushModeSelector(SketchController controller) {
    final current = controller.currentBrushMode.value;
    return Semantics(
      label: 'Brush mode selector',
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(children: [
          Tooltip(
            message: 'Basic Brush',
            child: ChoiceChip(
              key: const Key('brush-mode-basic'),
              label: const Text('Basic'),
              selected: current == null,
              onSelected: (_) => controller.setBrushMode(null),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Charcoal Brush',
            child: ChoiceChip(
              key: const Key('brush-mode-charcoal'),
              label: const Text('Charcoal'),
              selected: current == BrushMode.charcoal,
              onSelected: (_) => controller.setBrushMode(BrushMode.charcoal),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Watercolor Brush',
            child: ChoiceChip(
              key: const Key('brush-mode-watercolor'),
              label: const Text('Watercolor'),
              selected: current == BrushMode.watercolor,
              onSelected: (_) => controller.setBrushMode(BrushMode.watercolor),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Calligraphy Brush',
            child: ChoiceChip(
              key: const Key('brush-mode-calligraphy'),
              label: const Text('Calligraphy'),
              selected: current == BrushMode.calligraphy,
              onSelected: (_) => controller.setBrushMode(BrushMode.calligraphy),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Pastel Brush',
            child: ChoiceChip(
              key: const Key('brush-mode-pastel'),
              label: const Text('Pastel'),
              selected: current == BrushMode.pastel,
              onSelected: (_) => controller.setBrushMode(BrushMode.pastel),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Oil Paint Brush',
            child: ChoiceChip(
              key: const Key('brush-mode-oil'),
              label: const Text('Oil'),
              selected: current == BrushMode.oilPaint,
              onSelected: (_) => controller.setBrushMode(BrushMode.oilPaint),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildSegmentedButton(
    IconData icon,
    String tooltip,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue[600] : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              size: 20,
              color: isSelected ? Colors.white : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }

  // Professional color picker button
  Widget _buildColorPickerButton(SketchController controller) {
    return GestureDetector(
      onTap: onColorTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: controller.currentColor.value,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey[300]!, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.palette,
          color: controller.currentColor.value.computeLuminance() > 0.5
              ? Colors.grey[700]
              : Colors.white,
          size: 20,
        ),
      ),
    );
  }
}
