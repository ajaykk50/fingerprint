import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../../core/config/theme.dart';
import 'fingerprint_generator.dart';
import '../../engine/echo_print_game.dart';

class MazeComponent extends Component with HasGameRef<EchoPrintGame> {
  final int cols;
  final int rows;
  final FingerprintType type;
  
  late FingerprintGenerator generator;
  late List<List<bool>> explored;

  MazeComponent({
    required this.cols,
    required this.rows,
    required this.type,
    int? seed,
  }) {
    generator = FingerprintGenerator(cols: cols, rows: rows, type: type, seed: seed);
    // Initialize Fog of War matrix
    explored = List.generate(cols, (_) => List.generate(rows, (_) => false));
  }

  // Mark cell and its immediate neighbors as explored
  void exploreCell(int x, int y) {
    if (x >= 0 && x < cols && y >= 0 && y < rows) {
      explored[x][y] = true;
      
      // Also reveal adjacent cells slightly for readability
      if (x > 0) explored[x - 1][y] = true;
      if (x < cols - 1) explored[x + 1][y] = true;
      if (y > 0) explored[x][y - 1] = true;
      if (y < rows - 1) explored[x][y + 1] = true;
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final Size canvasSize = Size(gameRef.size.x, gameRef.size.y);

    // 1. Draw Fingerprint Core (Exit)
    final coreCell = generator.getCoreCell();
    final Offset corePos = generator.getWarpedPosition(coreCell.x + 0.5, coreCell.y + 0.5, canvasSize);
    
    _renderCorePortal(canvas, corePos);

    // 2. Draw Warped Fingerprint Ridge Walls
    final Paint wallPaint = Paint()
      ..color = AppTheme.accentBlue.withValues(alpha: 0.8)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int x = 0; x < cols; x++) {
      for (int y = 0; y < rows; y++) {
        final cell = generator.grid[x][y];

        // Corners in warped space
        final Offset topLeft = generator.getWarpedPosition(x.toDouble(), y.toDouble(), canvasSize);
        final Offset topRight = generator.getWarpedPosition((x + 1).toDouble(), y.toDouble(), canvasSize);
        final Offset bottomLeft = generator.getWarpedPosition(x.toDouble(), (y + 1).toDouble(), canvasSize);
        final Offset bottomRight = generator.getWarpedPosition((x + 1).toDouble(), (y + 1).toDouble(), canvasSize);

        // Draw individual walls
        if (cell.topWall) {
          canvas.drawLine(topLeft, topRight, wallPaint);
        }
        if (cell.bottomWall) {
          canvas.drawLine(bottomLeft, bottomRight, wallPaint);
        }
        if (cell.leftWall) {
          canvas.drawLine(topLeft, bottomLeft, wallPaint);
        }
        if (cell.rightWall) {
          canvas.drawLine(topRight, bottomRight, wallPaint);
        }
      }
    }
  }

  // Draw a biometric scanning terminal glow style core
  void _renderCorePortal(Canvas canvas, Offset position) {
    final Paint glowPaint = Paint()
      ..color = AppTheme.accentNeon.withValues(alpha: 0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15.0);

    final Paint ringPaint = Paint()
      ..color = AppTheme.accentNeon
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final Paint corePaint = Paint()
      ..color = AppTheme.accentNeon.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    // Draw glowing circles
    canvas.drawCircle(position, 30, glowPaint);
    canvas.drawCircle(position, 20, ringPaint);
    canvas.drawCircle(position, 12, ringPaint..strokeWidth = 1.0);
    canvas.drawCircle(position, 5, corePaint);
  }
}
