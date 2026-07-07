import 'package:flutter/material.dart';
import 'core/config/dependency_injection.dart';
import 'core/config/router.dart';
import 'core/config/theme.dart';

void main() async {
  // Ensure Flutter engine bindings are fully initialized before DI/storage setup
  WidgetsFlutterBinding.ensureInitialized();

  // Run Dependency Injection system setup (Hive, GetIt, Audio)
  await setupDependencyInjection();

  runApp(const EchoPrintApp());
}

class EchoPrintApp extends StatelessWidget {
  const EchoPrintApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'EchoPrint',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
