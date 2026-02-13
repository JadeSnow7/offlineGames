#ifndef COLLISION_DETECTION_H
#define COLLISION_DETECTION_H

#include "PhysicsTypes.h"

namespace cppcore {

/// Check if two axis-aligned bounding boxes overlap.
bool aabbOverlap(const AABB& a, const AABB& b);

/// Check if a point is inside an axis-aligned bounding box.
bool pointInAABB(const Vec2& point, const AABB& box);

/// Check if two circles overlap.
bool circleOverlap(const Vec2& centerA, float radiusA,
                   const Vec2& centerB, float radiusB);

/// Check if a circle overlaps an AABB.
bool circleAABBOverlap(const Vec2& center, float radius, const AABB& box);

} // namespace cppcore

#endif // COLLISION_DETECTION_H
