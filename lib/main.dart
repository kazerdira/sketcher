import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'controllers/enhanced_sketch_controller.dart';
import 'widgets/enhanced_canvas_widget.dart';
import 'widgets/tool_settings_widget.dart';
import 'widgets/tool_settings_compact_widget.dart';
import 'models/drawing_tool.dart';
import 'image_exporter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() {
  runApp(const ProfessionalSketchingApp());
}

class ProfessionalSketchingApp extends StatelessWidget {
  const ProfessionalSketchingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Professional Sketching App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MainSketchPage(),
    );
  }
}

class MainSketchPage extends StatefulWidget {
  const MainSketchPage({super.key});

  @override
  State<MainSketchPage> createState() => _MainSketchPageState();
}

class _MainSketchPageState extends State<MainSketchPage> {
  late final EnhancedSketchController _controller;
  final GlobalKey<State<EnhancedCanvasWidget>> _canvasKey = GlobalKey();
  final EnhancedCanvasController _canvasController = EnhancedCanvasController();

  bool _showToolSettings = false;
  bool _isCompactMode = false;
  ui.Image? _backgroundImage;
  bool _showBackgroundImage = false;
  double _backgroundOpacity = 0.5;

  @override
  void initState() {
    super.initState();
    _controller = EnhancedSketchController();

    // Set initial tool
    _controller.setTool(DrawingTool.pencil);

    // Check if we're on mobile for compact mode
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final size = MediaQuery.of(context).size;
      setState(() {
        _isCompactMode = size.width < 600; // Mobile/tablet threshold
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: _buildAppBar(),
      body: _isCompactMode
          ? _buildMobileLayout()
          : _buildDesktopLayout(isLandscape),
      bottomSheet: _isCompactMode ? _buildBottomSheet() : null,
      floatingActionButton: _isCompactMode ? null : _buildFloatingActions(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Professional Sketching'),
      elevation: 2,
      actions: [
        // Tool info
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Center(
            child: Text(
              _getToolName(_controller.currentToolSettings.tool),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
        ),

        // Undo
        IconButton(
          onPressed: _controller.canUndo ? _controller.undo : null,
          icon: const Icon(Icons.undo),
          tooltip: 'Undo',
        ),

        // Redo
        IconButton(
          onPressed: _controller.canRedo ? _controller.redo : null,
          icon: const Icon(Icons.redo),
          tooltip: 'Redo',
        ),

        // Clear
        IconButton(
          onPressed: _controller.hasStrokes ? _showClearDialog : null,
          icon: const Icon(Icons.clear),
          tooltip: 'Clear all',
        ),

        // Settings
        if (!_isCompactMode)
          IconButton(
            onPressed: () {
              setState(() {
                _showToolSettings = !_showToolSettings;
              });
            },
            icon: Icon(
              _showToolSettings ? Icons.settings : Icons.settings_outlined,
            ),
            tooltip: 'Tool settings',
          ),

        // Menu
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'export',
              child: ListTile(
                leading: Icon(Icons.save_alt),
                title: Text('Export Image'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'import',
              child: ListTile(
                leading: Icon(Icons.image),
                title: Text('Import Background'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'stats',
              child: ListTile(
                leading: Icon(Icons.analytics),
                title: Text('Drawing Statistics'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuItem(
              value: 'about',
              child: ListTile(
                leading: Icon(Icons.info),
                title: Text('About'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return EnhancedCanvasWidget(
      key: _canvasKey,
      controller: _controller,
      backgroundImage: _backgroundImage,
      showImage: _showBackgroundImage,
      imageOpacity: _backgroundOpacity,
      externalController: _canvasController,
    );
  }

  Widget _buildDesktopLayout(bool isLandscape) {
    if (isLandscape) {
      return Row(
        children: [
          // Tool settings sidebar
          if (_showToolSettings)
            Container(
              width: 300,
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: Colors.grey.shade300)),
              ),
              child: ToolSettingsWidget(
                controller: _controller,
                onClose: () {
                  setState(() {
                    _showToolSettings = false;
                  });
                },
              ),
            ),

          // Main canvas
          Expanded(
            child: EnhancedCanvasWidget(
              key: _canvasKey,
              controller: _controller,
              backgroundImage: _backgroundImage,
              showImage: _showBackgroundImage,
              imageOpacity: _backgroundOpacity,
              externalController: _canvasController,
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          // Tool settings panel
          if (_showToolSettings)
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: ToolSettingsWidget(
                controller: _controller,
                compact: true,
                onClose: () {
                  setState(() {
                    _showToolSettings = false;
                  });
                },
              ),
            ),

          // Main canvas
          Expanded(
            child: EnhancedCanvasWidget(
              key: _canvasKey,
              controller: _controller,
              backgroundImage: _backgroundImage,
              showImage: _showBackgroundImage,
              imageOpacity: _backgroundOpacity,
              externalController: _canvasController,
            ),
          ),
        ],
      );
    }
  }

  Widget? _buildBottomSheet() {
    return ToolSettingsCompactWidget(
      controller: _controller,
      showAdvanced: _showToolSettings,
      onToggleAdvanced: () {
        setState(() {
          _showToolSettings = !_showToolSettings;
        });
      },
    );
  }

  Widget _buildFloatingActions() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Zoom to fit
        FloatingActionButton.small(
          heroTag: 'zoom_fit',
          onPressed: _canvasController.zoomToFit,
          child: const Icon(Icons.zoom_out_map),
          tooltip: 'Zoom to fit',
        ),

        const SizedBox(height: 8),

        // Center canvas
        FloatingActionButton.small(
          heroTag: 'center',
          onPressed: _canvasController.centerCanvas,
          child: const Icon(Icons.center_focus_strong),
          tooltip: 'Center canvas',
        ),

        const SizedBox(height: 8),

        // Reset zoom
        FloatingActionButton.small(
          heroTag: 'reset_zoom',
          onPressed: _canvasController.resetZoom,
          child: const Icon(Icons.zoom_out),
          tooltip: 'Reset zoom',
        ),
      ],
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export':
        _exportDrawing();
        break;
      case 'import':
        _importBackground();
        break;
      case 'stats':
        _showStatistics();
        break;
      case 'about':
        _showAbout();
        break;
    }
  }

  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Drawing'),
        content: const Text(
          'This will clear all your drawing. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _controller.clearAll();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Drawing cleared')));
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _exportDrawing() {
    if (!_controller.hasStrokes) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nothing to export')));
      return;
    }
    _doExport();
  }

  void _importBackground() {
    _doImportBackground();
  }

  void _showStatistics() {
    final stats = _controller.getDrawingStatistics();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Drawing Statistics'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total Strokes: ${stats['totalStrokes']}'),
              Text('Total Points: ${stats['totalPoints']}'),
              Text(
                'Drawing Time: ${stats['totalDrawingTime'].toStringAsFixed(1)}s',
              ),
              Text(
                'Average Stroke Length: ${stats['averageStrokeLength'].toStringAsFixed(1)}px',
              ),
              Text(
                'Average Points per Stroke: ${stats['averagePointsPerStroke'].toStringAsFixed(1)}',
              ),
              const SizedBox(height: 16),
              const Text(
                'Tool Usage:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...((stats['toolUsage'] as Map<String, int>).entries.map(
                    (entry) => Text('${entry.key}: ${entry.value} strokes'),
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'Professional Sketching App',
      applicationVersion: '2.0.0',
      applicationIcon: const Icon(Icons.brush, size: 48),
      children: [
        const Text(
          'A professional drawing application with realistic brush tools:',
        ),
        const SizedBox(height: 8),
        const Text('• Pencil - Textured, pressure-sensitive graphite'),
        const Text('• Pen - Smooth, precise ink strokes'),
        const Text('• Marker - Translucent, blended strokes'),
        const Text('• Eraser - Clean removal tool'),
        const Text('• Brush - Soft, artistic painting'),
        const SizedBox(height: 8),
        const Text(
          'Features pressure sensitivity, velocity tracking, and professional-grade controls.',
        ),
      ],
    );
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

  Future<void> _doExport() async {
    try {
      final image = await _canvasController.captureImage(pixelRatio: 3.0);
      if (image == null) return;
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      // On mobile, save to gallery; on desktop, show Save dialog
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        final dir = await getTemporaryDirectory();
        final path =
            '${dir.path}/sketch_${DateTime.now().millisecondsSinceEpoch}.png';
        final file = File(path);
        await file.writeAsBytes(byteData.buffer.asUint8List());
        await ImageExporter.saveToGallery(file.path);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Saved to gallery')),
          );
        }
      } else {
        final result = await FilePicker.platform.saveFile(
          dialogTitle: 'Save sketch as PNG',
          type: FileType.custom,
          allowedExtensions: ['png'],
          fileName: 'sketch_${DateTime.now().millisecondsSinceEpoch}.png',
        );
        if (result == null) return; // cancelled
        final file = File(result);
        await file.writeAsBytes(byteData.buffer.asUint8List());
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Exported successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> _doImportBackground() async {
    try {
      Uint8List? data;
      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        final picker = ImagePicker();
        final XFile? picked =
            await picker.pickImage(source: ImageSource.gallery);
        if (picked == null) return;
        data = await picked.readAsBytes();
      } else {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
          withData: true,
        );
        if (result == null) return; // cancelled
        final fileBytes = result.files.single.bytes;
        final path = result.files.single.path;
        data = fileBytes;
        if (data == null && path != null) {
          data = await File(path).readAsBytes();
        }
        if (data == null) return;
      }

      final codec = await ui.instantiateImageCodec(data);
      final frame = await codec.getNextFrame();
      setState(() {
        _backgroundImage = frame.image;
        _showBackgroundImage = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Background imported')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
    }
  }
}
