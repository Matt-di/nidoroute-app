import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'base_bloc.dart';
import 'base_state.dart';
import '../models/trip.dart';
import '../models/delivery.dart';
import '../repositories/trip_repository.dart';

/// Trip data models for different use cases
class TripListData extends Equatable {
  final List<Trip> trips;
  final Map<String, dynamic>? driverStats;
  final bool hasReachedMax;
  final int currentPage;
  final int totalPages;
  final int totalCount;
  final TripFilters? filters;

  const TripListData({
    this.trips = const [],
    this.driverStats,
    this.hasReachedMax = false,
    this.currentPage = 1,
    this.totalPages = 1,
    this.totalCount = 0,
    this.filters,
  });

  factory TripListData.withTrips(List<Trip> trips, {Map<String, dynamic>? driverStats}) {
    return TripListData(trips: trips, driverStats: driverStats);
  }

  factory TripListData.withPagination({
    required List<Trip> trips,
    required bool hasReachedMax,
    required int currentPage,
    required int totalPages,
    required int totalCount,
    TripFilters? filters,
  }) {
    return TripListData(
      trips: trips,
      hasReachedMax: hasReachedMax,
      currentPage: currentPage,
      totalPages: totalPages,
      totalCount: totalCount,
      filters: filters,
    );
  }

  @override
  List<Object?> get props => [trips, driverStats, hasReachedMax, currentPage, totalPages, totalCount, filters];
}

class TripDetailData extends Equatable {
  final Trip trip;
  final List<Delivery>? deliveries;
  final bool isInProgress;
  final bool isCompleted;

  const TripDetailData({
    required this.trip,
    this.deliveries,
    this.isInProgress = false,
    this.isCompleted = false,
  });

  factory TripDetailData.loaded(Trip trip, List<Delivery> deliveries) {
    return TripDetailData(trip: trip, deliveries: deliveries);
  }

  factory TripDetailData.inProgress(Trip trip, List<Delivery> deliveries) {
    return TripDetailData(
      trip: trip,
      deliveries: deliveries,
      isInProgress: true,
    );
  }

  factory TripDetailData.completed(Trip trip) {
    return TripDetailData(trip: trip, isCompleted: true);
  }

  @override
  List<Object?> get props => [trip, deliveries, isInProgress, isCompleted];
}

class TripFilters extends Equatable {
  final String? status;
  final String? date; // Changed from DateTime to String to match repository
  final String? passengerId;

  const TripFilters({
    this.status,
    this.date,
    this.passengerId,
  });

  @override
  List<Object?> get props => [status, date, passengerId];
}

/// Unified Trip Events
abstract class TripEvent {}

class TripListLoadRequested extends TripEvent {
  final TripListType type;
  final TripFilters? filters;
  final int? page;
  final int? perPage;

  TripListLoadRequested({
    this.type = TripListType.all,
    this.filters,
    this.page,
    this.perPage,
  });
}

class TripListLoadMoreRequested extends TripEvent {
  final TripFilters? filters;
  final int page;
  final int perPage;

  TripListLoadMoreRequested({
    this.filters,
    required this.page,
    required this.perPage,
  });
}

class TripDetailLoadRequested extends TripEvent {
  final String tripId;
  final bool quiet;

  TripDetailLoadRequested({required this.tripId, this.quiet = false});
}

class TripStartRequested extends TripEvent {
  final String tripId;

  TripStartRequested({required this.tripId});
}

class TripCompleteRequested extends TripEvent {
  final String tripId;

  TripCompleteRequested({required this.tripId});
}

class TripDriverLocationUpdated extends TripEvent {
  final double latitude;
  final double longitude;

  TripDriverLocationUpdated({
    required this.latitude,
    required this.longitude,
  });
}

class TripDeliveryStatusUpdated extends TripEvent {
  final String deliveryId;
  final String status;
  final DateTime timestamp;

  TripDeliveryStatusUpdated({
    required this.deliveryId,
    required this.status,
    required this.timestamp,
  });
}

class BulkDeliveryPickupRequested extends TripEvent {
  final List<String> deliveryIds;

  BulkDeliveryPickupRequested({required this.deliveryIds});
}

