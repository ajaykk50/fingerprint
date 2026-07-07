import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'player_component.dart';
import '../maze/maze_component.dart';
import '../../engine/echo_print_game.dart';

class LightingMaskComponent extends Component with HasGameRef<EchoPrintGame> {
  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 1. Locate player and maze components
    final player = gameRef.children.whereType<PlayerComponent>().firstOrNull;
    final maze = gameRef.children.whereType<MazeComponent>().firstOrNull;

    if (player == null || maze == null) return;

    final Size canvasSize = Size(gameRef.size.x, gameRef.size.y);
    final playerPos = Offset(player.position.x, player.position.y);

    // 2. Create offscreen compositing layer
    final Rect screenRect = Rect.fromLTWH(0, 0, gameRef.size.x, gameRef.size.y);
    canvas.saveLayer(screenRect, Paint());

    // 3. Draw Solid Black Overlay (Unexplored Area)
    canvas.drawRect(screenRect, Paint()..color = Colors.black);

    // 4. Carve out Explored Area (Fog of War)
    // Draw circular soft masks on the explored coordinates to make them semi-visible
    final Paint exploredPaint = Paint()
      ..blendMode = BlendMode.dstOut
      ..color = Colors.white.withValues(alpha: 0.18); // Subtracts opacity to reveal 18% brightness

    for (int x = 0; x < maze.cols; x++) {
      for (int y = 0; y < maze.rows; y++) {
        if (maze.explored[x][y]) {
          final Offset cellPos = maze.generator.getWarpedPosition(x + 0.5, y + 0.5, canvasSize);
          canvas.drawCircle(cellPos, 40.0, exploredPaint);
        }
      }
    }

    // 5. Carve out Flashlight Spotlight (Bright visibility centered on player)
    final double lightRadius = player.currentLightRadius;
    final Rect lightRect = Rect.fromCircle(center: playerPos, radius: lightRadius);

    final Paint flashlightPaint = Paint()
      ..blendMode = BlendMode.dstOut
      ..shader = RadialGradient(
        colors: [
          Colors.white, // Erases black mask entirely at core
          Colors.white.withValues(alpha: 0.0), // Fades to zero erasure at edges
        ],
        stops: const [0.2, 1.0],
      ).createShader(lightRect);

    canvas.drawCircle(playerPos, lightRadius, flashlightPaint);

    // 6. Restore composite
    canvas.restore();
  }
}
