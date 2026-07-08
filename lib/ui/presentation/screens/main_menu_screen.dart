import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/theme.dart';
import '../widgets/ad_banner_widget.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          color: AppTheme.background,
        ),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'ECHOPRINT',
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ESCAPE THE FINGERPRINT',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.textSecondary,
                            letterSpacing: 4.0,
                          ),
                    ),
                    const SizedBox(height: 60),
                    _buildMenuButton(context, 'ENTER SCANNER', () => context.push('/levels')),
                    const SizedBox(height: 20),
                    _buildMenuButton(context, 'SETTINGS', () => context.push('/settings')),
                  ],
                ),
              ),
            ),
            const SafeArea(
              top: false,
              child: AdBannerWidget(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context, String text, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.accentNeon,
        side: const BorderSide(color: AppTheme.accentNeon, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero, // Minimal sharp edges
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Courier New',
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 2.0,
        ),
      ),
    );
  }
}
