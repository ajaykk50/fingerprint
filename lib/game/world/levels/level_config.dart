import 'dart:math';
import '../maze/fingerprint_generator.dart';
import '../components/collectibles.dart';
import '../components/enemies.dart';

class CollectibleSpawn {
  final int x;
  final int y;
  final CollectibleType type;
  CollectibleSpawn(this.x, this.y, this.type);
}

class PuzzleSpawn {
  final String type; // 'plate', 'door', 'teleporter'
  final int x;
  final int y;
  final Map<String, dynamic> params;
  PuzzleSpawn(this.type, this.x, this.y, this.params);
}

class EnemySpawn {
  final EnemyType type;
  final int x;
  final int y;
  final Map<String, dynamic> params;
  EnemySpawn(this.type, this.x, this.y, this.params);
}

class LevelConfig {
  final int levelId;
  final int cols;
  final int rows;
  final FingerprintType fingerprintType;
  final Point<int> startPoint;
  final List<CollectibleSpawn> collectibles;
  final List<PuzzleSpawn> puzzles;
  final List<EnemySpawn> enemies;

  LevelConfig({
    required this.levelId,
    required this.cols,
    required this.rows,
    required this.fingerprintType,
    required this.startPoint,
    required this.collectibles,
    required this.puzzles,
    required this.enemies,
  });
}

class LevelConfigManager {
  static LevelConfig getLevelConfig(int levelId) {
    // Determine World classification (1 to 5) across 20 levels
    int world = 1;
    if (levelId <= 4) {
      world = 1;
    } else if (levelId <= 8) {
      world = 2;
    } else if (levelId <= 12) {
      world = 3;
    } else if (levelId <= 16) {
      world = 4;
    } else {
      world = 5;
    }

    // Use deterministic random based on levelId
    final rand = Random(levelId * 237);

    // Cap maze sizing to fit nicely on the screen and reduce complexity
    final int baseSize = 8 + (world - 1);
    final int cols = baseSize.clamp(8, 12);
    final int rows = baseSize.clamp(8, 12);

    // Fingerprint type selection per world
    FingerprintType fType = FingerprintType.whorl;
    if (world == 2) {
      fType = FingerprintType.spiral;
    } else if (world == 3) {
      fType = FingerprintType.arch;
    } else if (world == 4) {
      fType = FingerprintType.loop;
    } else if (world == 5) {
      fType = FingerprintType.doubleLoop;
    }

    final startPoint = const Point(0, 0); // Always start at top-left edge corridor

    final List<CollectibleSpawn> collectibles = [];
    final List<PuzzleSpawn> puzzles = [];
    final List<EnemySpawn> enemies = [];

    // Spawn core keys in worlds 3+
    bool needsKey = world >= 3;
    if (needsKey) {
      collectibles.add(CollectibleSpawn(cols - 1, 0, CollectibleType.key));
      // Put a door right before the core (cols~/2, rows~/2)
      final coreX = cols ~/ 2;
      final coreY = rows ~/ 2;
      
      // Let's spawn a pressure plate at (0, rows-1) to unlock the door
      puzzles.add(PuzzleSpawn('plate', 0, rows - 1, {}));
      puzzles.add(PuzzleSpawn('door', coreX, coreY - 1, {'plateX': 0, 'plateY': rows - 1}));
    }

    // Spawn battery cells dynamically based on sizing
    final int batteryCount = 2 + rand.nextInt(3);
    for (int i = 0; i < batteryCount; i++) {
      final bx = 1 + rand.nextInt(cols - 2);
      final by = 1 + rand.nextInt(rows - 2);
      // Ensure we don't spawn batteries on top of each other
      if (collectibles.any((c) => c.x == bx && c.y == by)) continue;

      CollectibleType bType = CollectibleType.batterySmall;
      if (rand.nextDouble() > 0.7) {
        bType = CollectibleType.batteryMedium;
      }
      if (rand.nextDouble() > 0.95 && world >= 4) {
        bType = CollectibleType.batteryLarge;
      }
      
      collectibles.add(CollectibleSpawn(bx, by, bType));
    }

    // Spawn DNA fragments (currency)
    final int dnaCount = 3 + rand.nextInt(4);
    for (int i = 0; i < dnaCount; i++) {
      final dx = 1 + rand.nextInt(cols - 2);
      final dy = 1 + rand.nextInt(rows - 2);
      if (collectibles.any((c) => c.x == dx && c.y == dy)) continue;
      
      collectibles.add(CollectibleSpawn(dx, dy, CollectibleType.dna));
    }

    // Spawn battery chargers (Power Stations) for harder levels (world >= 3)
    if (world >= 3) {
      final int cx = cols - 2;
      final int cy = rows - 2;
      if (!collectibles.any((c) => c.x == cx && c.y == cy)) {
        collectibles.add(CollectibleSpawn(cx, cy, CollectibleType.charger));
      }
    }

    // Spawning enemies based on Worlds progression (exclusive list to avoid crowded levels)
    if (world == 2 || world == 3) {
      // World 2-3: Small random movement drone
      enemies.add(EnemySpawn(EnemyType.shadowDrone, cols - 1, rows - 1, {}));
    } else if (world == 4) {
      // World 4: Single security patrol bot
      final path = [
        Point(cols - 1, 1),
        Point(cols - 1, rows - 2),
      ];
      enemies.add(EnemySpawn(EnemyType.securityBot, cols - 1, 1, {'patrolPath': path}));
    } else if (world == 5) {
      // World 5: Single slow tracking ghost
      enemies.add(EnemySpawn(EnemyType.ghostParticle, cols - 2, rows - 2, {}));
    } else if (world == 6) {
      // World 6: Single energy-draining light eater
      enemies.add(EnemySpawn(EnemyType.lightEater, cols - 2, rows - 2, {}));
    } else if (world == 7) {
      // World 7: Simple teleport pads
      puzzles.add(PuzzleSpawn('teleporter', 1, rows - 1, {'destX': cols - 2, 'destY': 1}));
      puzzles.add(PuzzleSpawn('teleporter', cols - 2, 1, {'destX': 1, 'destY': rows - 1}));
    } else if (world == 8) {
      // World 8: Single rotating scanning eye in center
      enemies.add(EnemySpawn(EnemyType.scannerEye, cols ~/ 2, rows ~/ 2, {'rotateSpeed': 1.0}));
    } else if (world >= 9) {
      // World 9-10: Capped combined threats
      enemies.add(EnemySpawn(EnemyType.scannerEye, cols ~/ 2, rows ~/ 2, {'rotateSpeed': 0.8}));
      enemies.add(EnemySpawn(EnemyType.shadowDrone, cols - 1, rows - 1, {}));
    }

    return LevelConfig(
      levelId: levelId,
      cols: cols,
      rows: rows,
      fingerprintType: fType,
      startPoint: startPoint,
      collectibles: collectibles,
      puzzles: puzzles,
      enemies: enemies,
    );
  }
}
