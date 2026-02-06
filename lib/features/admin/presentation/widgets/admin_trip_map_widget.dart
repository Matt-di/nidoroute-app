import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../trip/logic/bloc/trip_detail_bloc.dart';
import '../../../../core/bloc/base_state.dart';
import '../../../../core/bloc/trip_bloc.dart';
import '../../../../core/services/icon_cache_service.dart';
import '../../../../core/utils/map_utils.dart';

class AdminTripMapWidget extends StatefulWidget {
  const AdminTripMapWidget({super.key});

  @override
  State<AdminTripMapWidget> createState() => _AdminTripMapWidgetState();
}

class _AdminTripMapWidgetState extends State<AdminTripMapWidget> {
  final IconCacheService _iconCache = IconCacheService();
  GoogleMapController? _mapController;
  bool _iconsLoaded = false;

  @override
  void initState() {
    super.initState();
    _initializeIcons();
  }

  Future<void> _initializeIcons() async {
    if (!_iconCache.isReady) {
      await _iconCache.initialize();
    }
    if (mounted) {
      setState(() {
        _iconsLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_iconsLoaded) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return BlocBuilder<TripDetailBloc, BlocState<dynamic>>(
      builder: (context, state) {
        Set<Marker> markers = {};
        Set<Polyline> polylines = {};
        LatLng? center;

        if (state.isSuccess && state.data != null) {
          final tripDetailData = state.data as TripDetailData;
          final trip = tripDetailData.trip;
          final deliveries = tripDetailData.deliveries ?? [];

          // Generate markers for deliveries
          for (final delivery in deliveries) {
            final targetLoc = delivery.targetLocation(trip.tripType);
            if (targetLoc == null) continue;

            final pos = LatLng(targetLoc.latitude, targetLoc.longitude);
            BitmapDescriptor? icon;
            
            if (delivery.status == 'picked_up' || delivery.status == 'dropped_off' || delivery.status == 'completed') {
              icon = _iconCache.icons.completed;
            } else {
              icon = trip.tripType == 'pickup' ? _iconCache.icons.pickup : _iconCache.icons.dropoff;
            }

            markers.add(Marker(
              markerId: MarkerId('delivery_${delivery.id}'),
              position: pos,
              icon: icon ?? BitmapDescriptor.defaultMarker,
              infoWindow: InfoWindow(title: delivery.passengerName ?? 'Passenger'),
            ));
          }

          // Add driver marker if available
          if (trip.driverLocation != null) {
            final driverPos = LatLng(trip.driverLocation!.latitude, trip.driverLocation!.longitude);
            markers.add(Marker(
              markerId: const MarkerId('driver'),
              position: driverPos,
              icon: _iconCache.icons.bus ?? BitmapDescriptor.defaultMarker,
              anchor: Offset(0.5, 0.5),
              zIndex: 100,
            ));
            center = driverPos;
          }

          // Generate polylines
          if (trip.polyline != null && trip.polyline!.isNotEmpty) {
            polylines.add(Polyline(
              polylineId: const PolylineId('route'),
              points: MapUtils.decodePolyline(trip.polyline!),
              color: Color(0xFF2196F3),
              width: 5,
            ));
          }

          // Set center to first delivery if no driver location
          if (center == null && deliveries.isNotEmpty) {
            final firstLoc = deliveries.first.targetLocation(trip.tripType);
            if (firstLoc != null) {
              center = LatLng(firstLoc.latitude, firstLoc.longitude);
            }
          }
        }

        // Default center if nothing else is available
        center ??= const LatLng(0, 0);

        return GoogleMap(
          initialCameraPosition: CameraPosition(
            target: center,
            zoom: 13,
          ),
          markers: markers,
          polylines: polylines,
          myLocationButtonEnabled: false,
          compassEnabled: true,
          mapToolbarEnabled: false,
          onMapCreated: (controller) {
            _mapController = controller;
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
