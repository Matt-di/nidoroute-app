import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import 'api_service.dart';
import 'auth_service.dart';

/// Theme mode enum
enum AppThemeMode {
  light,
  dark,
  system;

  String get displayName {
    switch (this) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.system:
        return 'System';
    }
  }

  String get description {
    switch (this) {
      case AppThemeMode.light:
        return 'Always use light theme';
      case AppThemeMode.dark:
        return 'Always use dark theme';
      case AppThemeMode.system:
        return 'Follow system theme';
    }
  }

  IconData get icon {
    switch (this) {
      case AppThemeMode.light:
        return Icons.wb_sunny;
      case AppThemeMode.dark:
        return Icons.nightlight_round;
      case AppThemeMode.system:
        return Icons.settings_suggest;
    }
  }
}

/// Language enum
enum AppLanguage {
  english,
  amharic;

  String get displayName {
    switch (this) {
      case AppLanguage.english:
        return 'English';
      case AppLanguage.amharic:
        return 'አማርኛ';
    }
  }

  String get description {
    switch (this) {
      case AppLanguage.english:
        return 'English language';
      case AppLanguage.amharic:
        return 'Amharic language';
    }
  }

  IconData get icon {
    switch (this) {
      case AppLanguage.english:
        return Icons.language;
      case AppLanguage.amharic:
        return Icons.translate;
    }
  }

  String get code {
    switch (this) {
      case AppLanguage.english:
        return 'en';
      case AppLanguage.amharic:
        return 'am';
    }
  }
}

/// App settings model
class AppSettings {
  final AppThemeMode themeMode;
  final AppLanguage language;
  final bool pushNotifications;
  final bool smsNotifications;
  final int itemsPerPage;
  final bool enableRealTimeUpdates;

  AppSettings({
    required this.themeMode,
    required this.language,
    required this.pushNotifications,
    required this.smsNotifications,
    required this.itemsPerPage,
    required this.enableRealTimeUpdates,
  });

  factory AppSettings.defaults() {
    return AppSettings(
      themeMode: AppThemeMode.system,
      language: AppLanguage.english,
      pushNotifications: true,
      smsNotifications: false,
      itemsPerPage: 15,
      enableRealTimeUpdates: true,
    );
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      themeMode: AppThemeMode.values.firstWhere(
        (e) => e.name == json['themeMode'],
        orElse: () => AppThemeMode.system,
      ),
      language: AppLanguage.values.firstWhere(
        (e) => e.name == json['language'],
        orElse: () => AppLanguage.english,
      ),
      pushNotifications: json['pushNotifications'] ?? true,
      smsNotifications: json['smsNotifications'] ?? false,
      itemsPerPage: json['itemsPerPage'] ?? 15,
      enableRealTimeUpdates: json['enableRealTimeUpdates'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.name,
      'language': language.name,
      'pushNotifications': pushNotifications,
      'smsNotifications': smsNotifications,
      'itemsPerPage': itemsPerPage,
      'enableRealTimeUpdates': enableRealTimeUpdates,
    };
  }

  AppSettings copyWith({
    AppThemeMode? themeMode,
    AppLanguage? language,
    bool? pushNotifications,
    bool? smsNotifications,
    int? itemsPerPage,
    bool? enableRealTimeUpdates,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      language: language ?? this.language,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      smsNotifications: smsNotifications ?? this.smsNotifications,
      itemsPerPage: itemsPerPage ?? this.itemsPerPage,
      enableRealTimeUpdates:
          enableRealTimeUpdates ?? this.enableRealTimeUpdates,
    );
  }
}

/// Service for managing app settings with local storage and backend sync
class SettingsService {
  static const String _settingsKey = 'app_settings';
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final ApiService _apiService = ApiService();

  AppSettings? _currentSettings;

  AppSettings get currentSettings {
    _currentSettings ??= AppSettings.defaults();
    return _currentSettings!;
  }

