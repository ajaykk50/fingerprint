import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/theme.dart';
import '../../../game/engine/echo_print_game.dart';
import '../../../game/engine/game_cubit.dart';

class GamePlayScreen extends StatefulWidget {
  final int levelId;

  const GamePlayScreen({super.key, required this.levelId});

  @override
  State<GamePlayScreen> createState() => _GamePlayScreenState();
}

class _GamePlayScreenState extends State<GamePlayScreen> {
  late GameCubit _gameCubit;
  late EchoPrintGame _game;
  Offset _swipeDelta = Offset.zero;

  @override
  void initState() {
    super.initState();
    _gameCubit = GameCubit(levelId: widget.levelId);
    _game = EchoPrintGame(gameCubit: _gameCubit);
    _gameCubit.startGame();
  }

  @override
  void dispose() {
    _gameCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _gameCubit,
      child: Scaffold(
        body: Stack(
          children: [
            // The Flame Game Widget with Swiping and Tapping Control
            GestureDetector(
              onTapUp: (details) {
                // Get tap position relative to screen layout
                final tapPos = details.localPosition;
                final player = _game.player;
                final playerScreenPos = player.position.toOffset();
                final tapDirection = tapPos - playerScreenPos;
                
                player.move(tapDirection);
              },
              onPanStart: (details) {
                _swipeDelta = Offset.zero;
              },
              onPanUpdate: (details) {
                _swipeDelta += details.delta;
                
                // If sliding distance exceeds 25 pixels, trigger a step
                if (_swipeDelta.distance > 25.0) {
                  _game.player.move(_swipeDelta);
                  // Reset delta accumulator to allow continuous sliding along corridors
                  _swipeDelta = Offset.zero;
                }
              },
              child: GameWidget(game: _game),
            ),

            // Neon HUD Overlay
            Positioned(
              top: 40,
              left: 20,
              right: 20,
              child: _buildHudHeader(),
            ),

            // Game State Overlays (GameOver, Complete, Pause)
            BlocBuilder<GameCubit, GameState>(
              builder: (context, state) {
                if (state.status == GameStatus.paused) {
                  return _buildPauseOverlay();
                } else if (state.status == GameStatus.gameOver) {
                  return _buildGameOverOverlay();
                } else if (state.status == GameStatus.completed) {
                  return _buildLevelCompleteOverlay();
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHudHeader() {
    return BlocBuilder<GameCubit, GameState>(
      builder: (context, state) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Battery indicator
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BATTERY CELL',
                  style: TextStyle(fontFamily: 'Courier New', color: AppTheme.accentBlue, fontSize: 10),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 120,
                  height: 12,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.accentBlue, width: 1),
                  ),
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: state.battery / 100.0,
                    child: Container(
                      color: state.battery > 20.0 ? AppTheme.accentNeon : AppTheme.accentRed,
                    ),
                  ),
                ),
              ],
            ),
            // DNA & Pause
            Row(
              children: [
                Text(
                  'DNA: ${state.dnaCollected}',
                  style: const TextStyle(fontFamily: 'Courier New', color: AppTheme.accentNeon, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.pause, color: AppTheme.accentNeon),
                  onPressed: () => _gameCubit.pauseGame(),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildPauseOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'SCANNER PAUSED',
              style: TextStyle(fontFamily: 'Courier New', color: AppTheme.accentBlue, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            _buildOverlayButton('RESUME', () => _gameCubit.resumeGame()),
            const SizedBox(height: 16),
            _buildOverlayButton('ABORT SCAN', () => context.pop()),
          ],
        ),
      ),
    );
  }

  Widget _buildGameOverOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.9),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'CORE LOCKDOWN',
              style: TextStyle(fontFamily: 'Courier New', color: AppTheme.accentRed, fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'SIGNAL LOST - BATTERY CRITICAL',
              style: TextStyle(fontFamily: 'Courier New', color: AppTheme.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 40),
            _buildOverlayButton('RETRY SCAN', () {
              context.pop();
              context.push('/game/${widget.levelId}');
            }),
            const SizedBox(height: 16),
            _buildOverlayButton('EXIT', () => context.pop()),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelCompleteOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.9),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'ESCAPE SUCCESSFUL',
              style: TextStyle(fontFamily: 'Courier New', color: AppTheme.accentNeon, fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'FINGERPRINT CORE BYPASSED',
              style: TextStyle(fontFamily: 'Courier New', color: AppTheme.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 40),
            _buildOverlayButton('NEXT LEVEL', () {
              context.pop();
              context.push('/game/${widget.levelId + 1}');
            }),
            const SizedBox(height: 16),
            _buildOverlayButton('LEVEL LIST', () => context.pop()),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlayButton(String text, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.accentNeon,
        side: const BorderSide(color: AppTheme.accentNeon, width: 1),
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
      child: Text(text, style: const TextStyle(fontFamily: 'Courier New', letterSpacing: 2)),
    );
  }
}
