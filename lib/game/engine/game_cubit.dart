import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../core/config/dependency_injection.dart';
import '../../core/repository/game_repository.dart';
import '../../core/services/audio_service.dart';

enum GameStatus { initial, playing, paused, completed, gameOver }

class GameState extends Equatable {
  final int levelId;
  final GameStatus status;
  final double battery; // 0.0 to 100.0
  final int dnaCollected;
  final int sonarPulses;
  final int compassUses;
  final int timeFreezeUses;
  final int shieldUses;
  final int teleportUses;
  final int nightVisionUses;
  final bool hasKey;
  final double timeElapsed; // in seconds

  const GameState({
    required this.levelId,
    required this.status,
    required this.battery,
    required this.dnaCollected,
    required this.sonarPulses,
    required this.compassUses,
    required this.timeFreezeUses,
    required this.shieldUses,
    required this.teleportUses,
    required this.nightVisionUses,
    required this.hasKey,
    required this.timeElapsed,
  });

  factory GameState.initial(int levelId) {
    return GameState(
      levelId: levelId,
      status: GameStatus.initial,
      battery: 100.0,
      dnaCollected: 0,
      sonarPulses: 3,
      compassUses: 1,
      timeFreezeUses: 1,
      shieldUses: 1,
      teleportUses: 1,
      nightVisionUses: 1,
      hasKey: false,
      timeElapsed: 0.0,
    );
  }

  GameState copyWith({
    int? levelId,
    GameStatus? status,
    double? battery,
    int? dnaCollected,
    int? sonarPulses,
    int? compassUses,
    int? timeFreezeUses,
    int? shieldUses,
    int? teleportUses,
    int? nightVisionUses,
    bool? hasKey,
    double? timeElapsed,
  }) {
    return GameState(
      levelId: levelId ?? this.levelId,
      status: status ?? this.status,
      battery: battery ?? this.battery,
      dnaCollected: dnaCollected ?? this.dnaCollected,
      sonarPulses: sonarPulses ?? this.sonarPulses,
      compassUses: compassUses ?? this.compassUses,
      timeFreezeUses: timeFreezeUses ?? this.timeFreezeUses,
      shieldUses: shieldUses ?? this.shieldUses,
      teleportUses: teleportUses ?? this.teleportUses,
      nightVisionUses: nightVisionUses ?? this.nightVisionUses,
      hasKey: hasKey ?? this.hasKey,
      timeElapsed: timeElapsed ?? this.timeElapsed,
    );
  }

  @override
  List<Object?> get props => [
        levelId,
        status,
        battery,
        dnaCollected,
        sonarPulses,
        compassUses,
        timeFreezeUses,
        shieldUses,
        teleportUses,
        nightVisionUses,
        hasKey,
        timeElapsed,
      ];
}

class GameCubit extends Cubit<GameState> {
  final GameRepository _repository = locator<GameRepository>();
  final AudioService _audioService = locator<AudioService>();

  GameCubit({required int levelId}) : super(GameState.initial(levelId));

  void startGame() {
    emit(state.copyWith(status: GameStatus.playing));
    _audioService.playBgm('ambient_explore.mp3');
  }

  void pauseGame() {
    if (state.status == GameStatus.playing) {
      emit(state.copyWith(status: GameStatus.paused));
      _audioService.pauseBgm();
    }
  }

  void resumeGame() {
    if (state.status == GameStatus.paused) {
      emit(state.copyWith(status: GameStatus.playing));
      _audioService.resumeBgm();
    }
  }

  void drainBattery(double amount) {
    if (state.status != GameStatus.playing) return;
    
    final newBattery = (state.battery - amount).clamp(0.0, 100.0);
    
    if (newBattery == 0.0) {
      emit(state.copyWith(battery: 0.0, status: GameStatus.gameOver));
      _audioService.stopBgm();
      _audioService.playSfx('collision.wav'); // Game over sound
    } else {
      // Play low battery warning sound periodically
      if (newBattery < 20.0 && state.battery >= 20.0) {
        _audioService.playSfx('battery_warning.wav');
      }
      emit(state.copyWith(battery: newBattery));
    }
  }

  void rechargeBattery(double amount) {
    if (state.status != GameStatus.playing) return;
    final newBattery = (state.battery + amount).clamp(0.0, 100.0);
    emit(state.copyWith(battery: newBattery));
    _audioService.playSfx('battery_pickup.wav');
  }

  void collectDna(int amount) {
    if (state.status != GameStatus.playing) return;
    emit(state.copyWith(dnaCollected: state.dnaCollected + amount));
    _audioService.playSfx('battery_pickup.wav');
  }

  void obtainKey() {
    if (state.status != GameStatus.playing) return;
    emit(state.copyWith(hasKey: true));
    _audioService.playSfx('gate_open.wav');
  }

  void useSonar() {
    if (state.status != GameStatus.playing) return;
    if (state.sonarPulses <= 0) return;
    emit(state.copyWith(sonarPulses: state.sonarPulses - 1));
    _audioService.playSfx('sonar_ping.wav');
  }

  void useAbility(String abilityId) {
    if (state.status != GameStatus.playing) return;
    switch (abilityId) {
      case 'compass':
        if (state.compassUses > 0) emit(state.copyWith(compassUses: state.compassUses - 1));
        break;
      case 'time_freeze':
        if (state.timeFreezeUses > 0) emit(state.copyWith(timeFreezeUses: state.timeFreezeUses - 1));
        break;
      case 'shield':
        if (state.shieldUses > 0) emit(state.copyWith(shieldUses: state.shieldUses - 1));
        break;
      case 'teleport':
        if (state.teleportUses > 0) emit(state.copyWith(teleportUses: state.teleportUses - 1));
        break;
      case 'night_vision':
        if (state.nightVisionUses > 0) emit(state.copyWith(nightVisionUses: state.nightVisionUses - 1));
        break;
    }
  }

  void incrementTime(double dt) {
    if (state.status != GameStatus.playing) return;
    emit(state.copyWith(timeElapsed: state.timeElapsed + dt));
  }

  void completeLevel() {
    if (state.status != GameStatus.playing) return;
    emit(state.copyWith(status: GameStatus.completed));
    _audioService.stopBgm();
    _audioService.playSfx('level_complete.wav');
    
    // Save to repository
    _repository.completeLevel(
      state.levelId,
      state.dnaCollected,
      state.timeElapsed.toInt(),
    );
  }

  void failGame() {
    if (state.status != GameStatus.playing) return;
    emit(state.copyWith(status: GameStatus.gameOver));
    _audioService.stopBgm();
    _audioService.playSfx('collision.wav');
  }
}
