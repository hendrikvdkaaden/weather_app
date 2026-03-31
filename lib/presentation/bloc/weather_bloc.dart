import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/exceptions/location_exceptions.dart';
import '../../core/exceptions/weather_exceptions.dart';
import '../../domain/repositories/weather_repository.dart';
import 'weather_event.dart';
import 'weather_state.dart';

class WeatherBloc extends Bloc<WeatherEvent, WeatherState> {
  final WeatherRepository _repository;

  WeatherBloc({required WeatherRepository repository})
      : _repository = repository,
        super(const WeatherState()) {
    on<WeatherFetchRequested>(_onWeatherFetchRequested);
  }

  Future<void> _onWeatherFetchRequested(
    WeatherFetchRequested event,
    Emitter<WeatherState> emit,
  ) async {
    // (1) Emit loading — count the attempt immediately, even if the call fails later.
    emit(state.copyWith(
      status: WeatherStatus.loading,
      apiCallCount: state.apiCallCount + 1,
    ));

    try {
      // (2) Fetch weather data via the repository.
      final weather = await _repository.fetchWeatherForCurrentLocation();

      // (3) Success — store data and timestamp.
      emit(state.copyWith(
        status: WeatherStatus.success,
        weather: weather,
        lastUpdated: DateTime.now(),
        errorMessage: null,
      ));
    } on LocationPermissionDeniedException {
      emit(state.copyWith(
        status: WeatherStatus.permissionDenied,
        errorMessage:
            'Location access denied. Please grant permission to fetch the weather.',
      ));
    } on LocationPermissionPermanentlyDeniedException {
      emit(state.copyWith(
        status: WeatherStatus.permissionDenied,
        errorMessage:
            'Location access permanently denied. Open app settings to grant access.',
      ));
    } on LocationServiceDisabledException {
      emit(state.copyWith(
        status: WeatherStatus.failure,
        errorMessage:
            'GPS is disabled. Enable location services to fetch the weather.',
      ));
    } on WeatherApiException {
      emit(state.copyWith(
        status: WeatherStatus.failure,
        errorMessage: 'Could not fetch weather data. Please try again.',
      ));
    } on Exception catch (e, stackTrace) {
      assert(() {
        // ignore: avoid_print
        print('[WeatherBloc] Unexpected error: $e\n$stackTrace');
        return true;
      }());
      emit(state.copyWith(
        status: WeatherStatus.failure,
        errorMessage: 'An unexpected error occurred. Please try again.',
      ));
    }
  }
}
