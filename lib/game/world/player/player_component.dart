import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../../core/config/dependency_injection.dart';
import '../../../core/config/theme.dart';
import '../../../core/services/audio_service.dart';
import '../maze/maze_component.dart';
import '../components/puzzles.dart';
import '../components/collectibles.dart';
import '../levels/level_config.dart';
import '../../engine/echo_print_game.dart';

class PlayerComponent extends PositionComponent with HasGameRef<EchoPrintGame> {
  // Logical grid coordinates
  double gridX = 0.0;
  double gridY = 0.0;
  
  int targetX = 0;
  int targetY = 0;

  double moveSpeed = 8.0; // Interpolation speed
  bool isMoving = false;

  // Flashlight properties (upgradable)
  double baseLightRadius = 120.0;
  double currentLightRadius = 120.0;

  PlayerComponent({
    required int startX,
    required int startY,
  }) {
    gridX = startX.toDouble();
    gridY = startY.toDouble();
    targetX = startX;
    targetY = startY;
    anchor = Anchor.center;
    size = Vector2(20, 20); // Orb size
  }

  // Attempt to move in a physical screen direction (swipe/tap vector)
  void move(Offset screenDir) {
    if (isMoving) return;

    final mazeComp = gameRef.children.whereType<MazeComponent>().firstOrNull;
    if (mazeComp == null) return;

    final generator = mazeComp.generator;
    final Size canvasSize = Size(gameRef.size.x, gameRef.size.y);

    final currentCell = generator.grid[targetX][targetY];
    final Offset currentScreenPos = generator.getWarpedPosition(targetX + 0.5, targetY + 0.5, canvasSize);

    // Build the list of all mathematically open adjacent paths
    final List<Map<String, dynamic>> movements = [];

    // North (dy = -1)
    if (!currentCell.topWall && targetY > 0) {
      movements.add({'x': targetX, 'y': targetY - 1});
    }
    // South (dy = 1)
    if (!currentCell.bottomWall && targetY < generator.rows - 1) {
      movements.add({'x': targetX, 'y': targetY + 1});
    }
    // West (dx = -1)
    if (!currentCell.leftWall && targetX > 0) {
      movements.add({'x': targetX - 1, 'y': targetY});
    }
    // East (dx = 1)
    if (!currentCell.rightWall && targetX < generator.cols - 1) {
      movements.add({'x': targetX + 1, 'y': targetY});
    }

    double bestDot = -double.maxFinite;
    Map<String, dynamic>? bestMove;

    for (final move in movements) {
      final int tx = move['x'] as int;
      final int ty = move['y'] as int;

      // Check if target cell has a closed security door
      final closedDoor = gameRef.children.whereType<DoorComponent>().firstWhere(
        (door) => door.gridX == tx && door.gridY == ty && door.isClosed,
        orElse: () => DoorComponent(gridX: -1, gridY: -1, plateX: -1, plateY: -1)..isClosed = false,
      );
      if (closedDoor.isClosed) continue; // Door blocks path

      // Get neighbor position in screen space (centered)
      final Offset neighborScreenPos = generator.getWarpedPosition(tx + 0.5, ty + 0.5, canvasSize);
      
      // Screen direction vector to this neighbor cell
      final Offset dirVec = neighborScreenPos - currentScreenPos;

      // Dot product comparison of normalized vectors to eliminate speed bias
      if (dirVec.distance > 0 && screenDir.distance > 0) {
        final double dot = (dirVec.dx * screenDir.dx + dirVec.dy * screenDir.dy) / 
            (dirVec.distance * screenDir.distance);
        // Only consider paths generally matching the user swipe direction (within 75 degrees)
        if (dot > bestDot && dot > 0.25) {
          bestDot = dot;
          bestMove = move;
        }
      }
    }

    // Only commit movement if direction matches alignment
    if (bestMove != null) {
      targetX = bestMove['x'] as int;
      targetY = bestMove['y'] as int;
      isMoving = true;
    } else {
      // Trigger feed feedback on block
      gameRef.triggerCameraShake(duration: 0.1, intensity: 2.0);
      locator<AudioService>().playSfx('collision.wav');
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    final mazeComp = gameRef.children.whereType<MazeComponent>().firstOrNull;
    if (mazeComp == null) return;

    final generator = mazeComp.generator;
    final Size canvasSize = Size(gameRef.size.x, gameRef.size.y);

    // Interpolate grid position
    if (isMoving) {
      final double dx = targetX - gridX;
      final double dy = targetY - gridY;
      final double dist = dx * dx + dy * dy;

      if (dist < 0.001) {
        gridX = targetX.toDouble();
        gridY = targetY.toDouble();
        isMoving = false;
      } else {
        gridX += dx * moveSpeed * dt;
        gridY += dy * moveSpeed * dt;
      }
    }

    // Convert logical warped coordinates to screen pixels (centered in corridor)
    final Offset screenPos = generator.getWarpedPosition(gridX + 0.5, gridY + 0.5, canvasSize);
    position = Vector2(screenPos.dx, screenPos.dy);

    // Dynamic flashlight radius based on remaining battery
    final batteryLevel = gameRef.gameCubit.state.battery;
    currentLightRadius = baseLightRadius * (0.4 + 0.6 * (batteryLevel / 100.0));

    // Register coordinates to explore cell (Fog of War)
    mazeComp.exploreCell(gridX.round(), gridY.round());

    // Check if player has reached the fingerprint core (win condition)
    final core = generator.getCoreCell();
    if (targetX == core.x && targetY == core.y && !isMoving) {
      final config = LevelConfigManager.getLevelConfig(gameRef.gameCubit.state.levelId);
      final bool requiresKey = config.collectibles.any((c) => c.type == CollectibleType.key);

      if (requiresKey && !gameRef.gameCubit.state.hasKey) {
        // Warning: keycard required
        gameRef.triggerCameraShake(duration: 0.15, intensity: 3.0);
        locator<AudioService>().playSfx('collision.wav');
      } else {
        gameRef.gameCubit.completeLevel();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw Player Neon Orb
    final Paint glowPaint = Paint()
      ..color = AppTheme.accentNeon.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0);
    
    final Paint corePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Draw glow circle
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 14, glowPaint);
    // Draw white core circle
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 6, corePaint);
  }
}
