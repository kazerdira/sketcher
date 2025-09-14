import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/sketch_controller.dart';
import '../utils/dialogs.dart';

/// Professional app bar with menu actions and context-aware UI
class SketchAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SketchAppBar({super.key, required this.onExport});

  final VoidCallback onExport;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final SketchController c = Get.find();

    return AppBar(
      title: const Text('Professional Sketcher'),
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      actions: [
        // Import Image
        IconButton(
          onPressed: c.pickImage,
          icon: const Icon(Icons.image),
          tooltip: 'Import Image',
        ),

        // Undo
        Obx(
          () => IconButton(
            onPressed: c.undoHistory.isNotEmpty ? c.undo : null,
            icon: Icon(
              Icons.undo,
              color: c.undoHistory.isNotEmpty ? null : Colors.grey,
            ),
            tooltip: 'Undo',
          ),
        ),

        // Export
        Obx(
          () => IconButton(
            onPressed: c.strokes.isNotEmpty ? onExport : null,
            icon: Icon(
              Icons.save_alt,
              color: c.strokes.isNotEmpty ? null : Colors.grey,
            ),
            tooltip: 'Export',
          ),
        ),

        // More actions menu
        GetBuilder<SketchController>(
          builder: (controller) => PopupMenuButton<String>(
            onSelected: (action) => _handleMenuAction(context, action),
            itemBuilder: (context) => _buildMenuItems(controller),
            icon: const Icon(Icons.more_vert),
            tooltip: 'More options',
          ),
        ),
      ],
    );
  }

  void _handleMenuAction(BuildContext context, String action) {
    final SketchController c = Get.find();

    switch (action) {
      case 'clear':
        if (c.strokes.isNotEmpty) {
          DialogUtils.showClearConfirmation(context);
        }
        break;
      case 'reset_view':
        c.resetView();
        break;
      case 'toggle_controls':
        c.controlsVisible.toggle();
        break;
      case 'add_layer':
        // Future feature: Add new drawing layer
        DialogUtils.showSnack(context, 'Layer feature coming soon!');
        break;
      case 'save_project':
        // Future feature: Save project
        DialogUtils.showSnack(context, 'Save project feature coming soon!');
        break;
      case 'settings':
        // Future feature: Settings
        DialogUtils.showSnack(context, 'Settings feature coming soon!');
        break;
    }
  }

  List<PopupMenuEntry<String>> _buildMenuItems(SketchController c) {
    return [
      PopupMenuItem<String>(
        value: 'clear',
        enabled: c.strokes.isNotEmpty,
        child: Row(
          children: [
            Icon(
              Icons.delete_outline,
              color: c.strokes.isNotEmpty ? null : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(
              'Clear All',
              style: TextStyle(
                color: c.strokes.isNotEmpty ? null : Colors.grey,
              ),
            ),
          ],
        ),
      ),
      const PopupMenuItem<String>(
        value: 'reset_view',
        child: Row(
          children: [
            Icon(Icons.center_focus_strong),
            SizedBox(width: 8),
            Text('Reset View'),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'toggle_controls',
        child: Row(
          children: [
            Icon(
              c.controlsVisible.value
                  ? Icons.keyboard_arrow_down
                  : Icons.keyboard_arrow_up,
            ),
            const SizedBox(width: 8),
            Text(c.controlsVisible.value ? 'Hide Controls' : 'Show Controls'),
          ],
        ),
      ),
      const PopupMenuDivider(),
      const PopupMenuItem<String>(
        value: 'add_layer',
        child: Row(
          children: [Icon(Icons.layers), SizedBox(width: 8), Text('Add Layer')],
        ),
      ),
      const PopupMenuItem<String>(
        value: 'save_project',
        child: Row(
          children: [
            Icon(Icons.save),
            SizedBox(width: 8),
            Text('Save Project'),
          ],
        ),
      ),
      const PopupMenuItem<String>(
        value: 'settings',
        child: Row(
          children: [
            Icon(Icons.settings),
            SizedBox(width: 8),
            Text('Settings'),
          ],
        ),
      ),
    ];
  }
}
