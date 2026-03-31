import 'package:flutter/material.dart';

import 'app.dart';
import 'data/datasources/weather_remote_datasource.dart';
import 'data/repositories/weather_repository_impl.dart';
import 'data/services/location_service.dart';
import 'domain/repositories/weather_repository.dart';

/// [repository] is optional so that integration tests can inject a FakeWeatherRepository
/// without needing real GPS or network access.
/// Without an argument, the full real implementation is built.
void main({WeatherRepository? repository}) {
  WidgetsFlutterBinding.ensureInitialized();

  final resolvedRepository = repository ??
      WeatherRepositoryImpl(
        datasource: WeatherRemoteDatasource(),
        locationService: LocationService(),
      );

  runApp(WeatherApp(repository: resolvedRepository));
}
