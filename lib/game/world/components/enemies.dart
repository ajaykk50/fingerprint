import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../../core/config/theme.dart';
import '../maze/maze_component.dart';
import '../player/player_component.dart';
import '../../engine/echo_print_game.dart';

enum EnemyType { shadowDrone, securityBot, ghostParticle, lightEater, scannerEye }

class EnemyComponent extends PositionComponent with HasGameRef<EchoPrintGame> {
  final EnemyType type;
  double gridX;
  double gridY;
  int targetX;
  int targetY;

  double moveSpeed = 4.0;
  bool isMoving = false;
  
  // Timer for AI actions
  double aiTimer = 0.0;
  double actionInterval = 1.5;

  // Patrol coordinates for SecurityBot
  final List<Point<int>> patrolPath;
  int patrolIndex = 0;

  // Laser details for ScannerEye
  double laserAngle = 0.0;
  double laserRotateSpeed = 1.0;

  EnemyComponent({
    required this.type,
    required int startX,
    required int startY,
    this.patrolPath = const [],
    this.laserRotateSpeed = 1.2,
  })  : gridX = startX.toDouble(),
        gridY = startY.toDouble(),
        targetX = startX,
        targetY = startY {
    anchor = Anchor.center;
    size = Vector2(18, 18);
  }

  @override
  void update(double dt) {
    super.update(dt);

    final mazeComp = gameRef.children.whereType<MazeComponent>().firstOrNull;
    if (mazeComp == null) return;

    final Size canvasSize = Size(gameRef.size.x, gameRef.size.y);

    // 1. Move interpolation
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

    // Convert to screen position
    final Offset screenPos = mazeComp.generator.getWarpedPosition(gridX + 0.5, gridY + 0.5, canvasSize);
    position = Vector2(screenPos.dx, screenPos.dy);

    // 2. Player proximity checks
    final player = gameRef.children.whereType<PlayerComponent>().firstOrNull;
    if (player == null) return;

    final double distToPlayer = sqrt(pow(player.gridX - gridX, 2) + pow(player.gridY - gridY, 2));

    // Collision (game over)
    if (player.targetX == targetX && player.targetY == targetY && !isMoving && !player.isMoving) {
      gameRef.gameCubit.failGame();
    }

    // AI Logic updates
    aiTimer += dt;
    if (aiTimer >= actionInterval) {
      aiTimer = 0.0;
      _updateAI(mazeComp, player);
    }

    // Special behavior updates per type
    if (type == EnemyType.lightEater && distToPlayer <= 2.2) {
      // Drain battery rapidly if player is close
      gameRef.gameCubit.drainBattery(15.0 * dt);
    }

    if (type == EnemyType.scannerEye) {
      laserAngle = (laserAngle + laserRotateSpeed * dt) % (2 * pi);
      _checkLaserCollision(player, mazeComp, canvasSize);
    }
  }

  // 3. AI Movement Decision Trees
  void _updateAI(MazeComponent mazeComp, PlayerComponent player) {
    if (isMoving) return;

    switch (type) {
      case EnemyType.shadowDrone:
        // Move randomly along available corridors
        final currentCell = mazeComp.generator.grid[targetX][targetY];
        final List<Point<int>> options = [];
        if (!currentCell.topWall) options.add(Point(targetX, targetY - 1));
        if (!currentCell.bottomWall) options.add(Point(targetX, targetY + 1));
        if (!currentCell.leftWall) options.add(Point(targetX - 1, targetY));
        if (!currentCell.rightWall) options.add(Point(targetX + 1, targetY));

        if (options.isNotEmpty) {
          final next = options[Random().nextInt(options.length)];
          targetX = next.x;
          targetY = next.y;
          isMoving = true;
        }
        break;

      case EnemyType.securityBot:
        // Patrol path coordinates
        if (patrolPath.isNotEmpty) {
          patrolIndex = (patrolIndex + 1) % patrolPath.length;
          final next = patrolPath[patrolIndex];
          targetX = next.x;
          targetY = next.y;
          isMoving = true;
        }
        break;

      case EnemyType.ghostParticle:
        // Simple heuristic tracking towards player coordinate
        final dx = (player.targetX - targetX).sign.toInt();
        final dy = (player.targetY - targetY).sign.toInt();

        final currentCell = mazeComp.generator.grid[targetX][targetY];
        // Prefer moving along the closest axis
        if (dx != 0 && ((dx < 0 && !currentCell.leftWall) || (dx > 0 && !currentCell.rightWall))) {
          targetX += dx;
          isMoving = true;
        } else if (dy != 0 && ((dy < 0 && !currentCell.topWall) || (dy > 0 && !currentCell.bottomWall))) {
          targetY += dy;
          isMoving = true;
        }
        break;

      default:
        break;
    }
  }

