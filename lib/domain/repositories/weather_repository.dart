import '../entities/weather.dart';

// This interface separates the domain layer from the infrastructure layer.
// The app only works with WeatherRepository, never directly with GPS or HTTP.
// This allows a FakeWeatherRepository to be injected in tests:
// no real location or network connection needed.
abstract class WeatherRepository {
  Future<Weather> fetchWeatherForCurrentLocation();
}
