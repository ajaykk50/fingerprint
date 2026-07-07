import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/theme.dart';

class LevelSelectScreen extends StatelessWidget {
  const LevelSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SELECT MATRIX', style: TextStyle(fontFamily: 'Courier New', color: AppTheme.accentNeon)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.accentNeon),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: 20, // World 1 levels
          itemBuilder: (context, index) {
            final levelNum = index + 1;
            return InkWell(
              onTap: () => context.push('/game/$levelNum'),
              child: Container(
                decoration: BorderBoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(color: AppTheme.accentBlue, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    '$levelNum',
                    style: const TextStyle(
                      fontFamily: 'Courier New',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentBlue,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Simple Helper widget for retro pixelated border decoration
class BorderBoxDecoration extends Decoration {
  final Color color;
  final Border border;

  const BorderBoxDecoration({required this.color, required this.border});

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) {
    return _BorderBoxPainter(color, border);
  }
}

class _BorderBoxPainter extends BoxPainter {
  final Color color;
  final Border border;

  _BorderBoxPainter(this.color, this.border);

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final Paint paint = Paint()..color = color;
    final Rect rect = offset & (configuration.size ?? Size.zero);
    canvas.drawRect(rect, paint);
    
    // Draw neon outline borders
    final borderPaint = Paint()
      ..color = border.top.color
      ..strokeWidth = border.top.width
      ..style = PaintingStyle.stroke;
    canvas.drawRect(rect, borderPaint);
  }
}
