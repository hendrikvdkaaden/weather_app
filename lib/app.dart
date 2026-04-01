import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'domain/repositories/weather_repository.dart';
import 'presentation/bloc/weather_bloc.dart';
import 'presentation/bloc/weather_event.dart';
import 'presentation/pages/weather_page.dart';

class WeatherApp extends StatelessWidget {
  final WeatherRepository repository;

  /// If false: the initial fetch is NOT started automatically.
  /// Only for tests that want to observe the initial state —
  /// in production always true so the app starts loading immediately.
  final bool autoFetch;
  final Duration autoRefreshDuration;

  const WeatherApp({
    super.key,
    required this.repository,
    this.autoFetch = true,
    this.autoRefreshDuration = const Duration(minutes: 3),
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Dispatch WeatherFetchRequested on startup so the UI starts
      // loading as soon as the app launches.
      create: (_) {
        final bloc = WeatherBloc(
          repository: repository,
          autoRefreshDuration: autoRefreshDuration,
        );
        if (autoFetch) bloc.add(const WeatherFetchRequested());
        return bloc;
      },
      child: MaterialApp(
        title: 'Weather App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1565C0),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: const WeatherPage(),
      ),
    );
  }
}
