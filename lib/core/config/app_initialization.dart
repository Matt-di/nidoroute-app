import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Handles app-wide initialization and bootstrapping
class AppInitialization {
  static bool _isInitialized = false;

  static Future<void> boot() async {
    if (_isInitialized) return;

    try {
      await dotenv.load();
      await _configureSystemUI();
      await _initializeHydratedBloc();

      _isInitialized = true;
    } catch (e, _) {
      rethrow;
    }
  }

  static Future<void> _initializeHydratedBloc() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      HydratedBloc.storage = await HydratedStorage.build(
        storageDirectory: directory,
      );
    } catch (e) {
      // App continues without persistent state
    }
  }

  static Future<void> _configureSystemUI() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }
}
