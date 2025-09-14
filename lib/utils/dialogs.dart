import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/sketch_controller.dart';

/// Utility class for dialogs and snackbars
class DialogUtils {
  /// Show a snackbar with the given message
  static void showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Show confirmation dialog for clearing all strokes
  static void showClearConfirmation(BuildContext context) {
    final SketchController c = Get.find();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear All Strokes'),
          content: const Text(
            'Are you sure you want to clear all drawing strokes? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                c.clear();
                showSnack(context, 'All strokes cleared');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade100,
                foregroundColor: Colors.red.shade700,
              ),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );
  }

  /// Show an export progress dialog
  static void showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Exporting image...'),
            ],
          ),
        );
      },
    );
  }

  /// Show image selection source dialog
  static Future<ImageSource?> showImageSourceDialog(BuildContext context) {
    return showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}

/// Extension to access ImageSource from image_picker
enum ImageSource { gallery, camera }
