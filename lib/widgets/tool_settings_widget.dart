import 'package:flutter/material.dart';
import '../models/drawing_tool.dart';
import '../controllers/enhanced_sketch_controller.dart';

class ToolSettingsWidget extends StatelessWidget {
  final EnhancedSketchController controller;
  final bool compact;
  final VoidCallback? onClose;

  const ToolSettingsWidget({
    super.key,
    required this.controller,
    this.compact = false,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        final settings = controller.currentToolSettings;

        if (compact) {
          return _buildCompactView(context, settings);
        } else {
          return _buildFullView(context, settings);
        }
      },
    );
  }

  Widget _buildFullView(BuildContext context, ToolSettings settings) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border.all(color: Theme.of(context).dividerColor, width: 1),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getToolIcon(settings.tool),
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  _getToolName(settings.tool),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (onClose != null)
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onClose,
                    iconSize: 20,
                  ),
              ],
            ),
          ),

          // Tool selector
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tool',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildToolSelector(),
                const SizedBox(height: 24),

                // Size
                _buildSliderSetting(
                  'Size',
                  settings.size,
                  1.0,
                  50.0,
                  (value) => controller.updateToolProperty('size', value),
                ),

                // Opacity
                _buildSliderSetting(
                  'Opacity',
                  settings.opacity,
                  0.0,
                  1.0,
                  (value) => controller.updateToolProperty('opacity', value),
                  percentage: true,
                ),

                // Flow (for applicable tools)
                if (_showFlowControl(settings.tool))
                  _buildSliderSetting(
                    'Flow',
                    settings.flow,
                    0.0,
                    1.0,
                    (value) => controller.updateToolProperty('flow', value),
                    percentage: true,
                  ),

                // Hardness (for applicable tools)
                if (_showHardnessControl(settings.tool))
                  _buildSliderSetting(
                    'Hardness',
                    settings.hardness,
                    0.0,
                    1.0,
                    (value) => controller.updateToolProperty('hardness', value),
                    percentage: true,
                  ),

                // Spacing
                _buildSliderSetting(
                  'Spacing',
                  settings.spacing,
                  0.01,
                  1.0,
                  (value) => controller.updateToolProperty('spacing', value),
                  percentage: true,
                ),

                const SizedBox(height: 16),

                // Color picker
                _buildColorPicker(settings.color),

                const SizedBox(height: 16),

                // Advanced settings
                _buildAdvancedSettings(settings),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactView(BuildContext context, ToolSettings settings) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tool selector (compact)
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: DrawingTool.values.map((tool) {
                final isSelected = tool == settings.tool;
                return Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: IconButton(
                    onPressed: () => controller.setTool(tool),
                    icon: Icon(_getToolIcon(tool)),
                    style: IconButton.styleFrom(
                      backgroundColor: isSelected
                          ? Theme.of(context).primaryColor
                          : null,
                      foregroundColor: isSelected ? Colors.white : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          // Quick settings
          Row(
            children: [
              Expanded(
                child: _buildCompactSlider(
                  'Size',
                  settings.size,
                  1.0,
                  50.0,
                  (value) => controller.updateToolProperty('size', value),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildCompactSlider(
                  'Opacity',
                  settings.opacity,
                  0.0,
                  1.0,
                  (value) => controller.updateToolProperty('opacity', value),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Color and pressure toggle
          Row(
            children: [
              Expanded(child: _buildColorButton(settings.color)),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => controller.updateToolProperty(
                  'pressureSensitive',
                  !settings.pressureSensitive,
                ),
                icon: Icon(
                  settings.pressureSensitive
                      ? Icons.touch_app
                      : Icons.touch_app_outlined,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: settings.pressureSensitive
                      ? Theme.of(context).primaryColor.withOpacity(0.2)
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToolSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: DrawingTool.values.map((tool) {
        final isSelected = tool == controller.currentToolSettings.tool;
        return Material(
          color: isSelected ? Colors.blue : Colors.grey.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: () => controller.setTool(tool),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getToolIcon(tool),
                    size: 16,
                    color: isSelected ? Colors.white : null,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getToolName(tool),
                    style: TextStyle(
                      color: isSelected ? Colors.white : null,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSliderSetting(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged, {
    bool percentage = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
              Text(
                percentage
                    ? '${(value * 100).round()}%'
                    : value.toStringAsFixed(1),
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: percentage ? 100 : null,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSlider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10)),
        SizedBox(
          height: 20,
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildColorPicker(Color currentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Color', style: TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _showColorPicker(currentColor),
          child: Container(
            height: 40,
            width: double.infinity,
            decoration: BoxDecoration(
              color: currentColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: Center(
              child: Text(
                'Tap to change color',
                style: TextStyle(
                  color: _getContrastColor(currentColor),
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorButton(Color currentColor) {
    return GestureDetector(
      onTap: () => _showColorPicker(currentColor),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: currentColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.withOpacity(0.3), width: 2),
        ),
      ),
    );
  }

  Widget _buildAdvancedSettings(ToolSettings settings) {
    return ExpansionTile(
      title: const Text(
        'Advanced Settings',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      children: [
        CheckboxListTile(
          title: const Text('Pressure Sensitive'),
          subtitle: const Text('Respond to stylus pressure'),
          value: settings.pressureSensitive,
          onChanged: (value) => controller.updateToolProperty(
            'pressureSensitive',
            value ?? false,
          ),
        ),
        CheckboxListTile(
          title: const Text('Anti-aliasing'),
          subtitle: const Text('Smooth edge rendering'),
          value: settings.antiAlias,
          onChanged: (value) =>
              controller.updateToolProperty('antiAlias', value ?? true),
        ),
      ],
    );
  }

  void _showColorPicker(Color currentColor) {
    // TODO: Implement color picker dialog
    // For now, cycle through some preset colors
    final colors = [
      Colors.black,
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.brown,
      Colors.grey,
    ];

    final currentIndex = colors.indexWhere(
      (c) => c.value == currentColor.value,
    );
    final nextIndex = (currentIndex + 1) % colors.length;
    controller.updateToolProperty('color', colors[nextIndex]);
  }

  bool _showFlowControl(DrawingTool tool) {
    return tool == DrawingTool.brush || tool == DrawingTool.marker;
  }

  bool _showHardnessControl(DrawingTool tool) {
    return tool == DrawingTool.brush || tool == DrawingTool.eraser;
  }

  IconData _getToolIcon(DrawingTool tool) {
    switch (tool) {
      case DrawingTool.pencil:
        return Icons.edit;
      case DrawingTool.pen:
        return Icons.create;
      case DrawingTool.marker:
        return Icons.brush;
      case DrawingTool.eraser:
        return Icons.auto_fix_normal;
      case DrawingTool.brush:
        return Icons.format_paint;
    }
  }

  String _getToolName(DrawingTool tool) {
    switch (tool) {
      case DrawingTool.pencil:
        return 'Pencil';
      case DrawingTool.pen:
        return 'Pen';
      case DrawingTool.marker:
        return 'Marker';
      case DrawingTool.eraser:
        return 'Eraser';
      case DrawingTool.brush:
        return 'Brush';
    }
  }

  Color _getContrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
