#include "../include/sketcher_native.h"
#include <cmath>
#include <algorithm>
#include <cstdint>
#include <vector>

// Define M_PI if not available (Windows compatibility)
#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

// Fast trigonometric calculations with caching
class FastTrig {
private:
    static constexpr int TABLE_SIZE = 3600; // 0.1 degree precision
    static double sin_table[TABLE_SIZE];
    static double cos_table[TABLE_SIZE];
    static bool initialized;
    
public:
    static void initialize() {
        if (initialized) return;
        
        for (int i = 0; i < TABLE_SIZE; i++) {
            double angle = (i * M_PI) / (TABLE_SIZE / 2.0);
            sin_table[i] = sin(angle);
            cos_table[i] = cos(angle);
        }
        initialized = true;
    }
    
    static double fast_sin(double angle_rad) {
        initialize();
        int index = static_cast<int>((angle_rad * TABLE_SIZE) / (2.0 * M_PI)) % TABLE_SIZE;
        if (index < 0) index += TABLE_SIZE;
        return sin_table[index];
    }
    
    static double fast_cos(double angle_rad) {
        initialize();
        int index = static_cast<int>((angle_rad * TABLE_SIZE) / (2.0 * M_PI)) % TABLE_SIZE;
        if (index < 0) index += TABLE_SIZE;
        return cos_table[index];
    }
};

// Static initialization
double FastTrig::sin_table[FastTrig::TABLE_SIZE];
double FastTrig::cos_table[FastTrig::TABLE_SIZE];
bool FastTrig::initialized = false;

// Optimized vector operations
struct Vector2D {
    double x, y;
    
    Vector2D(double x = 0.0, double y = 0.0) : x(x), y(y) {}
    
    Vector2D operator-(const Vector2D& other) const {
        return Vector2D(x - other.x, y - other.y);
    }
    
    Vector2D operator+(const Vector2D& other) const {
        return Vector2D(x + other.x, y + other.y);
    }
    
    Vector2D operator*(double scalar) const {
        return Vector2D(x * scalar, y * scalar);
    }
    
    Vector2D operator/(double scalar) const {
        return Vector2D(x / scalar, y / scalar);
    }
    
    double length() const {
        return sqrt(x * x + y * y);
    }
    
    double length_squared() const {
        return x * x + y * y;
    }
    
    Vector2D normalized() const {
        double len = length();
        return len > 1e-10 ? Vector2D(x / len, y / len) : Vector2D(0, 0);
    }
    
    double dot(const Vector2D& other) const {
        return x * other.x + y * other.y;
    }
    
    double cross(const Vector2D& other) const {
        return x * other.y - y * other.x;
    }
};

SKETCHER_EXPORT int calculate_calligraphy_segments(
    const PointData* points,
    int point_count,
    double stroke_width,
    double opacity,
    double nib_angle_deg,
    double nib_width_factor,
    CalligraphySegment* output_segments,
    int max_segments
) {
    if (point_count < 2 || max_segments <= 0) return 0;
    
    FastTrig::initialize();
    
    // Convert nib angle to radians and calculate direction
    const double nib_angle_rad = nib_angle_deg * M_PI / 180.0;
    const Vector2D nib_dir(FastTrig::fast_cos(nib_angle_rad), FastTrig::fast_sin(nib_angle_rad));
    
    // Clamp width factor for stability
    const double clamped_width_factor = std::clamp(nib_width_factor, 0.3, 2.5);
    
    int segment_count = 0;
    
    // Pre-calculate constants
    const double min_thickness = 0.6;
    const double thickness_base = stroke_width * clamped_width_factor;
    const double thickness_range = 0.9;
    const double thickness_offset = 0.35;
    
    // Process each segment with optimized calculations
    for (int i = 0; i < point_count - 1 && segment_count < max_segments; i++) {
        const PointData& a = points[i];
        const PointData& b = points[i + 1];
        
        const Vector2D seg(b.x - a.x, b.y - a.y);
        const double length_sq = seg.length_squared();
        
        // Skip near-zero length segments for performance
        if (length_sq < 1e-12) continue;
        
        // Fast length calculation using inverse square root when possible
        const double length = sqrt(length_sq);
        const Vector2D tangent = seg / length;
        
        // Calculate thickness using cross product (calligraphy effect)
        const double cross_product = std::abs(tangent.cross(nib_dir));
        
        // Interpolate pressure
        const double avg_pressure = (a.pressure + b.pressure) * 0.5;
        
        // Optimized thickness calculation
        const double thickness = std::max(
            min_thickness,
            thickness_base * (thickness_offset + thickness_range * cross_product) * avg_pressure
        );
        
        // Store segment data
        output_segments[segment_count] = {
            a.x, a.y,
            b.x, b.y,
            thickness,
            opacity
        };
        
        segment_count++;
    }
    
    return segment_count;
}

