import '../services/storage_service.dart';

class GameRepository {
  final StorageService _storageService;

  late Map<String, dynamic> _progress;
  late Map<String, dynamic> _settings;

  GameRepository(this._storageService);

  Future<void> init() async {
    _progress = _storageService.loadProgress();
    _settings = _storageService.loadSettings();
  }

  // Getters
  int get unlockedLevel => _progress['unlockedLevel'] as int? ?? 1;
  int get dnaBalance => _progress['dnaBalance'] as int? ?? 0;
  String get equippedFlashlight => _progress['equippedFlashlight'] as String? ?? 'pocket_light';
  String get equippedTrail => _progress['equippedTrail'] as String? ?? 'default';
  List<String> get purchasedFlashlights => List<String>.from(_progress['purchasedFlashlights'] ?? ['pocket_light']);
  List<String> get purchasedTrails => List<String>.from(_progress['purchasedTrails'] ?? ['default']);
  List<String> get achievements => List<String>.from(_progress['achievements'] ?? []);
  int get endlessHighScore => _progress['endlessHighScore'] as int? ?? 0;

  double get musicVolume => _settings['musicVolume'] as double? ?? 0.8;
  double get sfxVolume => _settings['sfxVolume'] as double? ?? 0.8;
  bool get hapticFeedback => _settings['hapticFeedback'] as bool? ?? true;
  bool get darkMode => _settings['darkMode'] as bool? ?? true;

  // Level completion
  Future<void> completeLevel(int levelId, int dnaCollected, int completionTime) async {
    final completedMap = Map<String, dynamic>.from(_progress['completedLevels'] ?? {});
    final existing = completedMap[levelId.toString()] as Map<String, dynamic>?;

    if (existing == null) {
      completedMap[levelId.toString()] = {
        'dnaCollected': dnaCollected,
        'bestTime': completionTime,
      };
    } else {
      final int prevDna = existing['dnaCollected'] as int? ?? 0;
      final int prevTime = existing['bestTime'] as int? ?? 99999;
      completedMap[levelId.toString()] = {
        'dnaCollected': dnaCollected > prevDna ? dnaCollected : prevDna,
        'bestTime': completionTime < prevTime ? completionTime : prevTime,
      };
    }

    _progress['completedLevels'] = completedMap;

    // Unlock next level if applicable
    final currentUnlocked = unlockedLevel;
    if (levelId == currentUnlocked && levelId < 285) {
      _progress['unlockedLevel'] = levelId + 1;
    }

    // Add DNA rewards to balance
    _progress['dnaBalance'] = dnaBalance + dnaCollected;

    await _storageService.saveProgress(_progress);
  }

  // Purchases
  Future<bool> purchaseFlashlight(String id, int cost) async {
    final list = purchasedFlashlights;
    if (list.contains(id)) return true;
    if (dnaBalance < cost) return false;

    _progress['dnaBalance'] = dnaBalance - cost;
    list.add(id);
    _progress['purchasedFlashlights'] = list;
    await _storageService.saveProgress(_progress);
    return true;
  }

  Future<void> equipFlashlight(String id) async {
    if (purchasedFlashlights.contains(id)) {
      _progress['equippedFlashlight'] = id;
      await _storageService.saveProgress(_progress);
    }
  }

  Future<bool> purchaseTrail(String id, int cost) async {
    final list = purchasedTrails;
    if (list.contains(id)) return true;
    if (dnaBalance < cost) return false;

    _progress['dnaBalance'] = dnaBalance - cost;
    list.add(id);
    _progress['purchasedTrails'] = list;
    await _storageService.saveProgress(_progress);
    return true;
  }

  Future<void> equipTrail(String id) async {
    if (purchasedTrails.contains(id)) {
      _progress['equippedTrail'] = id;
      await _storageService.saveProgress(_progress);
    }
  }

  // Achievements
  Future<void> unlockAchievement(String id) async {
    final list = achievements;
    if (!list.contains(id)) {
      list.add(id);
      _progress['achievements'] = list;
      await _storageService.saveProgress(_progress);
    }
  }

  // Endless record
  Future<void> updateEndlessHighScore(int score) async {
    if (score > endlessHighScore) {
      _progress['endlessHighScore'] = score;
      await _storageService.saveProgress(_progress);
    }
  }

  // Settings updates
  Future<void> updateSettings({
    double? music,
    double? sfx,
    bool? haptic,
    bool? dark,
  }) async {
    if (music != null) _settings['musicVolume'] = music;
    if (sfx != null) _settings['sfxVolume'] = sfx;
    if (haptic != null) _settings['hapticFeedback'] = haptic;
    if (dark != null) _settings['darkMode'] = dark;

    await _storageService.saveSettings(_settings);
  }

  Future<void> resetProgress() async {
    await _storageService.clearAll();
    await init();
  }
}
