import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/bloc/base_bloc.dart';
import '../../../../core/bloc/base_state.dart';
import '../../../../core/services/settings_service.dart';
import 'settings_event.dart';

/// Simple SettingsBloc demonstrating the base class benefits
class SettingsBloc extends BaseBloc<SettingsEvent, BlocState<AppSettings>> {
  final SettingsService _settingsService;

  SettingsBloc({required SettingsService settingsService}) 
      : _settingsService = settingsService,
        super(const BlocState.initial()) {
    on<SettingsLoadRequested>(_onSettingsLoadRequested);
    on<SettingsThemeModeChanged>(_onSettingsThemeModeChanged);
    on<SettingsLanguageChanged>(_onSettingsLanguageChanged);
    on<SettingsPushNotificationsChanged>(_onSettingsPushNotificationsChanged);
    on<SettingsSmsNotificationsChanged>(_onSettingsSmsNotificationsChanged);
    on<SettingsResetToDefaults>(_onSettingsResetToDefaults);
  }

  Future<void> _onSettingsLoadRequested(
    SettingsLoadRequested event,
    Emitter<BlocState<AppSettings>> emit,
  ) async {
    await executeSilent<AppSettings>(
      operation: () async {
        // Settings are already loaded in the service during initialization
        final settings = _settingsService.currentSettings;
        return settings;
      },
      onSuccess: (settings) {
        emit(BlocState.success(settings));
      },
      onError: (error) {
        // Fallback to default settings silently
        emit(BlocState.success(AppSettings.defaults()));
      },
    );
  }

  Future<void> _onSettingsThemeModeChanged(
    SettingsThemeModeChanged event,
    Emitter<BlocState<AppSettings>> emit,
  ) async {
    await executeWithLoading<AppSettings>(
      operation: () async {
        await _settingsService.updateThemeMode(event.themeMode);
        return _settingsService.currentSettings;
      },
      onSuccess: (settings) {
        emit(BlocState.success(settings));
      },
      onError: (error) {
        emit(BlocState.error(
          message: 'Failed to update theme: ${error.toString()}',
        ));
      },
    );
  }

  Future<void> _onSettingsLanguageChanged(
    SettingsLanguageChanged event,
    Emitter<BlocState<AppSettings>> emit,
  ) async {
    await executeWithLoading<AppSettings>(
      operation: () async {
        await _settingsService.updateLanguage(event.language);
        return _settingsService.currentSettings;
      },
      onSuccess: (settings) {
        emit(BlocState.success(settings));
      },
      onError: (error) {
        emit(BlocState.error(
          message: 'Failed to update language: ${error.toString()}',
        ));
      },
    );
  }

  Future<void> _onSettingsPushNotificationsChanged(
    SettingsPushNotificationsChanged event,
    Emitter<BlocState<AppSettings>> emit,
  ) async {
    await executeWithLoading<AppSettings>(
      operation: () async {
        await _settingsService.updatePushNotifications(event.enabled);
        return _settingsService.currentSettings;
      },
      onSuccess: (settings) {
        emit(BlocState.success(settings));
      },
      onError: (error) {
        emit(BlocState.error(
          message: 'Failed to update push notifications: ${error.toString()}',
        ));
      },
    );
  }

  Future<void> _onSettingsSmsNotificationsChanged(
    SettingsSmsNotificationsChanged event,
    Emitter<BlocState<AppSettings>> emit,
  ) async {
    await executeWithLoading<AppSettings>(
      operation: () async {
        await _settingsService.updateSmsNotifications(event.enabled);
        return _settingsService.currentSettings;
      },
      onSuccess: (settings) {
        emit(BlocState.success(settings));
      },
      onError: (error) {
        emit(BlocState.error(
          message: 'Failed to update SMS notifications: ${error.toString()}',
        ));
      },
    );
  }

  Future<void> _onSettingsResetToDefaults(
    SettingsResetToDefaults event,
    Emitter<BlocState<AppSettings>> emit,
  ) async {
    await executeWithLoading<AppSettings>(
      operation: () async {
        await _settingsService.resetToDefaults();
        return _settingsService.currentSettings;
      },
      onSuccess: (settings) {
        emit(BlocState.success(settings));
      },
      onError: (error) {
        emit(BlocState.error(
          message: 'Failed to reset settings: ${error.toString()}',
        ));
      },
    );
  }
}
