#include "CollisionDetection.h"
#include <algorithm>
#include <cmath>

namespace cppcore {

bool aabbOverlap(const AABB& a, const AABB& b) {
    return a.min.x <= b.max.x && a.max.x >= b.min.x &&
           a.min.y <= b.max.y && a.max.y >= b.min.y;
}

bool pointInAABB(const Vec2& point, const AABB& box) {
    return point.x >= box.min.x && point.x <= box.max.x &&
           point.y >= box.min.y && point.y <= box.max.y;
}

bool circleOverlap(const Vec2& centerA, float radiusA,
                   const Vec2& centerB, float radiusB) {
    Vec2 diff = centerA - centerB;
    float distSq = diff.lengthSquared();
    float radiusSum = radiusA + radiusB;
    return distSq <= radiusSum * radiusSum;
}

bool circleAABBOverlap(const Vec2& center, float radius, const AABB& box) {
    float closestX = std::clamp(center.x, box.min.x, box.max.x);
    float closestY = std::clamp(center.y, box.min.y, box.max.y);
    Vec2 closest = {closestX, closestY};
    Vec2 diff = center - closest;
    return diff.lengthSquared() <= radius * radius;
}

} // namespace cppcore
