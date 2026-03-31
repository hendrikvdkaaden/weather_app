import 'package:equatable/equatable.dart';

import '../../domain/entities/weather.dart';

enum WeatherStatus {
  initial,
  loading,
  success,
  failure,
  permissionDenied,
}

// Sentinel values for copyWith so nullable fields can be explicitly reset to null.
// Without this pattern, copyWith(errorMessage: null) can never clear an existing value
// — null would be treated as "no update".
const _clearString = Object();
const _clearWeather = Object();
const _clearDateTime = Object();

class WeatherState extends Equatable {
  final WeatherStatus status;
  final Weather? weather;
  final String? errorMessage;
  final int apiCallCount;
  final DateTime? lastUpdated;

  const WeatherState({
    this.status = WeatherStatus.initial,
    this.weather,
    this.errorMessage,
    this.apiCallCount = 0,
    this.lastUpdated,
  });

  WeatherState copyWith({
    WeatherStatus? status,
    Weather? weather,
    Object? errorMessage = _clearString,
    int? apiCallCount,
    Object? lastUpdated = _clearDateTime,
  }) {
    return WeatherState(
      status: status ?? this.status,
      // Sentinel check: if the caller explicitly passes null, clear the value.
      weather: weather ?? this.weather,
      errorMessage: errorMessage == _clearString
          ? this.errorMessage
          : errorMessage as String?,
      apiCallCount: apiCallCount ?? this.apiCallCount,
      lastUpdated: lastUpdated == _clearDateTime
          ? this.lastUpdated
          : lastUpdated as DateTime?,
    );
  }

  @override
  List<Object?> get props => [
        status,
        weather,
        errorMessage,
        apiCallCount,
        lastUpdated,
      ];
}
