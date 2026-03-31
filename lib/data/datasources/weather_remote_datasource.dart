import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/exceptions/weather_exceptions.dart';
import '../models/weather_model.dart';

abstract class IWeatherRemoteDatasource {
  Future<WeatherModel> getWeather({
    required double latitude,
    required double longitude,
  });
}

class WeatherRemoteDatasource implements IWeatherRemoteDatasource {
  final http.Client _client;

  WeatherRemoteDatasource({http.Client? client})
      : _client = client ?? http.Client();

  @override
  Future<WeatherModel> getWeather({
    required double latitude,
    required double longitude,
  }) async {
    // Both calls are independent — running them in parallel halves the load time.
    final results = await Future.wait([
      _fetchWeather(latitude, longitude),
      _fetchCityName(latitude, longitude),
    ]);

    final weatherData = results[0] as Map<String, dynamic>;
    final (cityName, country) = results[1] as (String, String);

    return WeatherModel.fromJson(
      weatherData,
      cityName: cityName,
      country: country,
    );
  }

  Future<Map<String, dynamic>> _fetchWeather(
    double latitude,
    double longitude,
  ) async {
    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': latitude.toString(),
      'longitude': longitude.toString(),
      'current':
          'temperature_2m,apparent_temperature,relative_humidity_2m,wind_speed_10m,weather_code',
      'wind_speed_unit': 'ms',
    });

    final response = await _client.get(uri);

    if (response.statusCode != 200) {
      throw WeatherApiException(
        message: 'Failed to fetch weather data.',
        statusCode: response.statusCode,
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Unexpected weather response format.');
    }
    if (decoded['current'] is! Map<String, dynamic>) {
      throw const FormatException('Missing "current" field in weather response.');
    }
    return decoded;
  }

  Future<(String cityName, String country)> _fetchCityName(
    double latitude,
    double longitude,
  ) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/reverse', {
      'lat': latitude.toString(),
      'lon': longitude.toString(),
      'format': 'json',
    });

    final response = await _client.get(
      uri,
      headers: {'User-Agent': 'WeatherApp/1.0'},
    );

    if (response.statusCode != 200) {
      throw WeatherApiException(
        message: 'Failed to fetch city name.',
        statusCode: response.statusCode,
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final address = json['address'] as Map<String, dynamic>? ?? {};

    final cityName = (address['city'] as String?) ??
        (address['town'] as String?) ??
        (address['village'] as String?) ??
        'Unknown';

    final country =
        (address['country_code'] as String?)?.toUpperCase() ?? '';

    return (cityName, country);
  }
}
