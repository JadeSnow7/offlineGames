#ifndef PHYSICS_TYPES_H
#define PHYSICS_TYPES_H

#include <cstdint>

namespace cppcore {

/// 2D vector used across physics and collision subsystems.
struct Vec2 {
    float x = 0.0f;
    float y = 0.0f;

    Vec2 operator+(const Vec2& other) const { return {x + other.x, y + other.y}; }
    Vec2 operator-(const Vec2& other) const { return {x - other.x, y - other.y}; }
    Vec2 operator*(float scalar) const { return {x * scalar, y * scalar}; }
    float dot(const Vec2& other) const { return x * other.x + y * other.y; }
    float lengthSquared() const { return x * x + y * y; }
};

/// Axis-aligned bounding box.
struct AABB {
    Vec2 min;
    Vec2 max;

    float width() const { return max.x - min.x; }
    float height() const { return max.y - min.y; }
    Vec2 center() const { return {(min.x + max.x) * 0.5f, (min.y + max.y) * 0.5f}; }
};

/// Integer grid position.
struct GridPos {
    int32_t x = 0;
    int32_t y = 0;

    bool operator==(const GridPos& other) const { return x == other.x && y == other.y; }
    bool operator!=(const GridPos& other) const { return !(*this == other); }
};

} // namespace cppcore

#endif // PHYSICS_TYPES_H