SKETCHER_EXPORT int smooth_stroke_points(
    const PointData* input_points,
    int input_count,
    double smoothing_factor,
    PointData* output_points,
    int max_output
) {
    if (input_count < 3 || max_output <= 0) {
        // Copy input directly if too few points
        int copy_count = std::min(input_count, max_output);
        for (int i = 0; i < copy_count; i++) {
            output_points[i] = input_points[i];
        }
        return copy_count;
    }
    
    // Clamp smoothing factor
    const double factor = std::clamp(smoothing_factor, 0.0, 1.0);
    const double inv_factor = 1.0 - factor;
    
    // Always keep first point
    output_points[0] = input_points[0];
    int output_count = 1;
    
    // Apply smoothing using weighted averaging
    for (int i = 1; i < input_count - 1 && output_count < max_output; i++) {
        const PointData& prev = input_points[i - 1];
        const PointData& curr = input_points[i];
        const PointData& next = input_points[i + 1];
        
        // Smooth position
        const double smooth_x = factor * (prev.x + next.x) * 0.5 + inv_factor * curr.x;
        const double smooth_y = factor * (prev.y + next.y) * 0.5 + inv_factor * curr.y;
        
        // Smooth pressure
        const double smooth_pressure = factor * (prev.pressure + next.pressure) * 0.5 + inv_factor * curr.pressure;
        
        output_points[output_count] = {
            smooth_x,
            smooth_y,
            smooth_pressure,
            curr.timestamp,
            curr.tiltX,
            curr.tiltY
        };
        
        output_count++;
    }
    
    // Always keep last point
    if (output_count < max_output) {
        output_points[output_count] = input_points[input_count - 1];
        output_count++;
    }
    
    return output_count;
}

// Utility: distance between two points
static inline double dist2(double x1, double y1, double x2, double y2) {
    const double dx = x2 - x1, dy = y2 - y1;
    return dx*dx + dy*dy;
}

SKETCHER_EXPORT int resample_stroke_points(
    const PointData* input_points,
    int input_count,
    double spacing,
    PointData* output_points,
    int max_output
) {
    if (!input_points || !output_points || input_count <= 0 || max_output <= 0) return 0;
    if (input_count == 1) { output_points[0] = input_points[0]; return 1; }
    const double spacing2 = spacing * spacing;
    int out = 0;
    PointData last = input_points[0];
    output_points[out++] = last;
    double accx = last.x, accy = last.y;
    for (int i = 1; i < input_count && out < max_output; i++) {
        const PointData& p = input_points[i];
        if (dist2(last.x, last.y, p.x, p.y) >= spacing2) {
            output_points[out++] = p;
            last = p;
        }
    }
    if (out < max_output) output_points[out++] = input_points[input_count - 1];
    return out;
}

SKETCHER_EXPORT int compute_stroke_velocity(
    const PointData* points,
    int point_count,
    double* out_velocities,
    int max_output
) {
    if (!points || !out_velocities || point_count < 2 || max_output <= 0) return 0;
    int out = 0;
    for (int i = 1; i < point_count && out < max_output; i++) {
        const PointData& a = points[i-1];
        const PointData& b = points[i];
        const double d = sqrt(dist2(a.x, a.y, b.x, b.y));
        const double dt = std::max(1e-6, b.timestamp - a.timestamp);
        out_velocities[out++] = d / dt;
    }
    return out;
}

// Ramer–Douglas–Peucker simplify (recursive helper)
static void rdp(const std::vector<PointData>& pts, int s, int e, double eps2, std::vector<PointData>& out) {
    if (e <= s + 1) return;
    const PointData& A = pts[s];
    const PointData& B = pts[e];
    const double vx = B.x - A.x; const double vy = B.y - A.y;
    const double vlen2 = vx*vx + vy*vy;
    int idx = -1; double maxd = 0.0;
    for (int i = s + 1; i < e; i++) {
        const PointData& P = pts[i];
        double t = 0.0;
        if (vlen2 > 1e-12) t = ((P.x - A.x)*vx + (P.y - A.y)*vy) / vlen2;
        t = std::max(0.0, std::min(1.0, t));
        const double projx = A.x + t*vx; const double projy = A.y + t*vy;
        const double d2 = dist2(P.x, P.y, projx, projy);
        if (d2 > maxd) { maxd = d2; idx = i; }
    }
    if (maxd > eps2 && idx != -1) {
        rdp(pts, s, idx, eps2, out);
        out.push_back(pts[idx]);
        rdp(pts, idx, e, eps2, out);
    }
}

