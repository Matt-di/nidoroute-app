import 'package:flutter/material.dart';
import 'dart:async';
import 'core/config/app_initialization.dart';
import 'app.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    _setupErrorHandling();

    await AppInitialization.boot();

    runApp(const NidoRouteApp());
  }, (error, stack) {
    _handleGlobalError(error, stack);
  });
}

void _setupErrorHandling() {
  FlutterError.onError = (FlutterErrorDetails details) {
    if (_isIgnorableException(details.exception)) return;
    
    FlutterError.presentError(details);
  };
}

void _handleGlobalError(Object error, StackTrace stack) {
  if (_isIgnorableException(error)) return;

  // Global error logging would happen here
}

bool _isIgnorableException(dynamic exception) {
  final message = exception.toString().toLowerCase();
  return message.contains('platformexception') && 
         (message.contains('channel-error') || message.contains('missingplugin'));
}
