import '../../domain/entities/weather.dart';

class WeatherModel extends Weather {
  const WeatherModel({
    required super.cityName,
    required super.country,
    required super.temperature,
    required super.feelsLike,
    required super.humidity,
    required super.windSpeed,
    required super.condition,
    required super.conditionDescription,
    required super.fetchedAt,
  });

  factory WeatherModel.fromJson(
    Map<String, dynamic> json, {
    required String cityName,
    required String country,
  }) {
    final current = json['current'] as Map<String, dynamic>;
    final weatherCode = (current['weather_code'] as num?)?.toInt() ?? 0;

    return WeatherModel(
      cityName: cityName,
      country: country,
      temperature: (current['temperature_2m'] as num?)?.toDouble() ?? 0.0,
      feelsLike: (current['apparent_temperature'] as num?)?.toDouble() ?? 0.0,
      humidity: (current['relative_humidity_2m'] as num?)?.toInt() ?? 0,
      windSpeed: (current['wind_speed_10m'] as num?)?.toDouble() ?? 0.0,
      condition: _conditionFromCode(weatherCode),
      conditionDescription: _descriptionFromCode(weatherCode),
      fetchedAt: DateTime.now(),
    );
  }

  static String _conditionFromCode(int code) {
    if (code == 0) return 'Clear';
    if (code <= 3) return 'Clouds';
    if (code == 45 || code == 48) return 'Fog';
    if (code >= 51 && code <= 57) return 'Drizzle';
    if (code >= 61 && code <= 67) return 'Rain';
    if (code >= 71 && code <= 77) return 'Snow';
    if (code >= 80 && code <= 82) return 'Rain';
    if (code == 85 || code == 86) return 'Snow';
    if (code == 95 || code == 96 || code == 99) return 'Thunderstorm';
    return 'Unknown';
  }

  static String _descriptionFromCode(int code) {
    switch (code) {
      case 0:
        return 'Clear sky';
      case 1:
        return 'Mainly clear';
      case 2:
        return 'Partly cloudy';
      case 3:
        return 'Overcast';
      case 45:
        return 'Foggy';
      case 48:
        return 'Depositing rime fog';
      case 51:
        return 'Light drizzle';
      case 53:
        return 'Moderate drizzle';
      case 55:
        return 'Dense drizzle';
      case 56:
        return 'Light freezing drizzle';
      case 57:
        return 'Dense freezing drizzle';
      case 61:
        return 'Slight rain';
      case 63:
        return 'Moderate rain';
      case 65:
        return 'Heavy rain';
      case 66:
        return 'Light freezing rain';
      case 67:
        return 'Heavy freezing rain';
      case 71:
        return 'Slight snowfall';
      case 73:
        return 'Moderate snowfall';
      case 75:
        return 'Heavy snowfall';
      case 77:
        return 'Snow grains';
      case 80:
        return 'Slight rain showers';
      case 81:
        return 'Moderate rain showers';
      case 82:
        return 'Violent rain showers';
      case 85:
        return 'Slight snow showers';
      case 86:
        return 'Heavy snow showers';
      case 95:
        return 'Thunderstorm';
      case 96:
        return 'Thunderstorm with slight hail';
      case 99:
        return 'Thunderstorm with heavy hail';
      default:
        return 'Unknown weather conditions';
    }
  }
}
