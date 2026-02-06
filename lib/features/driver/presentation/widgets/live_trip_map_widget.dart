import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../logic/bloc/live_trip_bloc.dart';
import '../../logic/bloc/live_trip_state.dart';
import '../../../../core/widgets/live_tracker_map.dart';

class LiveTripMapWidget extends StatelessWidget {
  const LiveTripMapWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LiveTripBloc, LiveTripState>(
      builder: (context, state) {
        if (state is LiveTripReady) {
          return LiveTrackerMap(
            initialPosition: state.currentPosition,
            markers: state.markers,
            polylines: state.polylines,
            showUserLocation: true,
            followTarget: true,
            targetPosition: state.currentPosition,
            targetBearing: state.bearing,
          );
        }

        if (state is LiveTripError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(state.message, style: const TextStyle(color: Colors.red)),
              ],
            ),
          );
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}
