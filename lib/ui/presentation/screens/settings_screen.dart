import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/dependency_injection.dart';
import '../../../core/config/theme.dart';
import '../../../core/repository/game_repository.dart';
import '../../../core/services/audio_service.dart';
import '../widgets/ad_banner_widget.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final GameRepository _repository = locator<GameRepository>();
  final AudioService _audioService = locator<AudioService>();

  late double _musicVol;
  late double _sfxVol;
  late bool _haptic;

  @override
  void initState() {
    super.initState();
    _musicVol = _repository.musicVolume;
    _sfxVol = _repository.sfxVolume;
    _haptic = _repository.hapticFeedback;
  }

  void _saveSettings() {
    _repository.updateSettings(
      music: _musicVol,
      sfx: _sfxVol,
      haptic: _haptic,
    );
    _audioService.updateVolumes(_musicVol, _sfxVol);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SETTINGS', style: TextStyle(fontFamily: 'Courier New', color: AppTheme.accentNeon)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.accentNeon),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        color: AppTheme.background,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AUDIO CONTROLLER',
              style: TextStyle(fontFamily: 'Courier New', color: AppTheme.accentBlue, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const Divider(color: AppTheme.accentBlue, thickness: 1),
            const SizedBox(height: 16),
            _buildSliderSetting(
              'AMBIENT MUSIC',
              _musicVol,
              (val) {
                setState(() {
                  _musicVol = val;
                });
                _saveSettings();
              },
            ),
            const SizedBox(height: 16),
            _buildSliderSetting(
              'SOUND EFFECTS',
              _sfxVol,
              (val) {
                setState(() {
                  _sfxVol = val;
                });
                _saveSettings();
              },
            ),
            const SizedBox(height: 40),
            const Text(
              'HAPTICS & VIBRATION',
              style: TextStyle(fontFamily: 'Courier New', color: AppTheme.accentBlue, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const Divider(color: AppTheme.accentBlue, thickness: 1),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('SCREEN HAPTICS', style: TextStyle(fontFamily: 'Courier New', fontSize: 14)),
              value: _haptic,
              activeThumbColor: AppTheme.accentNeon,
              onChanged: (val) {
                setState(() {
                  _haptic = val;
                });
                _saveSettings();
              },
            ),
            const Spacer(),
            Center(
              child: OutlinedButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final router = GoRouter.of(context);
                  await _repository.resetProgress();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('All data cleared.', style: TextStyle(fontFamily: 'Courier New')),
                      backgroundColor: AppTheme.accentPurple,
                    ),
                  );
                  router.pop();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.accentRed,
                  side: const BorderSide(color: AppTheme.accentRed, width: 1),
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
                child: const Text('WIPE DATA', style: TextStyle(fontFamily: 'Courier New', letterSpacing: 2)),
              ),
            ),
            const SizedBox(height: 24),
            const SafeArea(
              top: false,
              child: AdBannerWidget(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderSetting(String label, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontFamily: 'Courier New', fontSize: 12)),
            Text('${(value * 100).toInt()}%', style: const TextStyle(fontFamily: 'Courier New', fontSize: 12, color: AppTheme.accentNeon)),
          ],
        ),
        Slider(
          value: value,
          onChanged: onChanged,
          activeColor: AppTheme.accentNeon,
          inactiveColor: AppTheme.darkGray,
        ),
      ],
    );
  }
}
