import '../../../../core/services/settings_service.dart';

abstract class SettingsEvent {}

class SettingsLoadRequested extends SettingsEvent {}

class SettingsThemeModeChanged extends SettingsEvent {
  final AppThemeMode themeMode;
  SettingsThemeModeChanged(this.themeMode);
}

class SettingsLanguageChanged extends SettingsEvent {
  final AppLanguage language;
  SettingsLanguageChanged(this.language);
}

class SettingsPushNotificationsChanged extends SettingsEvent {
  final bool enabled;
  SettingsPushNotificationsChanged(this.enabled);
}

class SettingsSmsNotificationsChanged extends SettingsEvent {
  final bool enabled;
  SettingsSmsNotificationsChanged(this.enabled);
}

class SettingsResetToDefaults extends SettingsEvent {}