class BulkDeliveryDropoffRequested extends TripEvent {
  final List<String> deliveryIds;

  BulkDeliveryDropoffRequested({required this.deliveryIds});
}

class DeliveryPickupRequested extends TripEvent {
  final String deliveryId;

  DeliveryPickupRequested({required this.deliveryId});
}

class DeliveryDropoffRequested extends TripEvent {
  final String deliveryId;

  DeliveryDropoffRequested({required this.deliveryId});
}

enum TripListType {
  all,
  active,
  history,
  driverDashboard,
  guardian,
}

/// Unified Trip BLoC
class TripBloc extends BaseBloc<TripEvent, BlocState<dynamic>> {
  final TripRepository _tripRepository;

  TripBloc({required TripRepository tripRepository})
      : _tripRepository = tripRepository,
        super(const BlocState.initial()) {
    on<TripListLoadRequested>(_onTripListLoadRequested);
    on<TripListLoadMoreRequested>(_onTripListLoadMoreRequested);
    on<TripDetailLoadRequested>(_onTripDetailLoadRequested);
    on<TripStartRequested>(_onTripStartRequested);
    on<TripCompleteRequested>(_onTripCompleteRequested);
    on<TripDriverLocationUpdated>(_onTripDriverLocationUpdated);
    on<TripDeliveryStatusUpdated>(_onTripDeliveryStatusUpdated);
    on<BulkDeliveryPickupRequested>(_onBulkDeliveryPickupRequested);
    on<BulkDeliveryDropoffRequested>(_onBulkDeliveryDropoffRequested);
    on<DeliveryPickupRequested>(_onDeliveryPickupRequested);
    on<DeliveryDropoffRequested>(_onDeliveryDropoffRequested);
  }

  Future<void> _onTripListLoadRequested(
    TripListLoadRequested event,
    Emitter<BlocState<dynamic>> emit,
  ) async {
    await executeWithLoading<TripListData>(
      operation: () async {
        switch (event.type) {
          case TripListType.all:
            final trips = await _tripRepository.getTrips();
            return TripListData.withTrips(trips);
            
          case TripListType.active:
            final trips = await _tripRepository.getActiveTrips();
            return TripListData.withTrips(trips);
            
          case TripListType.driverDashboard:
            // Get both active trips (in_progress) and scheduled trips for driver dashboard
            final activeTrips = await _tripRepository.getTrips(status: ['in_progress', 'active']);
            final scheduledTrips = await _tripRepository.getTrips(status: 'scheduled');
            final allTrips = [...activeTrips, ...scheduledTrips];
            final driverStats = await _tripRepository.getDriverDashboardStats();
            return TripListData.withTrips(allTrips, driverStats: driverStats);
            
          case TripListType.guardian:
            final result = await _tripRepository.getGuardianTrips(
              status: event.filters?.status,
              date: event.filters?.date,
              passengerId: event.filters?.passengerId,
              page: event.page ?? 1,
              perPage: event.perPage ?? 20,
            );
            final trips = result['items'] as List<Trip>;
            final meta = result['meta'] as Map<String, dynamic>;
            return TripListData.withPagination(
              trips: trips,
              hasReachedMax: trips.length < (event.perPage ?? 20),
              currentPage: event.page ?? 1,
              totalPages: meta['last_page'] ?? 1,
              totalCount: meta['total'] ?? 0,
              filters: event.filters,
            );
            
          case TripListType.history:
            final result = await _tripRepository.getTripsPaginated(
              status: event.filters?.status, // Don't default to completed - load all trips when no filter
              date: event.filters?.date,
              page: event.page ?? 1,
              perPage: event.perPage ?? 20,
            );
            final trips = result['items'] as List<Trip>;
            final meta = result['meta'] as Map<String, dynamic>;
            return TripListData.withPagination(
              trips: trips,
              hasReachedMax: trips.length < (event.perPage ?? 20),
              currentPage: event.page ?? 1,
              totalPages: meta['last_page'] ?? 1,
              totalCount: meta['total'] ?? 0,
            );
        }
      },
      onSuccess: (data) {
        emit(BlocState.success(data));
      },
      onError: (error) {
        emit(BlocState.error(message: error.message));
      },
    );
  }

