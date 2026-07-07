import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

class StorageService {
  static const String _boxName = 'echoprint_storage';
  static const String _progressKey = 'player_progress';
  static const String _settingsKey = 'game_settings';

  late Box _box;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  // Load progress
  Map<String, dynamic> loadProgress() {
    final String? jsonStr = _box.get(_progressKey);
    if (jsonStr != null) {
      try {
        return json.decode(jsonStr) as Map<String, dynamic>;
      } catch (e) {
        // Fallback if decode fails
      }
    }
    return _defaultProgress();
  }

  // Save progress
  Future<void> saveProgress(Map<String, dynamic> progress) async {
    final String jsonStr = json.encode(progress);
    await _box.put(_progressKey, jsonStr);
  }

  // Load settings
  Map<String, dynamic> loadSettings() {
    final String? jsonStr = _box.get(_settingsKey);
    if (jsonStr != null) {
      try {
        return json.decode(jsonStr) as Map<String, dynamic>;
      } catch (e) {
        // Fallback
      }
    }
    return _defaultSettings();
  }

  // Save settings
  Future<void> saveSettings(Map<String, dynamic> settings) async {
    final String jsonStr = json.encode(settings);
    await _box.put(_settingsKey, jsonStr);
  }

  // Default initial progress state
  Map<String, dynamic> _defaultProgress() {
    return {
      'unlockedLevel': 1,
      'completedLevels': <String, dynamic>{}, // levelId: {dnaCollected: int, bestTime: int}
      'dnaBalance': 0,
      'purchasedFlashlights': ['pocket_light'],
      'equippedFlashlight': 'pocket_light',
      'purchasedTrails': ['default'],
      'equippedTrail': 'default',
      'achievements': <String>[],
      'endlessHighScore': 0,
    };
  }

  // Default initial settings state
  Map<String, dynamic> _defaultSettings() {
    return {
      'musicVolume': 0.8,
      'sfxVolume': 0.8,
      'hapticFeedback': true,
      'darkMode': true,
      'language': 'en',
    };
  }

  Future<void> clearAll() async {
    await _box.clear();
  }
}
