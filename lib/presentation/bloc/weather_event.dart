import 'package:equatable/equatable.dart';

// Sealed class so the Dart compiler enforces exhaustive matching in the BLoC.
// Adding a new subclass triggers a compiler warning on every switch
// that does not yet handle the new event — so we never forget a case.
sealed class WeatherEvent extends Equatable {
  const WeatherEvent();
}

class WeatherFetchRequested extends WeatherEvent {
  const WeatherFetchRequested();

  // props does not need to be overridden: the base class already has no props
  // and Equatable defaults to using runtimeType for comparison.
  @override
  List<Object> get props => [];
}
