import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _loadingPercentage = 0.0;
  String _statusText = 'BOOTING PROTOCOLS...';

  @override
  void initState() {
    super.initState();
    // 3 Seconds scanning sweep loop
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _startLoading();
  }

  void _startLoading() async {
    // Simulate loading milestones
    for (int i = 1; i <= 100; i++) {
      await Future.delayed(const Duration(milliseconds: 25));
      if (!mounted) return;

      setState(() {
        _loadingPercentage = i / 100.0;
        if (i < 30) {
          _statusText = 'ENCRYPTING RIDGE CACHE...';
        } else if (i < 65) {
          _statusText = 'WARPING MATRIX VECTORS...';
        } else if (i < 90) {
          _statusText = 'BYPASSING SECURITY FIREWALL...';
        } else {
          _statusText = 'GRID LOADED. ACCESS GRANTED.';
        }
      });
    }

    // Load completed, transition to main menu
    if (mounted) {
      context.go('/menu');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          // Cyberpunk Grid Background
          Positioned.fill(
            child: Opacity(
              opacity: 0.08,
              child: GridPaper(
                color: AppTheme.accentBlue,
                divisions: 1,
                subdivisions: 1,
                interval: 18,
              ),
            ),
          ),

          // Diagnostic Corner Crosshairs
          Positioned(top: 40, left: 20, child: _buildCrosshair()),
          Positioned(top: 40, right: 20, child: _buildCrosshair()),
          Positioned(bottom: 40, left: 20, child: _buildCrosshair()),
          Positioned(bottom: 40, right: 20, child: _buildCrosshair()),

          // Main Scanning Column
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'ECHOPRINT',
                  style: TextStyle(
                    fontFamily: 'Courier New',
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentNeon,
                    letterSpacing: 6.0,
                    shadows: [
                      Shadow(color: AppTheme.accentNeon, blurRadius: 10),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Scanning Area
                AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: FingerprintPainter(_controller.value),
                      size: const Size(200, 240),
                    );
                  },
                ),
                const SizedBox(height: 50),

                // Status Terminal Text
                Text(
                  _statusText,
                  style: const TextStyle(
                    fontFamily: 'Courier New',
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.accentBlue,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),

                // Progress Loading Bar
                Container(
                  width: 240,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    border: Border.all(color: AppTheme.accentBlue.withValues(alpha: 0.3), width: 1.0),
                  ),
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: _loadingPercentage,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: AppTheme.accentNeon,
                        boxShadow: [
                          BoxShadow(color: AppTheme.accentNeon, blurRadius: 6, spreadRadius: 1),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Percentage indicator
                Text(
                  '${(_loadingPercentage * 100).toInt()}%',
                  style: const TextStyle(
                    fontFamily: 'Courier New',
                    fontSize: 12,
                    color: AppTheme.accentNeon,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCrosshair() {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.accentBlue.withValues(alpha: 0.4), width: 1.0),
      ),
      child: const Center(
        child: Icon(Icons.add, size: 8, color: Colors.white24),
      ),
    );
  }
}

class FingerprintPainter extends CustomPainter {
  final double scanProgress; // 0.0 to 1.0

  FingerprintPainter(this.scanProgress);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    final Paint ridgePaint = Paint()
      ..color = AppTheme.accentBlue.withValues(alpha: 0.4)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final Paint scannedPaint = Paint()
      ..color = AppTheme.accentNeon
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    final double laserY = scanProgress * size.height;

    // Draw fingerprint ridges (arches and loops)
    for (int i = 1; i <= 6; i++) {
      final double r = i * 16.0;
      final Path path = Path();
      path.moveTo(cx - r, cy + r * 0.7);
      path.quadraticBezierTo(cx - r, cy - r * 0.9, cx, cy - r * 0.9);
      path.quadraticBezierTo(cx + r, cy - r * 0.9, cx + r, cy + r * 0.7);

      canvas.drawPath(path, ridgePaint);

      // Check intersection with laser sweep line
      final double peakY = cy - r * 0.9;
      final double bottomY = cy + r * 0.7;

      if (laserY >= peakY && laserY <= bottomY) {
        // Draw highlighted scan trace
        canvas.drawPath(path, scannedPaint);
      }
    }

    // Laser Sweep Beam Line
    final Paint laserPaint = Paint()
      ..color = AppTheme.accentNeon
      ..strokeWidth = 2.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

    canvas.drawLine(Offset(0, laserY), Offset(size.width, laserY), laserPaint);
  }

  @override
  bool shouldRepaint(covariant FingerprintPainter oldDelegate) =>
      oldDelegate.scanProgress != scanProgress;
}
