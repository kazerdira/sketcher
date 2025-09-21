import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../painters/sketch_painter.dart';
import '../models/stroke.dart';

/// Phase 4: Comprehensive Memory Management System
///
/// Handles automatic memory pressure detection, cache optimization,
/// and resource cleanup to prevent memory-related crashes.
class MemoryManager {
  // Memory limits for production stability
  static const int _maxStrokeCount = 1000;
  static const int _maxCacheSize = 50;
  static const int _criticalStrokeThreshold = 800;
  static const int _complexBrushThreshold = 100;

  // Cleanup intervals
  static const int _regularCleanupInterval = 20; // Every 20 strokes
  static const int _memoryCheckInterval = 50; // Every 50 strokes

  /// Handle critical memory pressure situations
  /// Aggressively clears all caches to free GPU memory
  static void handleMemoryPressure() {
    try {
      debugPrint('🧠 MemoryManager: Handling memory pressure');

      // Clear all caches aggressively
      SketchPainter.clearStrokeCache();
      SketchPainter.clearBoundsCache();

      // Force garbage collection hint
      // Note: Dart GC is automatic, but this signals memory pressure

      Get.snackbar(
        'Memory Optimization',
        'Freed memory caches to maintain performance',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      debugPrint('❌ MemoryManager: Memory pressure handling failed: $e');
    }
  }

  /// Manage stroke count to prevent memory exhaustion
  /// Removes oldest strokes when limit is exceeded
  static List<Stroke> manageStrokeCount(List<Stroke> strokes) {
    if (strokes.length <= _maxStrokeCount) {
      return strokes; // No action needed
    }

    try {
      final removeCount = strokes.length - _maxStrokeCount;
      debugPrint(
          '🧠 MemoryManager: Removing $removeCount old strokes (${strokes.length} → $_maxStrokeCount)');

      // Clean up caches for strokes being removed
      for (int i = 0; i < removeCount; i++) {
        final strokeToRemove = strokes[i];
        SketchPainter.cleanupStrokeCaches(strokeToRemove);
      }

      // Remove oldest strokes
      final updatedStrokes = strokes.sublist(removeCount);

      Get.snackbar(
        'Memory Optimization',
        'Removed $removeCount old strokes to maintain performance',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.TOP,
      );

      return updatedStrokes;
    } catch (e) {
      debugPrint('❌ MemoryManager: Stroke count management failed: $e');
      return strokes; // Return original on failure
    }
  }

  /// Check if memory pressure conditions exist
  /// Returns true if cleanup is recommended
  static bool shouldTriggerMemoryCleanup(List<Stroke> strokes) {
    try {
      // Count complex brush strokes (more memory intensive)
      final complexBrushCount = strokes
          .where((stroke) =>
              stroke.tool.toString().contains('brush') &&
              stroke.brushMode != null)
          .length;

      // Trigger cleanup conditions:
      return strokes.length > _criticalStrokeThreshold ||
          complexBrushCount > _complexBrushThreshold;
    } catch (e) {
      debugPrint('❌ MemoryManager: Memory check failed: $e');
      return false;
    }
  }

  /// Periodic memory optimization
  /// Should be called regularly during drawing sessions
  static void optimizeMemoryUsage(List<Stroke> strokes) {
    try {
      debugPrint('🧠 MemoryManager: Running periodic optimization');

      // Optimize caches
      SketchPainter.optimizeCaches();

      // Check for memory pressure
      if (shouldTriggerMemoryCleanup(strokes)) {
        handleMemoryPressure();
      }
    } catch (e) {
      debugPrint('❌ MemoryManager: Memory optimization failed: $e');
    }
  }

  /// Get memory usage recommendations
  static String getMemoryStatus(List<Stroke> strokes) {
    try {
      final complexBrushCount = strokes
          .where((stroke) =>
              stroke.tool.toString().contains('brush') &&
              stroke.brushMode != null)
          .length;

      if (strokes.length > _criticalStrokeThreshold) {
        return 'High memory usage - cleanup recommended';
      } else if (complexBrushCount > _complexBrushThreshold) {
        return 'Complex brushes detected - monitoring memory';
      } else if (strokes.length > (_maxStrokeCount * 0.7)) {
        return 'Moderate memory usage';
      } else {
        return 'Normal memory usage';
      }
    } catch (e) {
      debugPrint('❌ MemoryManager: Status check failed: $e');
      return 'Memory status unknown';
    }
  }

  /// Emergency cleanup when memory is critically low
  /// More aggressive than regular cleanup
  static void emergencyMemoryCleanup() {
    try {
      debugPrint('🚨 MemoryManager: EMERGENCY cleanup triggered');

      // Clear all caches immediately
      SketchPainter.clearStrokeCache();
      SketchPainter.clearBoundsCache();

      Get.snackbar(
        '⚠️ Emergency Cleanup',
        'Memory critically low - cleared all caches',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.TOP,
      );
    } catch (e) {
      debugPrint('❌ MemoryManager: Emergency cleanup failed: $e');
    }
  }

  /// Check if regular cleanup should be triggered
  static bool shouldRunRegularCleanup(int strokeCount) {
    return strokeCount > 0 && strokeCount % _regularCleanupInterval == 0;
  }

  /// Check if memory pressure check should be triggered
  static bool shouldRunMemoryCheck(int strokeCount) {
    return strokeCount > 0 && strokeCount % _memoryCheckInterval == 0;
  }
}
