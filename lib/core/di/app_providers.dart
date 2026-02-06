import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nitoroute/core/services/auth_service.dart';
import 'package:nitoroute/core/services/trip_service.dart';
import 'package:nitoroute/core/services/route_service.dart';
import 'package:nitoroute/core/services/notification_service.dart';
import 'package:nitoroute/core/services/settings_service.dart';
import 'package:nitoroute/core/services/guardian_service.dart';
import 'package:nitoroute/core/services/admin_service.dart';
import 'package:nitoroute/core/services/reverb_service.dart';
import 'package:nitoroute/core/services/trip_tracking_service.dart';
import 'package:nitoroute/core/services/icon_cache_service.dart';
import 'package:nitoroute/core/services/connection_service.dart';
import 'package:nitoroute/core/repositories/trip_repository.dart';
import 'package:nitoroute/core/bloc/connection_bloc.dart';
import 'package:nitoroute/core/bloc/trip_bloc.dart';
import 'package:nitoroute/features/auth/logic/bloc/auth_bloc.dart';
import 'package:nitoroute/features/auth/logic/bloc/auth_event.dart';
import 'package:nitoroute/features/trip/logic/bloc/trip_detail_bloc.dart';
import 'package:nitoroute/features/admin/logic/bloc/admin_bloc.dart';
import 'package:nitoroute/features/notification/logic/bloc/notification_bloc_simple.dart';
// import 'package:nitoroute/features/notification/logic/bloc/notification_event.dart';
import 'package:nitoroute/features/settings/logic/bloc/settings_bloc.dart';
import 'package:nitoroute/features/settings/logic/bloc/settings_event.dart';
import 'package:nitoroute/features/guardian/logic/bloc/guardian_trip_list_bloc.dart';
import 'package:nitoroute/features/guardian/logic/bloc/guardian_passenger_bloc.dart';

/// List of all repository providers for the app
List<RepositoryProvider> getRepositoryProviders() {
  return [
    RepositoryProvider(create: (context) => AuthService()),
    RepositoryProvider(create: (context) => TripService()),
    RepositoryProvider(
      create: (context) => TripRepository(
        tripService: context.read<TripService>(),
      ),
    ),
    RepositoryProvider(create: (context) => RouteService()),
    RepositoryProvider(create: (context) => GuardianService()),
    RepositoryProvider(create: (context) => AdminService()),
    RepositoryProvider(create: (context) => ReverbService()),
    RepositoryProvider(create: (context) => TripTrackingService()),
    RepositoryProvider(create: (context) => IconCacheService()),
    RepositoryProvider(create: (context) => ConnectionService()),
    RepositoryProvider(create: (context) => SettingsService()),
    RepositoryProvider(create: (context) => NotificationService()),
  ];
}

