import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/weather.dart';
import '../bloc/weather_bloc.dart';
import '../bloc/weather_event.dart';
import '../bloc/weather_state.dart';

class WeatherPage extends StatelessWidget {
  const WeatherPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            // buildWhen limits rebuilds to only when apiCallCount changes —
            // the rest of the AppBar does not need to rebuild on status changes.
            child: BlocBuilder<WeatherBloc, WeatherState>(
              buildWhen: (prev, curr) => prev.apiCallCount != curr.apiCallCount,
              builder: (context, state) =>
                  _ApiCallBadge(count: state.apiCallCount),
            ),
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: SizedBox.expand(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1565C0), // dark blue
                Color(0xFF0D1B2A), // near black
              ],
            ),
          ),
          child: SafeArea(
            child: BlocBuilder<WeatherBloc, WeatherState>(
              builder: (context, state) {
                return switch (state.status) {
                  WeatherStatus.initial => const _InitialView(),
                  WeatherStatus.loading => const _LoadingView(),
                  WeatherStatus.success => _SuccessView(
                      weather: state.weather!,
                      lastUpdated: state.lastUpdated,
                      autoRefreshDuration:
                          context.read<WeatherBloc>().autoRefreshDuration,
                    ),
                  WeatherStatus.failure => _ErrorView(message: state.errorMessage),
                  WeatherStatus.permissionDenied =>
                    _PermissionDeniedView(message: state.errorMessage),
                };
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// API Call Badge
// ---------------------------------------------------------------------------

class _ApiCallBadge extends StatelessWidget {
  final int count;

  const _ApiCallBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('api_call_badge'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        'API Calls: $count',
        key: const Key('api_call_count_text'),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Initial
// ---------------------------------------------------------------------------

class _InitialView extends StatelessWidget {
  const _InitialView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌍', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              'Tap the button to fetch the weather for your current location.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 32),
            const _FetchButton(isSuccess: false),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading
// ---------------------------------------------------------------------------

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: Colors.white),
    );
  }
}

// ---------------------------------------------------------------------------
// Success
// ---------------------------------------------------------------------------

class _SuccessView extends StatefulWidget {
  final Weather weather;
  final DateTime? lastUpdated;
  final Duration autoRefreshDuration;

  const _SuccessView({
    required this.weather,
    required this.lastUpdated,
    required this.autoRefreshDuration,
  });

  @override
  State<_SuccessView> createState() => _SuccessViewState();
}

class _SuccessViewState extends State<_SuccessView> {
  Timer? _minuteTimer;

  @override
  void initState() {
    super.initState();
    // Rebuild every minute so the "updated X minutes ago" text stays current.
    _minuteTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _minuteTimer?.cancel();
    super.dispose();
  }

  String get _minutesAgoText {
    final updated = widget.lastUpdated;
    if (updated == null) return '';
    final minutes = DateTime.now().difference(updated).inMinutes;
    if (minutes < 1) return 'Updated just now';
    return 'Updated $minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
  }

  String get _autoRefreshCountdownText {
    final updated = widget.lastUpdated;
    if (updated == null) return '';
    final elapsed = DateTime.now().difference(updated).inMinutes;
    final remaining = widget.autoRefreshDuration.inMinutes - elapsed;
    if (remaining <= 0) return 'Refreshing…';
    return 'Auto-refresh in $remaining ${remaining == 1 ? 'min' : 'min'}';
  }

  String _emojiForCondition(String condition) {
    return switch (condition.toLowerCase()) {
      'clear'        => '☀️',
      'clouds'       => '☁️',
      'rain'         => '🌧️',
      'drizzle'      => '🌦️',
      'snow'         => '❄️',
      'fog'          => '🌫️',
      'thunderstorm' => '⛈️',
      _              => '🌡️',
    };
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          Text(
            _emojiForCondition(widget.weather.condition),
            style: const TextStyle(fontSize: 80),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.weather.temperature.toStringAsFixed(1)}°C',
            key: const Key('temperature_text'),
            style: textTheme.displayLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.weather.conditionDescription,
            style: textTheme.titleMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          Text(
            '${widget.weather.cityName}, ${widget.weather.country}',
            key: const Key('city_name_text'),
            style: textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            _minutesAgoText,
            key: const Key('last_updated_text'),
            style: textTheme.bodySmall?.copyWith(color: Colors.white54),
          ),
          const SizedBox(height: 2),
          Text(
            _autoRefreshCountdownText,
            key: const Key('auto_refresh_countdown_text'),
            style: textTheme.bodySmall?.copyWith(color: Colors.white38),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatTile(
                icon: '🌡️',
                label: 'Feels like',
                value: '${widget.weather.feelsLike.toStringAsFixed(1)}°C',
              ),
              _StatTile(
                icon: '💧',
                label: 'Humidity',
                value: '${widget.weather.humidity}%',
              ),
              _StatTile(
                icon: '💨',
                label: 'Wind',
                value: '${widget.weather.windSpeed.toStringAsFixed(1)} m/s',
              ),
            ],
          ),
          const SizedBox(height: 40),
          const _FetchButton(isSuccess: true),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String icon;
  final String label;
  final String value;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Failure
// ---------------------------------------------------------------------------

class _ErrorView extends StatelessWidget {
  final String? message;

  const _ErrorView({this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              message ?? 'An unexpected error occurred.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 32),
            const _FetchButton(isSuccess: false),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Permission Denied
// ---------------------------------------------------------------------------

class _PermissionDeniedView extends StatelessWidget {
  final String? message;

  const _PermissionDeniedView({this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🔒', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              message ??
                  'Location access denied. Grant permission in settings to fetch the weather.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 32),
            const _FetchButton(isSuccess: false),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared fetch button
// ---------------------------------------------------------------------------

class _FetchButton extends StatelessWidget {
  final bool isSuccess;

  const _FetchButton({required this.isSuccess});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      key: const Key('fetch_weather_button'),
      onPressed: () =>
          context.read<WeatherBloc>().add(const WeatherFetchRequested()),
      icon: const Icon(Icons.my_location),
      label: Text(isSuccess ? 'Refresh' : 'Get Weather'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