  Future<void> _onTripListLoadMoreRequested(
    TripListLoadMoreRequested event,
    Emitter<BlocState<dynamic>> emit,
  ) async {
    await executeWithLoading<TripListData>(
      operation: () async {
        final currentState = state;
        List<Trip> existingTrips = [];
        
        // Check if filters have changed, if so reset the list
        if (currentState.isSuccess && currentState.data != null) {
          final currentData = currentState.data as TripListData;
          final filtersChanged = !_filtersEqual(currentData.filters, event.filters);
          
          if (event.page == 1 || filtersChanged) {
            // Reset list for new search or changed filters
            existingTrips = [];
          } else {
            // Append to existing list for pagination
            existingTrips = currentData.trips;
          }
        }
        
        final result = await _tripRepository.getTripsPaginated(
          status: event.filters?.status,
          date: event.filters?.date,
          page: event.page,
          perPage: event.perPage,
        );
        final newTrips = result['items'] as List<Trip>;
        final meta = result['meta'] as Map<String, dynamic>;
        
        // Combine existing trips with new trips
        final allTrips = event.page == 1 ? newTrips : [...existingTrips, ...newTrips];
        
        return TripListData.withPagination(
          trips: allTrips,
          hasReachedMax: newTrips.length < event.perPage,
          currentPage: event.page,
          totalPages: meta['last_page'] ?? 1,
          totalCount: meta['total'] ?? 0,
          filters: event.filters,
        );
      },
      onSuccess: (data) {
        emit(BlocState.success(data));
      },
      onError: (error) {
        emit(BlocState.error(message: error.message));
      },
    );
  }
  
  bool _filtersEqual(TripFilters? filters1, TripFilters? filters2) {
    if (filters1 == null && filters2 == null) return true;
    if (filters1 == null || filters2 == null) return false;
    
    return filters1.status == filters2.status &&
           filters1.date == filters2.date &&
           filters1.passengerId == filters2.passengerId;
  }

  Future<void> _onTripDetailLoadRequested(
    TripDetailLoadRequested event,
    Emitter<BlocState<dynamic>> emit,
  ) async {
    final operation = () async {
      final trip = await _tripRepository.getTripById(event.tripId);
      final deliveries = await _tripRepository.getTripDeliveries(event.tripId);
      
      if (trip.isInProgress) {
        return TripDetailData.inProgress(trip, deliveries);
      } else if (trip.isCompleted) {
        return TripDetailData.completed(trip);
      } else {
        return TripDetailData.loaded(trip, deliveries);
      }
    };

    if (event.quiet) {
      await executeSilent<TripDetailData>(
        operation: operation,
        onSuccess: (data) => emit(BlocState.success(data)),
      );
    } else {
      await executeWithLoading<TripDetailData>(
        operation: operation,
        onSuccess: (data) => emit(BlocState.success(data)),
        onError: (error) => emit(BlocState.error(message: error.message)),
      );
    }
  }

  Future<void> _onTripStartRequested(
    TripStartRequested event,
    Emitter<BlocState<dynamic>> emit,
  ) async {
    await executeWithLoading<void>(
      operation: () async {
        await _tripRepository.startTrip(event.tripId);
        return;
      },
      onSuccess: (_) {
        // Reload trip details after starting
        add(TripDetailLoadRequested(tripId: event.tripId));
      },
      onError: (error) {
        emit(BlocState.error(message: error.message));
      },
    );
  }

  Future<void> _onTripDriverLocationUpdated(
    TripDriverLocationUpdated event,
    Emitter<BlocState<dynamic>> emit,
  ) async {
    // Update location without loading state
    try {
      // For now, just emit the current state unchanged
      // The location update would be handled by the repository service
      if (state.isSuccess && state.data != null) {
        emit(BlocState.success(state.data));
      }
    } catch (e) {
      emit(BlocState.error(message: 'Failed to update location: ${e.toString()}'));
    }
  }