/// List of all bloc providers for the app
List<BlocProvider> getBlocProviders() {
  return [
    BlocProvider<ConnectionBloc>(
      create: (context) =>
          ConnectionBloc(connectionService: context.read<ConnectionService>()),
    ),

══╡ EXCEPTION CAUGHT BY WIDGETS LIBRARY
╞═══════════════════════════════════════════════════════════
The following ProviderNotFoundException was thrown building
KeyedSubtree-[GlobalKey#e7e86]:
Error: Could not find the correct Provider<AuthService> above
this
_InheritedProviderScope<AuthBloc?> Widget

This happens because you used a `BuildContext` that does not
include the provider
of your choice. There are a few common scenarios:

- You added a new provider in your `main.dart` and performed a
hot-reload.
  To fix, perform a hot-restart.

- The provider you are trying to read is in a different route.

  Providers are "scoped". So if you insert of provider inside a
  route, then
  other routes will not be able to access that provider.

- You used a `BuildContext` that is an ancestor of the provider
you are trying to read.

  Make sure that _InheritedProviderScope<AuthBloc?> is under
  your
MultiProvider/Provider<AuthService>.
  This usually happens when you are creating a provider and
  trying to read it immediately.

  For example, instead of:

  ```
  Widget build(BuildContext context) {
    return Provider<Example>(
      create: (_) => Example(),
      // Will throw a ProviderNotFoundError, because `context`
      is associated
      // to the widget that is the parent of
      `Provider<Example>`
      child: Text(context.watch<Example>().toString()),
    );
  }
  ```

  consider using `builder` like so:

  ```
  Widget build(BuildContext context) {
    return Provider<Example>(
      create: (_) => Example(),
      // we use `builder` to obtain a new `BuildContext` that
      has access to the provider
      builder: (context, child) {
        // No longer throws
        return Text(context.watch<Example>().toString());
      }
    );
  }
  ```

If none of these solutions work, consider asking for help on
StackOverflow:
https://stackoverflow.com/questions/tagged/flutter

The relevant error-causing widget was:
  Scaffold
  Scaffold:file:///Users/matewosd/Documents/Pr/SchoolTransport/
  nitoroute/lib/features/auth/presentation/screens/login_screen
  .dart:79:12

When the exception was thrown, this was the stack:
#0      Provider._inheritedElementOf
(package:provider/src/provider.dart:377:7)
#1      Provider.of (package:provider/src/provider.dart:327:30)
#2      ReadContext.read
(package:provider/src/provider.dart:683:21)
#3      getBlocProviders.<anonymous closure>
(package:nitoroute/core/di/app_providers.dart:57:58)
#4      _CreateInheritedProviderState.value
(package:provider/src/inherited_provider.dart:749:36)
#5      _InheritedProviderScopeElement.value
(package:provider/src/inherited_provider.dart:603:33)
#6      Provider.of (package:provider/src/provider.dart:337:37)
#7      ReadContext.read
(package:provider/src/provider.dart:683:21)
#8      _BlocConsumerState.initState
(package:flutter_bloc/src/bloc_consumer.dart:130:36)
#9      StatefulElement._firstBuild
(package:flutter/src/widgets/framework.dart:5950:55)
#10     ComponentElement.mount
(package:flutter/src/widgets/framework.dart:5793:5)
...     Normal element mounting (25 frames)
#35     Element.inflateWidget
(package:flutter/src/widgets/framework.dart:4587:20)
#36     MultiChildRenderObjectElement.inflateWidget
(package:flutter/src/widgets/framework.dart:7264:36)
#37     MultiChildRenderObjectElement.mount
(package:flutter/src/widgets/framework.dart:7279:32)
...     Normal element mounting (136 frames)
#173    Element.inflateWidget
(package:flutter/src/widgets/framework.dart:4587:20)
#174    MultiChildRenderObjectElement.inflateWidget
(package:flutter/src/widgets/framework.dart:7264:36)
#175    MultiChildRenderObjectElement.mount
(package:flutter/src/widgets/framework.dart:7279:32)
...     Normal element mounting (194 frames)
#369    Element.inflateWidget
(package:flutter/src/widgets/framework.dart:4587:20)
#370    MultiChildRenderObjectElement.inflateWidget
(package:flutter/src/widgets/framework.dart:7264:36)
#371    MultiChildRenderObjectElement.mount
(package:flutter/src/widgets/framework.dart:7279:32)
...     Normal element mounting (481 frames)
#852    _InheritedProviderScopeElement.mount
(package:provider/src/inherited_provider.dart:424:11)
...     Normal element mounting (7 frames)
#859    SingleChildWidgetElementMixin.mount
(package:nested/nested.dart:222:11)
...     Normal element mounting (7 frames)
#866    SingleChildWidgetElementMixin.mount
(package:nested/nested.dart:222:11)
...     Normal element mounting (7 frames)
#873    _NestedHookElement.mount
(package:nested/nested.dart:187:11)
...     Normal element mounting (7 frames)
#880    _InheritedProviderScopeElement.mount
(package:provider/src/inherited_provider.dart:424:11)
...     Normal element mounting (7 frames)
#887    SingleChildWidgetElementMixin.mount
(package:nested/nested.dart:222:11)
...     Normal element mounting (7 frames)
#894    SingleChildWidgetElementMixin.mount
(package:nested/nested.dart:222:11)
...     Normal element mounting (7 frames)
#901    _NestedHookElement.mount
(package:nested/nested.dart:187:11)
...     Normal element mounting (7 frames)
#908    _InheritedProviderScopeElement.mount
(package:provider/src/inherited_provider.dart:424:11)
...     Normal element mounting (7 frames)
#915    SingleChildWidgetElementMixin.mount
(package:nested/nested.dart:222:11)
...     Normal element mounting (7 frames)
#922    SingleChildWidgetElementMixin.mount
(package:nested/nested.dart:222:11)
...     Normal element mounting (7 frames)
#929    _NestedHookElement.mount
(package:nested/nested.dart:187:11)
...     Normal element mounting (7 frames)
#936    _InheritedProviderScopeElement.mount
(package:provider/src/inherited_provider.dart:424:11)
...     Normal element mounting (7 frames)
#943    SingleChildWidgetElementMixin.mount
(package:nested/nested.dart:222:11)
...     Normal element mounting (7 frames)
#950    SingleChildWidgetElementMixin.mount
(package:nested/nested.dart:222:11)
...     Normal element mounting (7 frames)
#957    _NestedHookElement.mount
(package:nested/nested.dart:187:11)
...     Normal element mounting (7 frames)
#964    _InheritedProviderScopeElement.mount
(package:provider/src/inherited_provider.dart:424:11)
...     Normal element mounting (7 frames)
#971    SingleChildWidgetElementMixin.mount
(package:nested/nested.dart:222:11)
...     Normal element mounting (7 frames)
#978    SingleChildWidgetElementMixin.mount
(package:nested/nested.dart:222:11)
...     Normal element mounting (7 frames)
#985    _NestedHookElement.mount
(package:nested/nested.dart:187:11)
...     Normal element mounting (7 frames)
#992    _InheritedProviderScopeElement.mount
(package:provider/src/inherited_provider.dart:424:11)
...     Normal element mounting (7 frames)
#999    SingleChildWidgetElementMixin.mount
(package:nested/nested.dart:222:11)
...     Normal element mounting (7 frames)
#1006   SingleChildWidgetElementMixin.mount
(package:nested/nested.dart:222:11)
...     Normal element mounting (7 frames)
#1013   _NestedHookElement.mount
(package:nested/nested.dart:187:11)
...     Normal element mounting (7 frames)
#1020   _InheritedProviderScopeElement.mount
(package:provider/src/inherited_provider.dart:424:11)
...     Normal element mounting (7 frames)
#1027   SingleChildWidgetElementMixin.mount
(package:nested/nested.dart:222:11)
...     Normal element mounting (7 frames)
#1034   SingleChildWidgetElementMixin.mount
(package:nested/nested.dart:222:11)
...     Normal element mounting (7 frames)
#1041   _NestedHookElement.mount
(package:nested/nested.dart:187:11)
...     Normal element mounting (7 frames)
#1048   _InheritedProviderScopeElement.mount
(package:provider/src/inherited_provider.dart:424:11)
...     Normal element mounting (7 frames)
#1055   SingleChildWidgetElementMixin.mount
(package:nested/nested.dart:222:11)
...     Normal element mounting (7 frames)
#1062   SingleChildWidgetElementMixin.mount
(package:nested/nested.dart:222:11)
...     Normal element mounting (7 frames)
#1069   _NestedHookElement.mount
(package:nested/nested.dart:187:11)
...     Normal element mounting (7 frames)
#1076   _InheritedProviderScopeElement.mount
(package:provider/src/inherited_provider.dart:424:11)
...     Normal element mounting (7 frames)
#1083   SingleChildWidgetElementMixin.mount
(package:nested/nested.dart:222:11)
...     Normal element mounting (7 frames)
#1090   SingleChildWidgetElementMixin.mount
(package:nested/nested.dart:222:11)
...     Normal element mounting (7 frames)
#1097   _NestedHookElement.mount
(package:nested/nested.dart:187:11)
...     Normal element mounting (7 frames)
#1104   SingleChildWidgetElementMixin.mount
(package:nested/nested.dart:222:11)
...     Normal element mounting (13 frames)
#1117   _InheritedProviderScopeElement.mount
(package:provider/src/inherited_provider.dart:424:11)
...     Normal element mounting (7 frames)
#1124   _InheritedProviderScopeElement.mount
(package:provider/src/inherited_provider.dart:424:11)
...     Normal element mounting (7 frames)
#1131   _InheritedProviderScopeElement.mount
(package:provider/src/inherited_provider.dart:424:11)
...     Normal element mounting (7 frames)
#1138   _InheritedProviderScopeElement.mount
(package:provider/src/inherited_provider.dart:424:11)
...     Normal element mounting (7 frames)
#1145   _InheritedProviderScopeElement.mount
(package:provider/src/inherited_provider.dart:424:11)
...     Normal element mounting (7 frames)
#1152   _InheritedProviderScopeElement.mount
(package:provider/src/inherited_provider.dart:424:11)
...     Normal element mounting (7 frames)
#1159   _InheritedProviderScopeElement.mount
(package:provider/src/inherited_provider.dart:424:11)
...     Normal element mounting (7 frames)
#1166   _InheritedProviderScopeElement.mount
(package:provider/src/inherited_provider.dart:424:11)
...     Normal element mounting (7 frames)
#1173   _InheritedProviderScopeElement.mount
(package:provider/src/inherited_provider.dart:424:11)
...     Normal element mounting (7 frames)
#1180   _InheritedProviderScopeElement.mount
(package:provider/src/inherited_provider.dart:424:11)
...     Normal element mounting (7 frames)
#1187   _InheritedProviderScopeElement.mount
(package:provider/src/inherited_provider.dart:424:11)
...     Normal element mounting (7 frames)
#1194   _InheritedProviderScopeElement.mount
(package:provider/src/inherited_provider.dart:424:11)
...     Normal element mounting (7 frames)
#1201   SingleChildWidgetElementMixin.mount
(package:nested/nested.dart:222:11)
...     Normal element mounting (7 frames)
#1208   _NestedHookElement.mount
(package:nested/nested.dart:187:11)
...     Normal element mounting (7 frames)
#1215   SingleChildWidgetElementMixin.mount
(package:nested/nested.dart:222:11)
...     Normal element mounting (71 frames)
#1286   Element.inflateWidget
(package:flutter/src/widgets/framework.dart:4587:20)
#1287   Element.updateChild
(package:flutter/src/widgets/framework.dart:4059:18)
#1288   _RawViewElement._updateChild
(package:flutter/src/widgets/view.dart:481:16)
#1289   _RawViewElement.mount
(package:flutter/src/widgets/view.dart:504:5)
...     Normal element mounting (15 frames)
#1304   Element.inflateWidget
(package:flutter/src/widgets/framework.dart:4587:20)
#1305   Element.updateChild
(package:flutter/src/widgets/framework.dart:4059:18)
#1306   RootElement._rebuild
(package:flutter/src/widgets/binding.dart:2030:16)
#1307   RootElement.mount
(package:flutter/src/widgets/binding.dart:1999:5)
#1308   RootWidget.attach.<anonymous closure>
(package:flutter/src/widgets/binding.dart:1952:18)
#1309   BuildOwner.buildScope
(package:flutter/src/widgets/framework.dart:3101:19)
#1310   RootWidget.attach
(package:flutter/src/widgets/binding.dart:1951:13)
#1311   WidgetsBinding.attachToBuildOwner
(package:flutter/src/widgets/binding.dart:1627:27)
#1312   WidgetsBinding.attachRootWidget
(package:flutter/src/widgets/binding.dart:1612:5)
#1313   WidgetsBinding.scheduleAttachRootWidget.<anonymous
closure> (package:flutter/src/widgets/binding.dart:1598:7)
#1324   _RawReceivePort._handleMessage
(dart:isolate-patch/isolate_patch.dart:193:12)
(elided 10 frames from class _Timer, dart:async, and
dart:async-patch)

═══════════════════════════════════════════════════════════════
═════════════════════════════════════

Another exception was thrown: Error: Could not find the correct
Provider<ConnectionService> above this
_InheritedProviderScope<ConnectionBloc?> Widget
flutter: Async platform channel error handled gracefully: PlatformException(channel-error, Unable to establish connection on channel: "dev.flutter.pigeon.path_provider_foundation.PathProviderApi.getDirectoryPath"., null, null)
flutter: Async platform channel error handled gracefully: PlatformException(channel-error, Unable to establish connection on channel: "dev.flutter.pigeon.path_provider_foundation.PathProviderApi.getDirectoryPath"., null, null)
flutter: Async platform channel error handled gracefully: PlatformException(channel-error, Unable to establish connection on channel: "dev.flutter.pigeon.path_provider_foundation.PathProviderApi.getDirectoryPath"., null, null)
    BlocProvider<AuthBloc>(
      create: (context) => AuthBloc(authService: context.read<AuthService>())
        ..add(const AuthCheckRequested()),
    ),
    BlocProvider<NotificationBloc>(
      create: (context) => NotificationBloc()
        ..add(NotificationLoadRequested()),
    ),
    BlocProvider(
      create: (context) =>
          TripBloc(tripRepository: context.read<TripRepository>()),
    ),
    BlocProvider(
      create: (context) => TripDetailBloc(
        tripRepository: context.read<TripRepository>(),
      ),
    ),
    BlocProvider(
      create: (context) =>
          AdminBloc(adminService: context.read<AdminService>()),
    ),
    BlocProvider<SettingsBloc>(
      create: (context) => SettingsBloc(settingsService: context.read<SettingsService>())
        ..add(SettingsLoadRequested()),
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
  ];
}
