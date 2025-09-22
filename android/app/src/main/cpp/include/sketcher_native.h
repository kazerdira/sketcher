#ifndef SKETCHER_NATIVE_H
#define SKETCHER_NATIVE_H

#ifdef _WIN32
#define SKETCHER_EXPORT __declspec(dllexport)
#else
#define SKETCHER_EXPORT __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

// Point data structure for FFI
typedef struct {
    double x;
    double y;
    double pressure;
    double timestamp;
    double tiltX;
    double tiltY;
} PointData;

// Calligraphy segment data for rendering
typedef struct {
    double x1, y1;
    double x2, y2;
    double thickness;
    double alpha;
} CalligraphySegment;

// Vertex structure for mesh rendering
typedef struct {
    double x;
    double y;
    double alpha; // per-vertex alpha [0..1]
} Vertex2D;

// High-performance calligraphy calculation
SKETCHER_EXPORT int calculate_calligraphy_segments(
    const PointData* points,
    int point_count,
    double stroke_width,
    double opacity,
    double nib_angle_deg,
    double nib_width_factor,
    CalligraphySegment* output_segments,
    int max_segments
);

// Stroke smoothing for professional quality
SKETCHER_EXPORT int smooth_stroke_points(
    const PointData* input_points,
    int input_count,
    double smoothing_factor,
    PointData* output_points,
    int max_output
);

// Uniformly resample points along the path at given spacing (in pixels)
SKETCHER_EXPORT int resample_stroke_points(
    const PointData* input_points,
    int input_count,
    double spacing,
    PointData* output_points,
    int max_output
);

// One Euro filter for smoothing with latency control
// min_cutoff: base cutoff frequency (Hz), beta: speed coefficient, d_cutoff: derivative cutoff
SKETCHER_EXPORT int one_euro_filter_points(
    const PointData* input_points,
    int input_count,
    double min_cutoff,
    double beta,
    double d_cutoff,
    PointData* output_points,
    int max_output
);

// Build a triangle mesh for the calligraphy stroke.
// Returns the number of vertices written to out_vertices.
// Writes the number of indices to out_index_count.
SKETCHER_EXPORT int build_calligraphy_mesh(
    const PointData* points,
    int point_count,
    double stroke_width,
    double opacity,
    double nib_angle_deg,
    double nib_width_factor,
    Vertex2D* out_vertices,
    int max_vertices,
    unsigned int* out_indices,
    int max_indices,
    int* out_index_count
);

#ifdef __cplusplus
}
#endif

#endif // SKETCHER_NATIVE_H