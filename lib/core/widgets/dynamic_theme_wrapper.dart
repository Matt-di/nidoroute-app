import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nitoroute/core/bloc/base_state.dart';
import '../../features/settings/logic/bloc/settings_bloc.dart';
import '../../core/services/settings_service.dart';
import '../theme/app_theme.dart';

class DynamicThemeWrapper extends StatelessWidget {
  final Widget child;

  const DynamicThemeWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, BlocState<AppSettings>>(
      builder: (context, settingsState) {
        // Determine theme mode based on settings
        ThemeMode themeMode = ThemeMode.system;
        if (settingsState.isSuccess && settingsState.data != null) {
          final themeModeSetting = settingsState.data!.themeMode;
          switch (themeModeSetting) {
            case AppThemeMode.light:
              themeMode = ThemeMode.light;
              break;
            case AppThemeMode.dark:
              themeMode = ThemeMode.dark;
              break;
            case AppThemeMode.system:
              themeMode = ThemeMode.system;
              break;
          }
        }

        // Get current system brightness for system theme mode
        final systemBrightness =
            WidgetsBinding.instance.platformDispatcher.platformBrightness;

        return Theme(
          data: _getCurrentTheme(themeMode, systemBrightness),
          child: child,
        );
      },
    );
  }

  ThemeData _getCurrentTheme(ThemeMode themeMode, Brightness systemBrightness) {
    switch (themeMode) {
      case ThemeMode.light:
        return AppTheme.lightTheme;
      case ThemeMode.dark:
        return AppTheme.darkTheme;
      case ThemeMode.system:
        return systemBrightness == Brightness.dark
            ? AppTheme.darkTheme
            : AppTheme.lightTheme;
    }
  }
}
