import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../../core/config/dependency_injection.dart';
import '../../../core/config/theme.dart';
import '../../../core/services/audio_service.dart';
import '../maze/maze_component.dart';
import '../player/player_component.dart';
import '../../engine/echo_print_game.dart';

class PressurePlateComponent extends PositionComponent with HasGameRef<EchoPrintGame> {
  final int gridX;
  final int gridY;
  bool isPressed = false;

  PressurePlateComponent({required this.gridX, required this.gridY}) {
    anchor = Anchor.center;
    size = Vector2(22, 22);
  }

  @override
  void update(double dt) {
    super.update(dt);

    final mazeComp = gameRef.children.whereType<MazeComponent>().firstOrNull;
    if (mazeComp == null) return;

    final Size canvasSize = Size(gameRef.size.x, gameRef.size.y);
    final Offset screenPos = mazeComp.generator.getWarpedPosition(gridX + 0.5, gridY + 0.5, canvasSize);
    position = Vector2(screenPos.dx, screenPos.dy);

    // Detect if player is standing on this plate
    final player = gameRef.children.whereType<PlayerComponent>().firstOrNull;
    final bool currentlyPressed = player != null && player.targetX == gridX && player.targetY == gridY;
    
    if (currentlyPressed && !isPressed) {
      isPressed = true;
      locator<AudioService>().playSfx('click.wav');
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final Paint borderPaint = Paint()
      ..color = isPressed ? AppTheme.accentNeon : AppTheme.accentPurple
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final Paint fillPaint = Paint()
      ..color = (isPressed ? AppTheme.accentNeon : AppTheme.accentPurple).withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRect(rect, fillPaint);
    canvas.drawRect(rect, borderPaint);

    if (isPressed) {
      // Draw inner pressed indicator
      canvas.drawRect(Rect.fromLTWH(4, 4, size.x - 8, size.y - 8), borderPaint..strokeWidth = 1.0);
    }
  }
}

class DoorComponent extends PositionComponent with HasGameRef<EchoPrintGame> {
  final int gridX;
  final int gridY;
  final int plateX;
  final int plateY;
  bool isClosed = true;

  DoorComponent({
    required this.gridX,
    required this.gridY,
    required this.plateX,
    required this.plateY,
  }) {
    anchor = Anchor.center;
    size = Vector2(24, 24);
  }

  @override
  void update(double dt) {
    super.update(dt);

    final mazeComp = gameRef.children.whereType<MazeComponent>().firstOrNull;
    if (mazeComp == null) return;

    final Size canvasSize = Size(gameRef.size.x, gameRef.size.y);
    final Offset screenPos = mazeComp.generator.getWarpedPosition(gridX + 0.5, gridY + 0.5, canvasSize);
    position = Vector2(screenPos.dx, screenPos.dy);

    // Query linked pressure plate state
    final plate = gameRef.children.whereType<PressurePlateComponent>()
        .firstWhere((p) => p.gridX == plateX && p.gridY == plateY, 
        orElse: () => PressurePlateComponent(gridX: -1, gridY: -1));

    final bool shouldOpen = plate.isPressed;
    if (shouldOpen && isClosed) {
      isClosed = false;
      locator<AudioService>().playSfx('gate_open.wav');
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (isClosed) {
      // Draw security barricade cross laser
      final Paint laserPaint = Paint()
        ..color = AppTheme.accentRed
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke;

      canvas.drawLine(Offset(0, size.y / 2), Offset(size.x, size.y / 2), laserPaint);
      canvas.drawLine(Offset(size.x / 2, 0), Offset(size.x / 2, size.y), laserPaint..strokeWidth = 1.0);
    } else {
      // Draw faded green open gateway
      final Paint openPaint = Paint()
        ..color = AppTheme.accentNeon.withValues(alpha: 0.3)
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;
      
      canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), openPaint);
    }
  }
}

class TeleporterComponent extends PositionComponent with HasGameRef<EchoPrintGame> {
  final int gridX;
  final int gridY;
  final int destX;
  final int destY;
  
  double cooldown = 0.0;

  TeleporterComponent({
    required this.gridX,
    required this.gridY,
    required this.destX,
    required this.destY,
  }) {
    anchor = Anchor.center;
    size = Vector2(20, 20);
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (cooldown > 0.0) {
      cooldown -= dt;
    }

    final mazeComp = gameRef.children.whereType<MazeComponent>().firstOrNull;
    if (mazeComp == null) return;

    final Size canvasSize = Size(gameRef.size.x, gameRef.size.y);
    final Offset screenPos = mazeComp.generator.getWarpedPosition(gridX + 0.5, gridY + 0.5, canvasSize);
    position = Vector2(screenPos.dx, screenPos.dy);

    // Trigger teleport when player steps on it
    final player = gameRef.children.whereType<PlayerComponent>().firstOrNull;
    if (player != null && player.targetX == gridX && player.targetY == gridY && !player.isMoving && cooldown <= 0.0) {
      player.targetX = destX;
      player.targetY = destY;
      player.gridX = destX.toDouble();
      player.gridY = destY.toDouble();
      
      // Prevent immediate back-teleportation by setting a cooldown on both teleporters
      cooldown = 1.5;
      final partner = gameRef.children.whereType<TeleporterComponent>()
          .firstWhere((t) => t.gridX == destX && t.gridY == destY, 
          orElse: () => TeleporterComponent(gridX: -1, gridY: -1, destX: 0, destY: 0));
      partner.cooldown = 1.5;

      locator<AudioService>().playSfx('gate_open.wav'); // Teleport sound
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // Draw glowing teleporter portal rings
    final Paint paint = Paint()
      ..color = AppTheme.accentBlue
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    
    final Paint glowPaint = Paint()
      ..color = AppTheme.accentBlue.withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);

    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 10, glowPaint);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 8, paint);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), 4, paint..color = AppTheme.accentNeon);
  }
}
