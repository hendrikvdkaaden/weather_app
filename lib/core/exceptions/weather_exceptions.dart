class WeatherApiException implements Exception {
  final String message;
  final int statusCode;

  const WeatherApiException({required this.message, required this.statusCode});

  @override
  String toString() => 'WeatherApiException($statusCode): $message';
}

class NoInternetException implements Exception {
  const NoInternetException();
}

class RequestTimeoutException implements Exception {
  const RequestTimeoutException();
}