  Future<void> _onTripDeliveryStatusUpdated(
    TripDeliveryStatusUpdated event,
    Emitter<BlocState<dynamic>> emit,
  ) async {
    // Update local state when an external event (like WebSocket) arrives
    if (state.data != null && state.data is TripDetailData) {
      final currentData = state.data as TripDetailData;
      final deliveries = List<Delivery>.from(currentData.deliveries ?? []);
      
      final index = deliveries.indexWhere((d) => d.id == event.deliveryId);
      if (index != -1) {
        final updatedDelivery = deliveries[index].copyWith(status: event.status);
        deliveries[index] = updatedDelivery;
        
        // Recalculate if all are completed
        final allCompleted = deliveries.every((d) => d.status == 'delivered' || d.status == 'completed' || d.status == 'no_show');
        
        final updatedData = TripDetailData(
          trip: currentData.trip,
          deliveries: deliveries,
          isInProgress: currentData.isInProgress && !allCompleted,
          isCompleted: currentData.isCompleted || allCompleted,
        );
        
        emit(BlocState.success(updatedData));
      }
    }
  }

  Future<void> _onTripCompleteRequested(
    TripCompleteRequested event,
    Emitter<BlocState<dynamic>> emit,
  ) async {
    await executeWithLoading<void>(
      operation: () async {
        await _tripRepository.completeTrip(event.tripId);
        return;
      },
      onSuccess: (_) {
        // Reload trip details after completing
        add(TripDetailLoadRequested(tripId: event.tripId));
      },
      onError: (error) {
        emit(BlocState.error(message: error.message));
      },
    );
  }

  Future<void> _onBulkDeliveryPickupRequested(
    BulkDeliveryPickupRequested event,
    Emitter<BlocState<dynamic>> emit,
  ) async {
    await executeWithLoading<void>(
      operation: () async {
        for (final deliveryId in event.deliveryIds) {
          await _tripRepository.markAsPickedUp(deliveryId);
        }
        return;
      },
      onSuccess: (_) {
        // Reload trip details to get updated delivery statuses
        if (state.data is TripDetailData) {
          add(TripDetailLoadRequested(
            tripId: (state.data as TripDetailData).trip.id,
            quiet: true,
          ));
        }
      },
      onError: (error) {
        emit(BlocState.error(message: error.message));
      },
    );
  }

  Future<void> _onBulkDeliveryDropoffRequested(
    BulkDeliveryDropoffRequested event,
    Emitter<BlocState<dynamic>> emit,
  ) async {
    await executeWithLoading<void>(
      operation: () async {
        for (final deliveryId in event.deliveryIds) {
          await _tripRepository.markAsDelivered(deliveryId);
        }
        return;
      },
      onSuccess: (_) {
        // Reload trip details to get updated delivery statuses
        if (state.data is TripDetailData) {
          add(TripDetailLoadRequested(
            tripId: (state.data as TripDetailData).trip.id,
            quiet: true,
          ));
        }
      },
      onError: (error) {
        emit(BlocState.error(message: error.message));
      },
    );
  }

  Future<void> _onDeliveryPickupRequested(
    DeliveryPickupRequested event,
    Emitter<BlocState<dynamic>> emit,
  ) async {
    await executeWithLoading<void>(
      operation: () async {
        await _tripRepository.markAsPickedUp(event.deliveryId);
        return;
      },
      onSuccess: (_) {
        // Reload trip details to get updated delivery status
        if (state.data is TripDetailData) {
          add(TripDetailLoadRequested(
            tripId: (state.data as TripDetailData).trip.id,
            quiet: true,
          ));
        }
      },
      onError: (error) {
        emit(BlocState.error(message: error.message));
      },
    );
  }

  Future<void> _onDeliveryDropoffRequested(
    DeliveryDropoffRequested event,
    Emitter<BlocState<dynamic>> emit,
  ) async {
    await executeWithLoading<void>(
      operation: () async {
        await _tripRepository.markAsDelivered(event.deliveryId);
        return;
      },
      onSuccess: (_) {
        // Reload trip details to get updated delivery status
        if (state.data is TripDetailData) {
          add(TripDetailLoadRequested(
            tripId: (state.data as TripDetailData).trip.id,
            quiet: true,
          ));
        }
      },
      onError: (error) {
        emit(BlocState.error(message: error.message));
      },
    );
  }
}
