import 'package:app/features/shared/infrastructure/database/objectbox.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'core/di/dependency_injection.dart';

final logger = Logger();

/// Global ObjectBox instance following official singleton pattern
late ObjectBox objectbox;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize ObjectBox following official pattern
    logger.i('Initializing ObjectBox...');
    objectbox = await ObjectBox.create();
    logger.i('ObjectBox initialized successfully');

    // Run app with providers
    runApp(
      ProviderScope(
        overrides: [
          // Override ObjectBox provider with initialized instance
          objectBoxProvider.overrideWithValue(objectbox),
        ],
        child: const MyApp(),
      ),
    );
  } catch (e, stackTrace) {
    logger.e(
      'Failed to initialize application',
      error: e,
      stackTrace: stackTrace,
    );
    runApp(const ErrorApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AirlineConnect',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const MyHomePage(title: 'AirlineConnect'),
    );
  }
}

class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('AirlineConnect 登機牌管理系統', style: TextStyle(fontSize: 24)),
            SizedBox(height: 20),
            Text(
              'DDD + TDD + Hook-Riverpod 實戰',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Text(
              'ObjectBox 資料庫已初始化完成',
              style: TextStyle(fontSize: 14, color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Close ObjectBox on app shutdown
    objectbox.close();
    super.dispose();
  }
}

class ErrorApp extends StatelessWidget {
  const ErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Application failed to initialize',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please restart the application',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
