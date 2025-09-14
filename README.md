# Professional Sketching App

Modern sketching aid: import a reference photo, adjust its transparency, draw on top with a smooth brush, toggle reference visibility, undo/clear strokes, and export only your sketch layer (transparent PNG) to the device gallery. Now powered by **GetX** for lightweight reactive state & modular structure.

## Features

Core:
* Import image from device gallery
* Adjustable image opacity (0% – 100%) & visibility toggle (restores last opacity)
* Smooth freehand drawing (quadratic bezier smoothing)
* Color palette (15 curated swatches + white)
* Adjustable brush size (1px – 20px)
* Undo history (50 snapshots) / Clear all strokes
* Export drawing layer only (transparent PNG)
* Zoom & Pan (pinch with two fingers; single finger to draw)

Architecture & Quality:
* Reactive state via GetX (`SketchController`)
* Modular file layout (models / controllers / painters / services)
* High‑resolution export (tries 4.0 → 3.0 → 2.0 pixel ratio fallback)
* Pressure simulation (velocity-based) – opt-in via toggle
* Non-blocking export feedback

## Tech Stack & Packages

| Purpose | Package |
|---------|---------|
| State management | get |
| Image picking | image_picker |
| Temp file path | path_provider |
| Native gallery save | Custom MethodChannel (Android MediaStore) |

## Run Instructions

Prerequisites: Latest stable Flutter SDK installed.

```bash
flutter pub get
flutter run
```

Select a device/emulator; app launches to main sketch screen.

## Usage

1. Tap the photo icon (top bar) to import a reference image.
2. Adjust its opacity with the "Image Opacity" slider.
3. Pick a brush color from the palette chips.
4. Adjust brush thickness with the Brush slider.
5. Draw directly over the canvas.
6. Use Undo (↶) to remove last stroke, trash icon to clear all.
7. Toggle visibility (eye icon) to hide/show the reference.
8. Export (download icon) to save only the drawing layer (PNG with transparency). Snackbar confirms success.

## Export Notes

Only strokes are captured; the reference photo layer is excluded (transparent background). If no strokes exist, export is skipped with a message. On Android a custom native `MethodChannel` writes the PNG to `Pictures/Sketches` via `MediaStore` (scoped storage compliant). No third‑party gallery saver plugin is used.

## Platform Permissions

Image picking and gallery saving may require runtime permissions (Android: READ / WRITE media; iOS: Photos). Configure as needed in `AndroidManifest.xml` and `Info.plist` depending on target SDK policies.

## Code Overview

| File | Role |
|------|------|
| `lib/main.dart` | App bootstrap + screen composition + widgets |
| `lib/controllers/sketch_controller.dart` | GetX reactive state (strokes, image, export) |
| `lib/models/stroke.dart` | Stroke data model (points, width, color, pressures) |
| `lib/painters/sketch_painter.dart` | CustomPainter for strokes (Bezier smoothing) |
| `lib/image_exporter.dart` | Platform channel wrapper for gallery save |

Rendering path: gestures → controller stroke mutation → `GetBuilder`/`Obx` triggers repaint → `SketchPainter` rebuild.

## Potential Enhancements (Future)

* Layers & layer panel (visibility / reordering)
* Eraser & blend modes (multiply, overlay)
* True stylus pressure / tilt support (PointerEvents / platform channels)
* Redo stack (mirror undoHistory)
* Session persistence (serialize strokes + image ref)
* Shape tools (rectangle / ellipse / line) with snapping
* Off‑main‑thread raster cache for very large stroke counts

## License

Prototype code provided as-is for internal / educational use.
