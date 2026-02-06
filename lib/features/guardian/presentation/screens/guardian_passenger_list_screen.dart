import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nitoroute/core/bloc/base_state.dart';
// import '../../../auth/logic/bloc/auth_bloc.dart'; // No longer needed
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/dashboard_header.dart';
import '../../../../core/models/passenger.dart';
import '../../logic/bloc/guardian_passenger_bloc.dart';
import '../../logic/bloc/guardian_passenger_event.dart';
import 'guardian_passenger_trips_screen.dart';

class GuardianPassengerListScreen extends StatefulWidget {
  const GuardianPassengerListScreen({super.key});

  @override
  State<GuardianPassengerListScreen> createState() =>
      _GuardianPassengerListScreenState();
}

class _GuardianPassengerListScreenState
    extends State<GuardianPassengerListScreen> {
  
  @override
  void initState() {
    super.initState();
    // Trigger load if not already loaded, global bloc handles caching automatically
    context.read<GuardianPassengerBloc>().add(
      const GuardianPassengerLoadRequested(),
    );
  }

  Future<void> _refreshPassengers() async {
    final completer = Completer<void>();
    context.read<GuardianPassengerBloc>().add(
      const GuardianPassengerLoadRequested(forceRefresh: true),
    );
    // Rough way to wait for refresh, ideally listen to state change 
    // but for UI refresh indicator this is usually acceptable or we can use BlocListener
    // For now, let's just wait a bit or use the state stream?
    // Let's just return immediately, the UI will update. 
    // Actually RefreshIndicator expects a Future that completes when done.
    // Creating a proper listener is better but for now let's keep it simple.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            DashboardHeader(
              title: 'My Children',
              subtitle: 'Manage and track your children',
              showBackButton: true,
              actions: [
                HeaderAction(
                  icon: Icons.refresh, 
                  onPressed: () => context.read<GuardianPassengerBloc>().add(
                    const GuardianPassengerLoadRequested(forceRefresh: true)
                  ),
                ),
              ],
            ),
            Expanded(
              child: BlocConsumer<GuardianPassengerBloc, BlocState<List<Passenger>>>(
                listener: (context, state) {
                  if (state.isError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${state.errorMessage}')),
                    );
                  }
                },
                builder: (context, state) {
                  if (state.isLoading && !state.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  final passengers = state.data ?? [];
                  
                  if (passengers.isEmpty && !state.isLoading) {
                    return _buildEmptyState();
                  }
                  
                  return RefreshIndicator(
                    onRefresh: () async {
                       context.read<GuardianPassengerBloc>().add(
                        const GuardianPassengerLoadRequested(forceRefresh: true),
                      );
                      // Wait for next state change that is Not Loading?
                      // Simplification: just wait 1 sec for visual feedback since bloc is async
                      await Future.delayed(const Duration(seconds: 1));
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: passengers.length,
                      itemBuilder: (context, index) {
                        return _buildPassengerCard(passengers[index]);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.family_restroom_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Children Registered',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your registered children will appear here',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPassengerCard(Passenger passenger) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                GuardianPassengerTripsScreen(passenger: passenger),
          ),
        ),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Profile Picture
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    passenger.firstName.isNotEmpty ? passenger.firstName[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Passenger Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${passenger.firstName} ${passenger.lastName}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          passenger.gender == 'male'
                              ? Icons.male
                              : Icons.female,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${passenger.age} years old',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            passenger.schoolClass?.name ?? 'Unknown Class',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to view trip history',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow Icon
              Icon(
                Icons.arrow_forward_ios,
                color: AppTheme.textSecondary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
