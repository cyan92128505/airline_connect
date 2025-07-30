import 'package:app/core/bootstrap/contracts/initialization_context.dart';
import 'package:app/core/bootstrap/initialization_step.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Configure system UI settings for consistent appearance
class SystemUIInitializationStep extends InitializationStep {
  const SystemUIInitializationStep()
    : super(name: 'System UI Configuration', isCritical: false);

  @override
  Future<void> execute(InitializationContext context) async {
    // Lock orientation to portrait modes
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Configure system UI overlay
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }
}
