import 'package:equatable/equatable.dart';

abstract class GuardianPassengerEvent extends Equatable {
  const GuardianPassengerEvent();

  @override
  List<Object?> get props => [];
}

class GuardianPassengerLoadRequested extends GuardianPassengerEvent {
  final bool forceRefresh;

  const GuardianPassengerLoadRequested({this.forceRefresh = false});

  @override
  List<Object?> get props => [forceRefresh];
}
