#ifndef GRID_ALGORITHMS_H
#define GRID_ALGORITHMS_H

#include "PhysicsTypes.h"
#include <vector>
#include <cstdint>

namespace cppcore {

/// Flood fill on a 2D grid starting from (startX, startY).
/// Returns the count of cells filled.
int floodFill(std::vector<std::vector<int32_t>>& grid,
              int startX, int startY, int newValue);

/// A* pathfinding on a 2D grid. Returns a path from start to goal.
/// Empty vector if no path exists.
std::vector<GridPos> aStarPath(const std::vector<std::vector<int32_t>>& grid,
                               GridPos start, GridPos goal);

/// Check and clear completed rows in a block-puzzle grid.
/// Returns the number of rows cleared.
int clearCompletedRows(std::vector<std::vector<int32_t>>& grid);

} // namespace cppcore

#endif // GRID_ALGORITHMS_H