  // 4. Scanner laser collision calculation
  void _checkLaserCollision(PlayerComponent player, MazeComponent mazeComp, Size canvasSize) {
    final Offset myPos = Offset(position.x, position.y);
    final Offset playerPos = Offset(player.position.x, player.position.y);
    
    // Draw a virtual laser line from our position in the laserAngle direction up to 200 pixels
    final double maxLaserLen = 220.0;
    final Offset laserEnd = myPos + Offset(maxLaserLen * cos(laserAngle), maxLaserLen * sin(laserAngle));

    // Calculate perpendicular distance from player to laser line
    final double lineLenSq = (pow(laserEnd.dx - myPos.dx, 2) + pow(laserEnd.dy - myPos.dy, 2)).toDouble();
    if (lineLenSq == 0) return;

    // Projection scalar t
    final double t = (((playerPos.dx - myPos.dx) * (laserEnd.dx - myPos.dx)) +
            ((playerPos.dy - myPos.dy) * (laserEnd.dy - myPos.dy))) /
        lineLenSq;

    if (t >= 0.0 && t <= 1.0) {
      // Closest point on the line segment
      final Offset projection = Offset(
        myPos.dx + t * (laserEnd.dx - myPos.dx),
        myPos.dy + t * (laserEnd.dy - myPos.dy),
      );

      final double distance = (playerPos - projection).distance;
      // If player crosses the thin laser segment (within player radius)
      if (distance < 12.0) {
        gameRef.gameCubit.failGame();
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final double cx = size.x / 2;
    final double cy = size.y / 2;

    switch (type) {
      case EnemyType.shadowDrone:
        // Draw glitching diamond
        final Paint paint = Paint()
          ..color = AppTheme.accentPurple
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;
        final Path path = Path()
          ..moveTo(cx, 0)
          ..lineTo(size.x, cy)
          ..lineTo(cx, size.y)
          ..lineTo(0, cy)
          ..close();
        canvas.drawPath(path, paint);
        canvas.drawCircle(Offset(cx, cy), 3, paint..style = PaintingStyle.fill);
        break;

      case EnemyType.securityBot:
        // Draw double-ring warning scanner
        final Paint bodyPaint = Paint()
          ..color = AppTheme.accentRed
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
        canvas.drawCircle(Offset(cx, cy), 8, bodyPaint);
        canvas.drawRect(Rect.fromLTWH(cx - 3, cy - 3, 6, 6), bodyPaint..style = PaintingStyle.fill);
        break;

      case EnemyType.ghostParticle:
        // Draw fading neon triangle
        final Paint paint = Paint()
          ..color = AppTheme.accentPurple.withValues(alpha: 0.7)
          ..style = PaintingStyle.fill;
        final Path path = Path()
          ..moveTo(cx, 2)
          ..lineTo(size.x - 2, size.y - 2)
          ..lineTo(2, size.y - 2)
          ..close();
        canvas.drawPath(path, paint);
        break;

      case EnemyType.lightEater:
        // Draw spiky hollow circle (consuming light)
        final Paint paint = Paint()
          ..color = AppTheme.accentRed.withValues(alpha: 0.8)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
        canvas.drawCircle(Offset(cx, cy), 9, paint);
        // Inner core
        canvas.drawCircle(Offset(cx, cy), 4, paint..color = Colors.black..style = PaintingStyle.fill);
        break;

      case EnemyType.scannerEye:
        // Draw a CCTV style camera eye and its active laser line
        final Paint paint = Paint()
          ..color = AppTheme.accentRed
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(cx, cy), 7, paint);
        canvas.drawCircle(Offset(cx, cy), 9, paint..style = PaintingStyle.stroke..strokeWidth = 1.0);

        // Draw rotating laser beam
        final Paint laserPaint = Paint()
          ..color = AppTheme.accentRed.withValues(alpha: 0.6)
          ..strokeWidth = 1.5;
        
        final double maxLaserLen = 220.0;
        canvas.drawLine(
          Offset(cx, cy),
          Offset(cx + maxLaserLen * cos(laserAngle), cy + maxLaserLen * sin(laserAngle)),
          laserPaint,
        );
        break;
    }
  }
}
