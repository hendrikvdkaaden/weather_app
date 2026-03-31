import '../../domain/entities/weather.dart';
import '../../domain/repositories/weather_repository.dart';
import '../datasources/weather_remote_datasource.dart';
import '../services/location_service.dart';

class WeatherRepositoryImpl implements WeatherRepository {
  final IWeatherRemoteDatasource datasource;
  final ILocationService locationService;

  const WeatherRepositoryImpl({
    required this.datasource,
    required this.locationService,
  });

  @override
  Future<Weather> fetchWeatherForCurrentLocation() async {
    final position = await locationService.getCurrentPosition();
    return datasource.getWeather(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }
}
