import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/logic/bloc/auth_bloc.dart';
import '../../core/bloc/base_state.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/connection_status_banner.dart';
import 'unified_bottom_nav_bar.dart';
import 'navigation_manager.dart';

class UnifiedNavigationWrapper extends StatefulWidget {
  const UnifiedNavigationWrapper({super.key});

  @override
  State<UnifiedNavigationWrapper> createState() =>
      _UnifiedNavigationWrapperState();
}

class _UnifiedNavigationWrapperState extends State<UnifiedNavigationWrapper> {
  late int _currentIndex;
  late String _userRole;
  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _currentIndex = 0;
    _initializeNavigation();
  }

  void _initializeNavigation() {
    final authState = context.read<AuthBloc>().state;
    if (authState.isSuccess && authState.data?.role != null) {
      _userRole = authState.data!.role!;
      _screens = NavigationManager.getScreensForRole(_userRole);
    } else {
      _userRole = 'driver'; // Default fallback
      _screens = NavigationManager.getScreensForRole(_userRole);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, BlocState<AuthData>>(
      listener: (context, state) {
        if (state.isSuccess && state.data?.role != null && state.data!.role != _userRole) {
          setState(() {
            _userRole = state.data!.role!;
            _screens = NavigationManager.getScreensForRole(_userRole);
            _currentIndex = 0; // Reset to home when role changes
          });
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Stack(
          children: [
            // Main content
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.02, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey<int>(_currentIndex),
                child: _screens[_currentIndex],
              ),
            ),
            // Connection banner as overlay
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: const ConnectionStatusBanner(),
            ),
          ],
        ),
        floatingActionButton:
            NavigationManager.shouldShowFab(_currentIndex, _userRole)
            ? FloatingActionButton(
                heroTag: 'unified_nav_fab',
                onPressed: () =>
                    NavigationManager.handleFabPress(context, _userRole),
                backgroundColor: const Color(0xFF03173D),
                child: const Icon(Icons.add, color: Colors.white),
              )
            : null,
        bottomNavigationBar: UnifiedBottomNavBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          userRole: _userRole,
        ),
      ),
    );
  }
}
