import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'controllers/sketch_controller.dart';
import 'widgets/drawing_canvas.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Ensure a clean state for hot restarts/tests
  if (Get.isRegistered<SketchController>()) {
    Get.delete<SketchController>(force: true);
  }

  // Set preferred orientations
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(SketchApp());
}

class SketchApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Professional Sketcher',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
      ),
      home: const SketchScreen(),
      initialBinding: SketchBinding(),
    );
  }
}

class SketchBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<SketchController>(SketchController());
  }
}

class SketchScreen extends StatelessWidget {
  const SketchScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: DrawingCanvas(),
    );
  }

  // ignore: unused_element
  void _handleMenuSelection(String value, SketchController controller) {
    switch (value) {
      case 'export':
        _exportDrawing(controller);
        break;
      case 'settings':
        _showSettings();
        break;
    }
  }

  // ignore: unused_element
  void _exportDrawing(SketchController controller) {
    if (controller.strokes.isEmpty) {
      Get.snackbar(
        'No Drawing',
        'Please draw something before exporting',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    // Show loading
    Get.dialog(
      const Center(
        child: CircularProgressIndicator(),
      ),
      barrierDismissible: false,
    );

    // Simulate export process
    Future.delayed(const Duration(seconds: 2), () {
      Get.back(); // Close loading dialog
      Get.snackbar(
        'Export Successful',
        'Drawing saved to gallery',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );
    });
  }

  // ignore: unused_element
  void _showSettings() {
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const ListTile(
              title: Text('About'),
              subtitle: Text('Professional Sketcher v1.0'),
              leading: Icon(Icons.info_outline),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }
}
