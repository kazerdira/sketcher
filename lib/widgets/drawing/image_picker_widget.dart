import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/sketch_controller.dart';

class ImagePickerWidget {
  static void showImagePicker(BuildContext context) {
    final controller = Get.find<SketchController>();

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromGallery(controller);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFromCamera(controller);
                },
              ),
              if (controller.backgroundImage.value != null)
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('Remove Background'),
                  onTap: () {
                    Navigator.pop(context);
                    controller.setBackgroundImage(null);
                    controller.isImageVisible.value = false;
                    controller.update();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  static Future<void> _pickFromGallery(SketchController controller) async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;

      final bytes = await picked.readAsBytes();

      // Phase 2: Use async image loading instead of direct setState
      // The async loader will handle disposal and proper loading
      controller.setBackgroundImage(MemoryImage(bytes));
      controller.isImageVisible.value = true;
    } catch (e) {
      Get.snackbar(
        'Image Error',
        'Failed to load image: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  static Future<void> _pickFromCamera(SketchController controller) async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(source: ImageSource.camera);
      if (picked == null) return;

      final bytes = await picked.readAsBytes();

      // Phase 2: Use async image loading instead of direct setState
      // The async loader will handle disposal and proper loading
      controller.setBackgroundImage(MemoryImage(bytes));
      controller.isImageVisible.value = true;
    } catch (e) {
      Get.snackbar(
        'Camera Error',
        'Failed to capture image: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }
}
