class WeatherApiException implements Exception {
  final String message;
  final int statusCode;

  const WeatherApiException({required this.message, required this.statusCode});

  @override
  String toString() => 'WeatherApiException($statusCode): $message';
}
