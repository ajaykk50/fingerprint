import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'game_cubit.dart';
import '../world/maze/maze_component.dart';
import '../world/player/player_component.dart';
import '../world/player/lighting_mask_component.dart';
import '../world/levels/level_config.dart';
import '../world/components/collectibles.dart';
import '../world/components/puzzles.dart';
import '../world/components/enemies.dart';

class EchoPrintGame extends FlameGame with HasCollisionDetection {
  final GameCubit gameCubit;

  EchoPrintGame({required this.gameCubit}) : super();

  late PlayerComponent player;
  late MazeComponent maze;

  @override
  Color backgroundColor() => Colors.black;

  @override
  Future<void> onLoad() async {
    super.onLoad();
    
    final levelId = gameCubit.state.levelId;
    final config = LevelConfigManager.getLevelConfig(levelId);

    // 1. Create and add Fingerprint Maze
    maze = MazeComponent(
      cols: config.cols,
      rows: config.rows,
      type: config.fingerprintType,
    );
    await add(maze);

    // 2. Spawn player at configured start point
    player = PlayerComponent(startX: config.startPoint.x, startY: config.startPoint.y);
    await add(player);

    // 3. Spawn Collectibles
    for (final spawn in config.collectibles) {
      await add(CollectibleComponent(
        gridX: spawn.x,
        gridY: spawn.y,
        type: spawn.type,
      ));
    }

    // 4. Spawn Puzzles
    for (final spawn in config.puzzles) {
      if (spawn.type == 'plate') {
        await add(PressurePlateComponent(gridX: spawn.x, gridY: spawn.y));
      } else if (spawn.type == 'door') {
        await add(DoorComponent(
          gridX: spawn.x,
          gridY: spawn.y,
          plateX: spawn.params['plateX'] as int,
          plateY: spawn.params['plateY'] as int,
        ));
      } else if (spawn.type == 'teleporter') {
        await add(TeleporterComponent(
          gridX: spawn.x,
          gridY: spawn.y,
          destX: spawn.params['destX'] as int,
          destY: spawn.params['destY'] as int,
        ));
      }
    }

    // 5. Spawn Enemies
    for (final spawn in config.enemies) {
      final List<Point<int>> patrolPath = [];
      if (spawn.params['patrolPath'] != null) {
        patrolPath.addAll((spawn.params['patrolPath'] as List).cast<Point<int>>());
      }
      
      await add(EnemyComponent(
        type: spawn.type,
        startX: spawn.x,
        startY: spawn.y,
        patrolPath: patrolPath,
        laserRotateSpeed: (spawn.params['rotateSpeed'] as double?) ?? 1.2,
      ));
    }

    // 6. Add Fog of War & Flashlight overlay on top
    await add(LightingMaskComponent());

    // 7. Keep the camera locked centered in the screen to fit the fingerprint
    camera.viewfinder.anchor = Anchor.center;
    camera.viewfinder.position = Vector2(size.x / 2, size.y / 2);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    camera.viewfinder.position = Vector2(size.x / 2, size.y / 2);
  }

  @override
  void update(double dt) {
    super.update(dt);
    
    // Only update gameplay elements if the game state is currently active
    if (gameCubit.state.status == GameStatus.playing) {
      gameCubit.incrementTime(dt);
      
      // Flashlight battery drains progressively faster on higher levels
      final int levelId = gameCubit.state.levelId;
      final double drainRate = 1.0 + (levelId - 1) * 0.25;
      gameCubit.drainBattery(drainRate * dt);
    }
  }

  // Trigger camera shaking during warning or damage events
  void triggerCameraShake({double duration = 0.4, double intensity = 8.0}) {
    // Basic camera shake effect using viewfinder offsets or a temporary effect
    // We will build a customized shake effect later inside CameraManager or apply it here
  }
}
