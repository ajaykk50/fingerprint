import 'package:flame_audio/flame_audio.dart';

class AudioService {
  double _musicVolume = 0.8;
  double _sfxVolume = 0.8;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    
    // Preload critical sound effects to avoid lag during gameplay
    await FlameAudio.audioCache.loadAll([
      'sfx/sonar_ping.wav',
      'sfx/battery_pickup.wav',
      'sfx/battery_warning.wav',
      'sfx/level_complete.wav',
      'sfx/gate_open.wav',
      'sfx/collision.wav',
      'sfx/click.wav',
    ]);
    _initialized = true;
  }

  void updateVolumes(double musicVolume, double sfxVolume) {
    _musicVolume = musicVolume;
    _sfxVolume = sfxVolume;
    FlameAudio.bgm.audioPlayer.setVolume(_musicVolume);
  }

  // Play background music
  void playBgm(String filename) {
    if (!_initialized) return;
    final path = filename.startsWith('music/') ? filename : 'music/$filename';
    FlameAudio.bgm.play(path, volume: _musicVolume);
  }

  void stopBgm() {
    if (!_initialized) return;
    FlameAudio.bgm.stop();
  }

  void pauseBgm() {
    if (!_initialized) return;
    FlameAudio.bgm.pause();
  }

  void resumeBgm() {
    if (!_initialized) return;
    FlameAudio.bgm.resume();
  }

  // Play sound effect
  void playSfx(String filename) {
    if (!_initialized) return;
    final path = filename.startsWith('sfx/') ? filename : 'sfx/$filename';
    FlameAudio.play(path, volume: _sfxVolume);
  }
}
