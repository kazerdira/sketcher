import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Provides platform specific saving of PNG images to gallery / photos.
class ImageExporter {
  // Updated channel name to reflect professional refactor
  static const MethodChannel _channel = MethodChannel(
    'professional_sketcher/image_export',
  );

  static Future<bool> saveToGallery(String filePath) async {
    if (!File(filePath).existsSync()) return false;
    try {
      final bool? result = await _channel.invokeMethod<bool>('saveToGallery', {
        'path': filePath,
        'albumName': 'Professional Sketches',
      });
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Save error: $e');
      return false;
    }
  }
}
