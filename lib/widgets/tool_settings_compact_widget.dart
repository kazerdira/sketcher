import 'package:flutter/material.dart';
import '../models/drawing_tool.dart';
import '../controllers/enhanced_sketch_controller.dart';

class ToolSettingsCompactWidget extends StatefulWidget {
  final EnhancedSketchController controller;
  final bool showAdvanced;
  final VoidCallback? onToggleAdvanced;

  const ToolSettingsCompactWidget({
    super.key,
    required this.controller,
    this.showAdvanced = false,
    this.onToggleAdvanced,
  });

  @override
  State<ToolSettingsCompactWidget> createState() =>
      _ToolSettingsCompactWidgetState();
}

class _ToolSettingsCompactWidgetState extends State<ToolSettingsCompactWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        final settings = widget.controller.currentToolSettings;

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Quick tools row
              _buildQuickToolsRow(settings),

              // Expandable section
              if (_isExpanded) ...[
                const Divider(),
                _buildExpandedSettings(settings),
              ],

              // Bottom safe area
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickToolsRow(ToolSettings settings) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Tool selector
          Expanded(
            flex: 3,
            child: SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: DrawingTool.values.length,
                itemBuilder: (context, index) {
                  final tool = DrawingTool.values[index];
                  final isSelected = tool == settings.tool;

                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildToolButton(tool, isSelected),
                  );
                },
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Size control
          Expanded(
            flex: 2,
            child: _buildQuickSlider(
              'Size',
              settings.size,
              1.0,
              50.0,
              (value) => widget.controller.updateToolProperty('size', value),
              icon: Icons.line_weight,
            ),
          ),

          const SizedBox(width: 8),

          // Color button
          _buildColorButton(settings.color),

          const SizedBox(width: 8),

          // Expand button
          IconButton(
            onPressed: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
            style: IconButton.styleFrom(
              backgroundColor: _isExpanded
                  ? Theme.of(context).primaryColor.withOpacity(0.1)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(DrawingTool tool, bool isSelected) {
    return Material(
      color: isSelected
          ? Theme.of(context).primaryColor
          : Colors.grey.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () => widget.controller.setTool(tool),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 48,
          height: 48,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getToolIcon(tool),
                size: 20,
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).iconTheme.color,
              ),
              const SizedBox(height: 2),
              Text(
                _getToolAbbreviation(tool),
                style: TextStyle(
                  fontSize: 8,
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickSlider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged, {
    IconData? icon,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16),
              const SizedBox(width: 4),
            ],
            Expanded(child: Text(label, style: const TextStyle(fontSize: 12))),
            Text(
              value.round().toString(),
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 24,
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: onChanged,
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
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: currentColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: currentColor.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.palette,
          color: _getContrastColor(currentColor),
          size: 20,
        ),
      ),
    );
  }

  Widget _buildExpandedSettings(ToolSettings settings) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Tabs for basic and advanced
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Basic'),
              Tab(text: 'Advanced'),
            ],
          ),

          const SizedBox(height: 16),

          SizedBox(
            height: 200,
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildBasicSettings(settings),
                _buildAdvancedSettings(settings),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicSettings(ToolSettings settings) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Opacity
          _buildMobileSlider(
            'Opacity',
            settings.opacity,
            0.0,
            1.0,
            (value) => widget.controller.updateToolProperty('opacity', value),
            percentage: true,
          ),

          const SizedBox(height: 16),

          // Flow (for applicable tools)
          if (_showFlowControl(settings.tool))
            _buildMobileSlider(
              'Flow',
              settings.flow,
              0.0,
              1.0,
              (value) => widget.controller.updateToolProperty('flow', value),
              percentage: true,
            ),

          if (_showFlowControl(settings.tool)) const SizedBox(height: 16),

          // Hardness (for applicable tools)
          if (_showHardnessControl(settings.tool))
            _buildMobileSlider(
              'Hardness',
              settings.hardness,
              0.0,
              1.0,
              (value) =>
                  widget.controller.updateToolProperty('hardness', value),
              percentage: true,
            ),

          if (_showHardnessControl(settings.tool)) const SizedBox(height: 16),

          // Color palette
          _buildColorPalette(settings.color),
        ],
      ),
    );
  }

  Widget _buildAdvancedSettings(ToolSettings settings) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Spacing
          _buildMobileSlider(
            'Spacing',
            settings.spacing,
            0.01,
            1.0,
            (value) => widget.controller.updateToolProperty('spacing', value),
            percentage: true,
          ),

          const SizedBox(height: 16),

          // Toggles
          Row(
            children: [
              Expanded(
                child: _buildToggleCard(
                  'Pressure',
                  'Pressure sensitive',
                  Icons.touch_app,
                  settings.pressureSensitive,
                  (value) => widget.controller.updateToolProperty(
                    'pressureSensitive',
                    value,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildToggleCard(
                  'Anti-alias',
                  'Smooth edges',
                  Icons.auto_fix_high,
                  settings.antiAlias,
                  (value) =>
                      widget.controller.updateToolProperty('antiAlias', value),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileSlider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged, {
    bool percentage = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                percentage
                    ? '${(value * 100).round()}%'
                    : value.toStringAsFixed(1),
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: percentage ? 100 : null,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildToggleCard(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Material(
      color: value
          ? Theme.of(context).primaryColor.withOpacity(0.1)
          : Colors.grey.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(
                icon,
                color: value ? Theme.of(context).primaryColor : Colors.grey,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: value ? Theme.of(context).primaryColor : null,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorPalette(Color currentColor) {
    final colors = [
      Colors.black,
      Colors.grey[800]!,
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
          'Colors',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colors.map((color) {
            final isSelected = color.value == currentColor.value;
            return GestureDetector(
              onTap: () => widget.controller.updateToolProperty('color', color),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: color.withOpacity(0.5),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        color: _getContrastColor(color),
                        size: 16,
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showColorPicker(Color currentColor) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: _buildColorPalette(currentColor),
      ),
    );
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

  String _getToolAbbreviation(DrawingTool tool) {
    switch (tool) {
      case DrawingTool.pencil:
        return 'PEN';
      case DrawingTool.pen:
        return 'INK';
      case DrawingTool.marker:
        return 'MRK';
      case DrawingTool.eraser:
        return 'ERA';
      case DrawingTool.brush:
        return 'BRU';
    }
  }

  Color _getContrastColor(Color color) {
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}
