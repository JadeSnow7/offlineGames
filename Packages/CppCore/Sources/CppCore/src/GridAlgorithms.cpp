#include "GridAlgorithms.h"
#include <queue>
#include <unordered_map>
#include <cmath>
#include <algorithm>
#include <functional>

namespace cppcore {

int floodFill(std::vector<std::vector<int32_t>>& grid,
              int startX, int startY, int newValue) {
    if (grid.empty() || grid[0].empty()) return 0;

    int rows = static_cast<int>(grid.size());
    int cols = static_cast<int>(grid[0].size());

    if (startX < 0 || startX >= cols || startY < 0 || startY >= rows) return 0;

    int oldValue = grid[startY][startX];
    if (oldValue == newValue) return 0;

    int count = 0;
    std::queue<GridPos> queue;
    queue.push({startX, startY});

    while (!queue.empty()) {
        GridPos pos = queue.front();
        queue.pop();

        if (pos.x < 0 || pos.x >= cols || pos.y < 0 || pos.y >= rows) continue;
        if (grid[pos.y][pos.x] != oldValue) continue;

        grid[pos.y][pos.x] = newValue;
        count++;

        queue.push({pos.x + 1, pos.y});
        queue.push({pos.x - 1, pos.y});
        queue.push({pos.x, pos.y + 1});
        queue.push({pos.x, pos.y - 1});
    }

    return count;
}

std::vector<GridPos> aStarPath(const std::vector<std::vector<int32_t>>& grid,
                               GridPos start, GridPos goal) {
    if (grid.empty() || grid[0].empty()) return {};

    int rows = static_cast<int>(grid.size());
    int cols = static_cast<int>(grid[0].size());

    auto heuristic = [](GridPos a, GridPos b) -> float {
        return static_cast<float>(std::abs(a.x - b.x) + std::abs(a.y - b.y));
    };

    auto key = [cols](GridPos p) -> int { return p.y * cols + p.x; };

    struct Node {
        GridPos pos;
        float fScore;
        bool operator>(const Node& other) const { return fScore > other.fScore; }
    };

    std::priority_queue<Node, std::vector<Node>, std::greater<Node>> openSet;
    std::unordered_map<int, GridPos> cameFrom;
    std::unordered_map<int, float> gScore;

    int startKey = key(start);
    gScore[startKey] = 0.0f;
    openSet.push({start, heuristic(start, goal)});

    const GridPos dirs[] = {{1, 0}, {-1, 0}, {0, 1}, {0, -1}};

    while (!openSet.empty()) {
        Node current = openSet.top();
        openSet.pop();

        if (current.pos == goal) {
            std::vector<GridPos> path;
            GridPos step = goal;
            while (!(step == start)) {
                path.push_back(step);
                step = cameFrom[key(step)];
            }
            path.push_back(start);
            std::reverse(path.begin(), path.end());
            return path;
        }

        for (const auto& dir : dirs) {
            GridPos neighbor = {current.pos.x + dir.x, current.pos.y + dir.y};
            if (neighbor.x < 0 || neighbor.x >= cols ||
                neighbor.y < 0 || neighbor.y >= rows) continue;
            if (grid[neighbor.y][neighbor.x] != 0) continue;

            float tentativeG = gScore[key(current.pos)] + 1.0f;
            int neighborKey = key(neighbor);

            if (gScore.find(neighborKey) == gScore.end() ||
                tentativeG < gScore[neighborKey]) {
                cameFrom[neighborKey] = current.pos;
                gScore[neighborKey] = tentativeG;
                openSet.push({neighbor, tentativeG + heuristic(neighbor, goal)});
            }
        }
    }

    return {};
}

int clearCompletedRows(std::vector<std::vector<int32_t>>& grid) {
    int cleared = 0;
    for (auto it = grid.begin(); it != grid.end();) {
        bool full = true;
        for (int32_t cell : *it) {
            if (cell == 0) { full = false; break; }
        }
        if (full) {
            it = grid.erase(it);
            cleared++;
        } else {
            ++it;
        }
    }
    // Add empty rows at the top
    int cols = grid.empty() ? 0 : static_cast<int>(grid[0].size());
    for (int i = 0; i < cleared; i++) {
        grid.insert(grid.begin(), std::vector<int32_t>(cols, 0));
    }
    return cleared;
}

} // namespace cppcore