SKETCHER_EXPORT int simplify_stroke_rdp(
    const PointData* input_points,
    int input_count,
    double epsilon,
    PointData* output_points,
    int max_output
) {
    if (!input_points || !output_points || input_count == 0 || max_output <= 0) return 0;
    if (input_count <= 2) {
        const int c = std::min(input_count, max_output);
        for (int i = 0; i < c; i++) output_points[i] = input_points[i];
        return c;
    }
    std::vector<PointData> pts(input_count);
    for (int i = 0; i < input_count; i++) pts[i] = input_points[i];
    std::vector<PointData> out;
    out.reserve(input_count);
    out.push_back(pts.front());
    rdp(pts, 0, input_count - 1, epsilon*epsilon, out);
    out.push_back(pts.back());
    const int c = std::min((int)out.size(), max_output);
    for (int i = 0; i < c; i++) output_points[i] = out[i];
    return c;
}
// Build a triangle mesh (two triangles = quad) per segment using thickness as half-width around centerline.
// Vertices carry per-vertex alpha for blending.
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
) {
    if (!points || !out_vertices || !out_indices || !out_index_count) return 0;
    if (point_count < 2 || max_vertices < 4 || max_indices < 6) { *out_index_count = 0; return 0; }

    FastTrig::initialize();

    const double nib_angle_rad = nib_angle_deg * M_PI / 180.0;
    const Vector2D nib_dir(FastTrig::fast_cos(nib_angle_rad), FastTrig::fast_sin(nib_angle_rad));
    const double clamped_width_factor = std::clamp(nib_width_factor, 0.3, 2.5);
    const double thickness_base = stroke_width * clamped_width_factor;
    const double thickness_range = 0.9;
    const double thickness_offset = 0.35;

    int vcount = 0;
    int icount = 0;

    for (int i = 0; i < point_count - 1; i++) {
        const PointData& a = points[i];
        const PointData& b = points[i + 1];
        const Vector2D seg(b.x - a.x, b.y - a.y);
        const double len2 = seg.length_squared();
        if (len2 < 1e-12) continue;
        const double len = sqrt(len2);
        const Vector2D t = seg / len;
        const double cross_p = std::abs(t.cross(nib_dir));
        const double pressure = (a.pressure + b.pressure) * 0.5;
        const double thickness = std::max(0.6, thickness_base * (thickness_offset + thickness_range * cross_p) * pressure);
        const double half_w = 0.5 * thickness;

        // Perpendicular to segment
        const Vector2D n(-t.y, t.x);

        // Quad corners around segment endpoints
        const Vector2D a_l = Vector2D(a.x, a.y) - n * half_w;
        const Vector2D a_r = Vector2D(a.x, a.y) + n * half_w;
        const Vector2D b_l = Vector2D(b.x, b.y) - n * half_w;
        const Vector2D b_r = Vector2D(b.x, b.y) + n * half_w;

        if (vcount + 4 > max_vertices || icount + 6 > max_indices) break;

        const double va = std::clamp(opacity * pressure, 0.0, 1.0);

        // Write vertices
        out_vertices[vcount + 0] = { a_l.x, a_l.y, va };
        out_vertices[vcount + 1] = { a_r.x, a_r.y, va };
        out_vertices[vcount + 2] = { b_l.x, b_l.y, va };
        out_vertices[vcount + 3] = { b_r.x, b_r.y, va };

        // Indices (two triangles): (0,2,1) and (1,2,3) with base offset
        const unsigned int base = static_cast<unsigned int>(vcount);
        out_indices[icount + 0] = base + 0;
        out_indices[icount + 1] = base + 2;
        out_indices[icount + 2] = base + 1;
        out_indices[icount + 3] = base + 1;
        out_indices[icount + 4] = base + 2;
        out_indices[icount + 5] = base + 3;

        vcount += 4;
        icount += 6;
    }

    *out_index_count = icount;
    return vcount;
}