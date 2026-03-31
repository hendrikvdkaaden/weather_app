import 'package:equatable/equatable.dart';

class Weather extends Equatable {
  final String cityName;
  final String country;
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final String condition;
  final String conditionDescription;
  final DateTime fetchedAt;

  const Weather({
    required this.cityName,
    required this.country,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.condition,
    required this.conditionDescription,
    required this.fetchedAt,
  });

  @override
  List<Object> get props => [
        cityName,
        country,
        temperature,
        feelsLike,
        humidity,
        windSpeed,
        condition,
        conditionDescription,
        fetchedAt,
      ];
}
