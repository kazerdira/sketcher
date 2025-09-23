import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/sketch_controller.dart';
import '../../models/drawing_tool.dart';
import '../../models/brush_mode.dart';
import '../common/pro_slider.dart';

class InlineControls extends StatefulWidget {
  final VoidCallback onImagePicker;
  final VoidCallback onAdvancedSettings;
  final bool controlsExpanded;
  final ValueChanged<bool> onControlsToggle;

  const InlineControls({
    super.key,
    required this.onImagePicker,
    required this.onAdvancedSettings,
    required this.controlsExpanded,
    required this.onControlsToggle,
  });

  @override
  State<InlineControls> createState() => _InlineControlsState();
}

class _InlineControlsState extends State<InlineControls> {
  Widget _buildInlineControls() {
    return GetBuilder<SketchController>(builder: (controller) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: SafeArea(
          top: false,
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.6)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Material(
                    type: MaterialType.transparency,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top row: arrow toggle + quick actions
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _glassIconButton(
                              icon: widget.controlsExpanded
                                  ? Icons.keyboard_arrow_down
                                  : Icons.keyboard_arrow_up,
                              tooltip: widget.controlsExpanded
                                  ? 'Hide Sliders'
                                  : 'Show Sliders',
                              onTap: () => widget
                                  .onControlsToggle(!widget.controlsExpanded),
                              key: const Key('toggle-sliders-button'),
                            ),
                            const SizedBox(width: 12),
                            // Image and editing action buttons grouped together
                            if (controller.backgroundImage.value != null) ...[
                              _glassIconButton(
                                icon: Icons.close,
                                tooltip: 'Remove Image',
                                key: const Key('remove-background-button'),
                                color: Colors.red,
                                onTap: () {
                                  controller.setBackgroundImage(null);
                                  controller.isImageVisible.value = false;
                                  controller.update();
                                },
                              ),
                              _divider(),
                            ],
                            _glassIconButton(
                              icon: Icons.image,
                              tooltip: 'Background',
                              onTap: widget.onImagePicker,
                            ),
                            const SizedBox(width: 12),
                            _glassIconButton(
                              icon: Icons.undo,
                              tooltip: 'Undo',
                              onTap: controller.undo,
                              key: const Key('undo-button'),
                            ),
                            const SizedBox(width: 8),
                            _glassIconButton(
                              icon: Icons.clear,
                              tooltip: 'Clear',
                              onTap: controller.clear,
                              key: const Key('clear-button'),
                            ),
                            const SizedBox(width: 8),
                            _glassIconButton(
                              icon: Icons.settings,
                              tooltip: 'Settings',
                              onTap: widget.onAdvancedSettings,
                              key: const Key('settings-button'),
                            ),
                            const Spacer(),
                          ],
                        ),
                        // Collapsible sliders area (vertical with Syncfusion)
                        AnimatedSize(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeInOut,
                          child: ClipRect(
                            child: Align(
                              alignment: Alignment.topCenter,
                              heightFactor: widget.controlsExpanded ? 1.0 : 0.0,
                              child: Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 280),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      ProSlider(
                                        label: 'Brush Size',
                                        value: controller.brushSize.value,
                                        min: 1.0,
                                        max: 50.0,
                                        onChanged: (v) =>
                                            controller.setBrushSize(v),
                                        icon: Icons.brush,
                                        sliderKey:
                                            const Key('brush-size-slider'),
                                      ),
                                      const SizedBox(height: 12),
                                      ProSlider(
                                        label: 'Stroke Opacity',
                                        value: controller.toolOpacity.value,
                                        min: 0.0,
                                        max: 1.0,
                                        onChanged: (v) =>
                                            controller.setOpacity(v),
                                        icon: Icons.opacity,
                                        sliderKey:
                                            const Key('stroke-opacity-slider'),
                                      ),
                                      // Brush-specific tuning
                                      if (controller.currentTool.value ==
                                              DrawingTool.brush &&
                                          controller.currentBrushMode.value ==
                                              BrushMode.calligraphy) ...[
                                        const SizedBox(height: 12),
                                        ProSlider(
                                          label: 'Nib Angle (°)',
                                          value: controller
                                              .calligraphyNibAngleDeg.value,
                                          min: 0.0,
                                          max: 90.0,
                                          onChanged: (v) => controller
                                              .setCalligraphyNibAngle(v),
                                          icon: Icons.rotate_right,
                                          sliderKey: const Key(
                                              'calligraphy-nib-angle-slider'),
                                        ),
                                        const SizedBox(height: 12),
                                        ProSlider(
                                          label: 'Nib Width Factor',
                                          value: controller
                                              .calligraphyNibWidthFactor.value,
                                          min: 0.3,
                                          max: 2.5,
                                          onChanged: (v) => controller
                                              .setCalligraphyNibWidthFactor(v),
                                          icon: Icons.format_size,
                                          sliderKey: const Key(
                                              'calligraphy-nib-width-slider'),
                                        ),
                                      ],
                                      if (controller.currentTool.value ==
                                              DrawingTool.brush &&
                                          controller.currentBrushMode.value ==
                                              BrushMode.pastel) ...[
                                        const SizedBox(height: 12),
                                        ProSlider(
                                          label: 'Grain Density',
                                          value: controller
                                              .pastelGrainDensity.value,
                                          min: 0.3,
                                          max: 3.0,
                                          onChanged: (v) => controller
                                              .setPastelGrainDensity(v),
                                          icon: Icons.grain,
                                          sliderKey: const Key(
                                              'pastel-grain-density-slider'),
                                        ),
                                      ],
                                      if (controller.backgroundImage.value !=
                                          null) ...[
                                        const SizedBox(height: 12),
                                        ProSlider(
                                          label: 'Image Opacity',
                                          value: controller.imageOpacity.value,
                                          min: 0.0,
                                          max: 1.0,
                                          onChanged: (v) =>
                                              controller.setImageOpacity(v),
                                          icon: Icons.image,
                                          sliderKey:
                                              const Key('image-opacity-slider'),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _divider() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      width: 1,
      height: 28,
      color: Colors.black.withOpacity(0.06),
    );
  }

  Widget _glassIconButton({
    required IconData icon,
    required String tooltip,
    VoidCallback? onTap,
    Color? color,
    Key? key,
  }) {
    final iconColor = color ?? Colors.grey[700]!;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          key: key,
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.55),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.7)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildInlineControls();
  }
}
