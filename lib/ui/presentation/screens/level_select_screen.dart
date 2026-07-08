import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/dependency_injection.dart';
import '../../../core/config/theme.dart';
import '../../../core/repository/game_repository.dart';
import '../../../core/services/ad_service.dart';
import '../widgets/ad_banner_widget.dart';

class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({super.key});

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  @override
  Widget build(BuildContext context) {
    final int unlockedLevel = locator<GameRepository>().unlockedLevel;

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
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: 20, // Exactly 20 levels
                itemBuilder: (context, index) {
                  final levelNum = index + 1;
                  final bool isUnlocked = levelNum <= unlockedLevel;

                  return InkWell(
                    onTap: isUnlocked
                        ? () {
                            // Show the interstitial ad first, then transition to gameplay
                            locator<AdService>().showInterstitial(() async {
                              if (mounted) {
                                await context.push('/game/$levelNum');
                                // Refresh the matrix locking display when returning from gameplay
                                if (mounted) {
                                  setState(() {});
                                }
                              }
                            });
                          }
                        : null, // Tap disabled for locked levels
                    child: Container(
                      decoration: BorderBoxDecoration(
                        color: Colors.transparent,
                        border: Border.all(
                          color: isUnlocked ? AppTheme.accentBlue : Colors.white24,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: isUnlocked
                            ? Text(
                                '$levelNum',
                                style: const TextStyle(
                                  fontFamily: 'Courier New',
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.accentBlue,
                                ),
                              )
                            : const Icon(
                                Icons.lock_outline,
                                color: Colors.white24,
                                size: 22,
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SafeArea(
            top: false,
            child: AdBannerWidget(),
          ),
        ],
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
