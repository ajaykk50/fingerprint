import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../../core/config/theme.dart';
import '../maze/maze_component.dart';
import '../player/player_component.dart';
import '../../engine/echo_print_game.dart';

enum CollectibleType { dna, batterySmall, batteryMedium, batteryLarge, key, charger }

class CollectibleComponent extends PositionComponent with HasGameRef<EchoPrintGame> {
  final int gridX;
  final int gridY;
  final CollectibleType type;

  CollectibleComponent({
    required this.gridX,
    required this.gridY,
    required this.type,
  }) {
    anchor = Anchor.center;
    size = Vector2(16, 16);
  }

  @override
  void update(double dt) {
    super.update(dt);

    final mazeComp = gameRef.children.whereType<MazeComponent>().firstOrNull;
    if (mazeComp == null) return;

    final Size canvasSize = Size(gameRef.size.x, gameRef.size.y);
    final Offset screenPos = mazeComp.generator.getWarpedPosition(gridX + 0.5, gridY + 0.5, canvasSize);
    position = Vector2(screenPos.dx, screenPos.dy);

    // Check collision with player
    final player = gameRef.children.whereType<PlayerComponent>().firstOrNull;
    if (player != null && player.targetX == gridX && player.targetY == gridY) {
      _onCollect();
    }
  }

  void _onCollect() {
    switch (type) {
      case CollectibleType.dna:
        gameRef.gameCubit.collectDna(15);
        break;
      case CollectibleType.batterySmall:
        gameRef.gameCubit.rechargeBattery(10.0);
        break;
      case CollectibleType.batteryMedium:
        gameRef.gameCubit.rechargeBattery(25.0);
        break;
      case CollectibleType.batteryLarge:
        gameRef.gameCubit.rechargeBattery(50.0);
        break;
      case CollectibleType.key:
        gameRef.gameCubit.obtainKey();
        break;
      case CollectibleType.charger:
        gameRef.gameCubit.rechargeBattery(100.0); // Full Power Station charger
        break;
    }
    
    // Remove from game loop
    removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final double cx = size.x / 2;
    final double cy = size.y / 2;

    switch (type) {
      case CollectibleType.dna:
        // Draw a double-helix neon shape
        final Paint paint = Paint()
          ..color = AppTheme.accentNeon
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;
        canvas.drawCircle(Offset(cx - 3, cy), 3, paint);
        canvas.drawCircle(Offset(cx + 3, cy), 3, paint);
        canvas.drawLine(Offset(cx - 3, cy), Offset(cx + 3, cy), paint);
        break;

      case CollectibleType.batterySmall:
      case CollectibleType.batteryMedium:
      case CollectibleType.batteryLarge:
        // Draw battery cylinder outline with neon levels
        final Color energyColor = type == CollectibleType.batteryLarge 
            ? AppTheme.accentNeon 
            : AppTheme.accentBlue;
        final Paint bodyPaint = Paint()
          ..color = energyColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        final Paint fillPaint = Paint()
          ..color = energyColor.withValues(alpha: 0.6)
          ..style = PaintingStyle.fill;

        canvas.drawRect(Rect.fromLTWH(cx - 4, cy - 6, 8, 12), bodyPaint);
        canvas.drawRect(Rect.fromLTWH(cx - 2, cy - 8, 4, 2), bodyPaint); // Terminal tip
        
        final double fillPct = type == CollectibleType.batterySmall 
            ? 0.3 
            : type == CollectibleType.batteryMedium ? 0.6 : 0.9;
        canvas.drawRect(
          Rect.fromLTWH(cx - 3, cy + 5 - (10 * fillPct), 6, 10 * fillPct),
          fillPaint,
        );
        break;

      case CollectibleType.key:
        // Draw glowing biometric keycard/key
        final Paint paint = Paint()
          ..color = AppTheme.accentPurple
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;
        canvas.drawCircle(Offset(cx, cy - 3), 4, paint);
        canvas.drawLine(Offset(cx, cy + 1), Offset(cx, cy + 7), paint);
        canvas.drawLine(Offset(cx, cy + 4), Offset(cx + 3, cy + 4), paint);
        canvas.drawLine(Offset(cx, cy + 6), Offset(cx + 3, cy + 6), paint);
        break;

      case CollectibleType.charger:
        // Draw a pulsing concentric neon square and central charging dot
        final Paint paint = Paint()
          ..color = AppTheme.accentBlue
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;
        final Paint fillPaint = Paint()
          ..color = AppTheme.accentBlue.withValues(alpha: 0.35)
          ..style = PaintingStyle.fill;
        
        canvas.drawRect(Rect.fromLTWH(cx - 6, cy - 6, 12, 12), fillPaint);
        canvas.drawRect(Rect.fromLTWH(cx - 6, cy - 6, 12, 12), paint);
        canvas.drawCircle(Offset(cx, cy), 3, paint..color = AppTheme.accentNeon..style = PaintingStyle.fill);
        break;
    }
  }
}
