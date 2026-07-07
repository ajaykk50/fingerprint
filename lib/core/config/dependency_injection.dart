import 'package:get_it/get_it.dart';
import '../services/storage_service.dart';
import '../services/audio_service.dart';
import '../repository/game_repository.dart';

final GetIt locator = GetIt.instance;

Future<void> setupDependencyInjection() async {
  // Storage Service
  final storageService = StorageService();
  await storageService.init();
  locator.registerSingleton<StorageService>(storageService);

  // Game Repository
  final gameRepository = GameRepository(storageService);
  await gameRepository.init();
  locator.registerSingleton<GameRepository>(gameRepository);

  // Audio Service
  final audioService = AudioService();
  await audioService.init();
  locator.registerSingleton<AudioService>(audioService);
}
