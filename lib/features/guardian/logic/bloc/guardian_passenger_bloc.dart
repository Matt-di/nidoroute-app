import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/bloc/base_state.dart';
import '../../../../core/models/passenger.dart';
import '../../../../core/services/guardian_service.dart';
import 'guardian_passenger_event.dart';

class GuardianPassengerBloc extends Bloc<GuardianPassengerEvent, BlocState<List<Passenger>>> {
  final GuardianService _guardianService;

  GuardianPassengerBloc({required GuardianService guardianService})
      : _guardianService = guardianService,
        super(const BlocState.initial()) {
    on<GuardianPassengerLoadRequested>(_onLoadRequested);
  }

  Future<void> _onLoadRequested(
    GuardianPassengerLoadRequested event,
    Emitter<BlocState<List<Passenger>>> emit,
  ) async {
    if (!event.forceRefresh && state.hasData && !state.isError) {
      return;
    }

    emit(state.status == BlocStatus.initial 
        ? const BlocState.loading() 
        : state.copyWith(status: BlocStatus.loading));
        
    try {
      // Add timeout to prevent infinite loading
      final passengers = await _guardianService.getMyPassengers().timeout(
        const Duration(seconds: 15),
      );
      emit(BlocState.success(passengers));
    } catch (e) {
      emit(BlocState.error(message: e.toString()));
    }
  }
}
