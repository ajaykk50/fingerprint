import 'dart:math';
import 'package:flutter/material.dart';

enum FingerprintType { loop, whorl, arch, spiral, doubleLoop }

class MazeCell {
  final int x;
  final int y;
  bool topWall = true;
  bool bottomWall = true;
  bool leftWall = true;
  bool rightWall = true;
  bool visited = false;

  MazeCell(this.x, this.y);
}

class FingerprintGenerator {
  final int cols;
  final int rows;
  final FingerprintType type;
  final Random random;
  
  late List<List<MazeCell>> grid;

  FingerprintGenerator({
    required this.cols,
    required this.rows,
    required this.type,
    int? seed,
  }) : random = Random(seed ?? DateTime.now().millisecondsSinceEpoch) {
    _generateLogicalMaze();
  }

  // 1. Generate Logical Maze using Prim's / DFS Algorithm
  void _generateLogicalMaze() {
    grid = List.generate(cols, (x) => List.generate(rows, (y) => MazeCell(x, y)));

    final List<MazeCell> stack = [];
    final MazeCell start = grid[0][0];
    start.visited = true;
    stack.add(start);

    while (stack.isNotEmpty) {
      final current = stack.last;
      final neighbors = _getUnvisitedNeighbors(current);

      if (neighbors.isNotEmpty) {
        // Choose a random unvisited neighbor
        final next = neighbors[random.nextInt(neighbors.length)];
        _removeWalls(current, next);
        next.visited = true;
        stack.add(next);
      } else {
        stack.removeLast();
      }
    }
  }

  List<MazeCell> _getUnvisitedNeighbors(MazeCell cell) {
    final List<MazeCell> neighbors = [];
    final x = cell.x;
    final y = cell.y;

    if (y > 0 && !grid[x][y - 1].visited) neighbors.add(grid[x][y - 1]); // North
    if (y < rows - 1 && !grid[x][y + 1].visited) neighbors.add(grid[x][y + 1]); // South
    if (x > 0 && !grid[x - 1][y].visited) neighbors.add(grid[x - 1][y]); // West
    if (x < cols - 1 && !grid[x + 1][y].visited) neighbors.add(grid[x + 1][y]); // East

    return neighbors;
  }

  void _removeWalls(MazeCell a, MazeCell b) {
    if (a.x == b.x) {
      if (a.y > b.y) {
        a.topWall = false;
        b.bottomWall = false;
      } else {
        a.bottomWall = false;
        b.topWall = false;
      }
    } else if (a.y == b.y) {
      if (a.x > b.x) {
        a.leftWall = false;
        b.rightWall = false;
      } else {
        a.rightWall = false;
        b.leftWall = false;
      }
    }
  }

  // 2. Coordinate Warping: Maps logical grid cell coordinates to Fingerprint physical screen space.
  Offset getWarpedPosition(double gridX, double gridY, Size canvasSize) {
    final double cx = canvasSize.width / 2;
    final double cy = canvasSize.height / 2;
    final double maxRadius = min(canvasSize.width, canvasSize.height) * 0.45;

    // Normalize coordinates from 0.0 to 1.0
    final double nx = gridX / cols;
    final double ny = gridY / rows;

    // Minimum radius at the center to prevent collapse and keep pathways wide
    final double minRadius = 35.0;

    switch (type) {
      case FingerprintType.whorl:
        // Concentric horseshoe arches: open sweep (1.3 * pi) prevents boundaries from overlapping
        final double r = minRadius + ny * (maxRadius - minRadius);
        final double theta = 0.35 * pi + nx * 1.3 * pi;
        return Offset(cx + r * cos(theta), cy + r * sin(theta));

      case FingerprintType.spiral:
        // Open spiral: sweeps 1.4 * pi, keeping boundaries separated
        final double theta = 0.3 * pi + nx * 1.4 * pi;
        final double r = minRadius + ny * (maxRadius - minRadius) + (nx * 8.0);
        return Offset(cx + r * cos(theta), cy + r * sin(theta));

      case FingerprintType.arch:
        // Parallel waves rising up. Amplitude capped at 30% of cell height.
        final double cellHeight = (maxRadius - minRadius) * 2.0 / rows;
        final double amplitude = cellHeight * 0.3;
        final double rx = (nx - 0.5) * maxRadius * 2.0;
        final double heightScale = (1.0 - ny);
        final double ry = (ny - 0.5) * maxRadius * 2.0 - (amplitude * heightScale * cos((nx - 0.5) * pi));
        return Offset(cx + rx, cy + ry);

      case FingerprintType.loop:
        // Standard loop shape using U-turn. Amplitude capped at 45% of cell height.
        final double cellHeight = (maxRadius - minRadius) * 2.0 / rows;
        final double amplitude = cellHeight * 0.45;
        final double rx = (nx - 0.5) * maxRadius * 2.0;
        final double heightScale = (1.0 - ny);
        final double ry = (ny - 0.5) * maxRadius * 2.0 - (amplitude * heightScale * exp(-4.0 * pow(nx - 0.5, 2)));
        return Offset(cx + rx, cy + ry);

      case FingerprintType.doubleLoop:
        // Interlocking Yin-Yang waves. Amplitude capped at 18% of cell size.
        final double cellWidth = maxRadius * 2.0 / cols;
        final double cellHeight = maxRadius * 2.0 / rows;
        final double ampX = cellWidth * 0.18;
        final double ampY = cellHeight * 0.18;
        final double rx = (nx - 0.5) * maxRadius * 2.0 + ampX * sin(ny * 2 * pi);
        final double ry = (ny - 0.5) * maxRadius * 2.0 + ampY * sin(nx * 2 * pi);
        return Offset(cx + rx, cy + ry);
    }
  }

  // Get grid coordinate of center escape core
  Point<int> getCoreCell() {
    return Point(cols ~/ 2, rows ~/ 2);
  }
}
