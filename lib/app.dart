import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/services/notification_service.dart';
import 'core/services/settings_service.dart';
import 'core/services/auth_service.dart';
import 'core/services/trip_service.dart';
import 'core/services/route_service.dart';
import 'core/services/guardian_service.dart';
import 'core/services/admin_service.dart';
import 'core/services/reverb_service.dart';
import 'core/services/trip_tracking_service.dart';
import 'core/services/icon_cache_service.dart';
import 'core/services/connection_service.dart';
import 'core/repositories/trip_repository.dart';
import 'core/bloc/connection_bloc.dart';
import 'core/bloc/trip_bloc.dart';
import 'features/auth/logic/bloc/auth_bloc.dart';
import 'features/auth/logic/bloc/auth_event.dart';
import 'features/trip/logic/bloc/trip_detail_bloc.dart';
import 'features/admin/logic/bloc/admin_bloc.dart';
import 'features/notification/logic/bloc/notification_bloc_simple.dart';
import 'features/settings/logic/bloc/settings_bloc.dart';
import 'features/settings/logic/bloc/settings_event.dart';
import 'features/guardian/logic/bloc/guardian_trip_list_bloc.dart';
import 'features/guardian/logic/bloc/guardian_passenger_bloc.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'core/routing/app_router.dart';

class NidoRouteApp extends StatelessWidget {
  const NidoRouteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(create: (_) => ConnectionService()),
        RepositoryProvider(create: (_) => AuthService()),
        RepositoryProvider(create: (_) => SettingsService()),
        RepositoryProvider(create: (_) => NotificationService()),
        RepositoryProvider(create: (_) => ReverbService()),
        RepositoryProvider(create: (_) => IconCacheService()),
        
        RepositoryProvider(create: (_) => TripService()),
        RepositoryProvider(create: (_) => RouteService()),
        RepositoryProvider(create: (_) => GuardianService()),
        RepositoryProvider(create: (_) => AdminService()),
        RepositoryProvider(create: (_) => TripTrackingService()),
        
        RepositoryProvider(
          create: (context) => TripRepository(
            tripService: context.read<TripService>(),
          ),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AuthBloc(
              authService: context.read<AuthService>(),
            )..add(const AuthCheckRequested()),
          ),
          
          BlocProvider(
            create: (context) => ConnectionBloc(
              connectionService: context.read<ConnectionService>(),
            ),
          ),
          
          BlocProvider(
            create: (context) => SettingsBloc(
              settingsService: context.read<SettingsService>(),
            )..add(SettingsLoadRequested()),
          ),

          BlocProvider(
            create: (context) => NotificationBloc(
              notificationService: context.read<NotificationService>(),
            ),
          ),
          BlocProvider(
            create: (context) => TripBloc(
              tripRepository: context.read<TripRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => TripDetailBloc(
              tripRepository: context.read<TripRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => AdminBloc(
              adminService: context.read<AdminService>(),
            ),
          ),
          BlocProvider(
            create: (context) => GuardianTripListBloc(
              tripRepository: context.read<TripRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => GuardianPassengerBloc(
              guardianService: context.read<GuardianService>(),
            ),
          ),
        ],
        child: MaterialApp(
          title: 'Nidoroute',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          initialRoute: AppRouter.root,
          routes: AppRouter.routes,
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}
