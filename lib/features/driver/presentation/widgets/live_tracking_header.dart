import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/models/trip.dart';
import '../../../trip/logic/bloc/trip_detail_bloc.dart';
import './simple_trip_stops_sheet.dart';

class LiveTrackingHeader extends StatelessWidget {
  final Trip trip;
  final VoidCallback onBack;
  final VoidCallback? onSOS;

  const LiveTrackingHeader({
    super.key,
    required this.trip,
    required this.onBack,
    this.onSOS,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: onBack,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Live Trip',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  'ROUTE #${trip.id.substring(0, 6).toUpperCase()}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade500,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  final bloc = context.read<TripDetailBloc>();
                  SimpleTripStopsSheet.show(context, trip: trip, bloc: bloc);
                },
                icon: const Icon(
                  Icons.list_alt_rounded,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                tooltip: 'View All Stops',
              ),
              const SizedBox(width: 8),
              if (onSOS != null)
                GestureDetector(
                  onTap: onSOS,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.emergency_rounded, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'SOS',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