  /// Initialize settings from local storage
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_settingsKey);

      if (settingsJson != null) {
        final settingsMap = jsonDecode(settingsJson) as Map<String, dynamic>;
        _currentSettings = AppSettings.fromJson(settingsMap);
      } else {
        _currentSettings = AppSettings.defaults();
        await _saveSettings();
      }
    } catch (e) {
      _currentSettings = AppSettings.defaults();
    }
  }

  /// Update theme mode
  Future<void> updateThemeMode(AppThemeMode themeMode) async {
    _currentSettings = currentSettings.copyWith(themeMode: themeMode);
    await _saveSettings();
    await _syncToBackend('default_theme', themeMode.name);
  }

  /// Update language
  Future<void> updateLanguage(AppLanguage language) async {
    _currentSettings = currentSettings.copyWith(language: language);
    await _saveSettings();
    await _syncToBackend('locale', language.code);
  }

  /// Update push notifications
  Future<void> updatePushNotifications(bool enabled) async {
    _currentSettings = currentSettings.copyWith(pushNotifications: enabled);
    await _saveSettings();
    await _syncToBackend('push_notifications_enabled', enabled);
  }

  /// Update SMS notifications
  Future<void> updateSmsNotifications(bool enabled) async {
    _currentSettings = currentSettings.copyWith(smsNotifications: enabled);
    await _saveSettings();
    await _syncToBackend('sms_notifications_enabled', enabled);
  }

  /// Reset all settings to defaults
  Future<void> resetToDefaults() async {
    _currentSettings = AppSettings.defaults();
    await _saveSettings();
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = jsonEncode(currentSettings.toJson());
      await prefs.setString(_settingsKey, settingsJson);
    } catch (e) {
      // Handle  error
    }
  }

  /// Sync setting to backend
  Future<void> _syncToBackend(String key, dynamic value) async {
    try {
      final authService = AuthService();
      final token = await authService.getToken();

      if (token == null) {
        debugPrint('No auth token available for settings sync');
        return; // Skip sync if not authenticated
      }

      final response = await _apiService.post(
        '${AppConfig.baseUrl}/settings/value/$key',
        data: {'value': value},
      );

      if (response.statusCode != 200 || !(response.data['success'] as bool)) {
        debugPrint(
          'Failed to sync setting $key to backend: ${response.statusCode}',
        );
        // Don't throw exception, just log it to avoid app crashes
      }
    } catch (e) {
      debugPrint('Failed to sync setting $key to backend: $e');
    }
  }

  Future<void> syncFromBackend() async {
    try {
      final response = await _apiService.get(
        '${AppConfig.baseUrl}/settings/grouped',
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;

        final Map<String, dynamic> backendSettings = {};

        data.forEach((category, settings) {
          if (settings is List) {
            for (var setting in settings) {
              if (setting is Map<String, dynamic> &&
                  setting.containsKey('key')) {
                final key = setting['key'];
                final value = setting['processed_value'] ?? setting['value'];
                backendSettings[key] = value;
              }
            }
          }
        });

        final updatedSettings = AppSettings(
          themeMode: AppThemeMode.values.firstWhere(
            (e) => e.name == backendSettings['default_theme'],
            orElse: () => currentSettings.themeMode,
          ),
          language: AppLanguage.values.firstWhere(
            (e) => e.code == backendSettings['locale'],
            orElse: () => currentSettings.language,
          ),
          pushNotifications:
              backendSettings['push_notifications_enabled'] ??
              currentSettings.pushNotifications,
          smsNotifications:
              backendSettings['sms_notifications_enabled'] ??
              currentSettings.smsNotifications,
          itemsPerPage:
              backendSettings['items_per_page'] ?? currentSettings.itemsPerPage,
          enableRealTimeUpdates:
              backendSettings['enable_real_time_updates'] ??
              currentSettings.enableRealTimeUpdates,
        );

        _currentSettings = updatedSettings;
        await _saveSettings();
      }
    } catch (e) {
      debugPrint('Failed to sync settings from backend: $e');
    }
  }
}
