import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:weather_app_tap/app.dart';
import 'package:weather_app_tap/core/exceptions/location_exceptions.dart';
import 'package:weather_app_tap/core/exceptions/weather_exceptions.dart';
import 'package:weather_app_tap/domain/entities/weather.dart';
import 'package:weather_app_tap/domain/repositories/weather_repository.dart';

// ---------------------------------------------------------------------------
// FakeWeatherRepository
// ---------------------------------------------------------------------------

class FakeWeatherRepository implements WeatherRepository {
  final Duration delay;
  final Exception? errorToThrow;

  const FakeWeatherRepository({
    this.delay = const Duration(milliseconds: 150),
    this.errorToThrow,
  });

  static final amsterdamWeather = Weather(
    cityName: 'Amsterdam',
    country: 'NL',
    temperature: 14.2,
    feelsLike: 12.8,
    humidity: 72,
    windSpeed: 5.3,
    condition: 'Clouds',
    conditionDescription: 'Partly cloudy',
    fetchedAt: DateTime(2024, 3, 29, 12, 0),
  );

  @override
  Future<Weather> fetchWeatherForCurrentLocation() async {
    await Future<void>.delayed(delay);

    if (errorToThrow != null) throw errorToThrow!;

    return amsterdamWeather;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Builds the full [WeatherApp] with a [FakeWeatherRepository] and waits
/// until all animations and async work have completed.
///
/// [autoFetch] determines whether the BLoC starts a fetch immediately on startup.
/// Set to false to observe the initial state before the first fetch.
///
/// ```dart
/// // Success flow:
/// await pumpApp(tester);
///
/// // Initial state without fetch:
/// await pumpApp(tester, autoFetch: false);
///
/// // Error scenario:
/// await pumpApp(tester, repository: FakeWeatherRepository(
///   errorToThrow: const LocationPermissionDeniedException(),
/// ));
/// ```
// Short duration used in all tests so timer-based tests complete instantly
// via tester.pump() without waiting for real wall-clock time.
const _testAutoRefreshDuration = Duration(minutes: 3);

Future<void> pumpApp(
  WidgetTester tester, {
  FakeWeatherRepository? repository,
  bool autoFetch = true,
}) async {
  await tester.pumpWidget(
    WeatherApp(
      repository: repository ?? const FakeWeatherRepository(),
      autoFetch: autoFetch,
      autoRefreshDuration: _testAutoRefreshDuration,
    ),
  );

  // pumpAndSettle waits for all frames, animations and async microtasks.
  // This ensures the UI is in a stable final state when the first
  // assertion in the test is executed.
  await tester.pumpAndSettle();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // Initializes the integration_test binding that manages communication with
  // the device/emulator.
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('WeatherApp — initial state', () {
    testWidgets(
      'shows fetch button and zero API calls before first fetch',
      (tester) async {
        // autoFetch: false so the BLoC stays in WeatherStatus.initial —
        // otherwise pumpAndSettle would complete the fetch and we would
        // never see the initial state.
        await pumpApp(tester, autoFetch: false);

        // Fetch button is visible in the initial view.
        expect(find.byKey(const Key('fetch_weather_button')), findsOneWidget);

        // Counter is zero: no attempt has been made yet.
        expect(find.byKey(const Key('api_call_count_text')), findsOneWidget);
        expect(find.text('API Calls: 0'), findsOneWidget);

        // Weather data is not yet visible: success view has not been shown.
        expect(find.byKey(const Key('temperature_text')), findsNothing);
      },
    );
  });

  group('WeatherApp — loading', () {
    testWidgets(
      'shows loading indicator while fetching weather data',
      (tester) async {
        final repo = const FakeWeatherRepository(
          delay: Duration(seconds: 2),
        );

        await tester.pumpWidget(WeatherApp(repository: repo));

        // One pump: the first frame after pumpWidget — BLoC has emitted the
        // loading state but the Future is not yet complete.
        await tester.pump();

        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Wait exactly as long as the delay plus a small margin —
        // no arbitrary magic duration that breaks if the delay changes.
        await tester.pumpAndSettle(repo.delay + const Duration(milliseconds: 100));
      },
    );
  });

  group('WeatherApp — successful load', () {
    testWidgets(
      'shows temperature and city name after successful fetch',
      (tester) async {
        await pumpApp(tester);

        expect(find.byKey(const Key('temperature_text')), findsOneWidget);
        expect(find.byKey(const Key('city_name_text')), findsOneWidget);
        expect(
          find.text(
            '${FakeWeatherRepository.amsterdamWeather.cityName}, '
            '${FakeWeatherRepository.amsterdamWeather.country}',
          ),
          findsOneWidget,
        );
        expect(
          find.text(
            '${FakeWeatherRepository.amsterdamWeather.temperature.toStringAsFixed(1)}°C',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'shows "Refresh" as button text after successful fetch',
      (tester) async {
        await pumpApp(tester);

        expect(find.text('Refresh'), findsOneWidget);
      },
    );

    testWidgets(
      'API call counter increments on each fetch',
      (tester) async {
        await pumpApp(tester);

        // After the first automatic fetch the counter is 1.
        expect(find.text('API Calls: 1'), findsOneWidget);

        // Tap Refresh and wait for the second fetch.
        await tester.tap(find.byKey(const Key('fetch_weather_button')));
        await tester.pumpAndSettle();

        expect(find.text('API Calls: 2'), findsOneWidget);
      },
    );
  });

  group('WeatherApp — auto-refresh', () {
    testWidgets(
      'shows "Updated just now" label immediately after successful fetch',
      (tester) async {
        await pumpApp(tester);

        expect(find.byKey(const Key('last_updated_text')), findsOneWidget);
        expect(find.text('Updated just now'), findsOneWidget);
      },
    );

    testWidgets(
      'shows auto-refresh countdown label after successful fetch',
      (tester) async {
        await pumpApp(tester);

        expect(
          find.byKey(const Key('auto_refresh_countdown_text')),
          findsOneWidget,
        );
        expect(find.text('Auto-refresh in 3 min'), findsOneWidget);
      },
    );

    testWidgets(
      '"Updated X minutes ago" updates after one minute passes',
      (tester) async {
        await pumpApp(tester);

        expect(find.text('Updated just now'), findsOneWidget);

        await tester.pump(const Duration(minutes: 1));

        expect(find.text('Updated 1 minute ago'), findsOneWidget);
        expect(find.text('Auto-refresh in 2 min'), findsOneWidget);
      },
    );

    testWidgets(
      'auto-refresh countdown resets to 3 min after manual refresh',
      (tester) async {
        await pumpApp(tester);

        await tester.pump(const Duration(minutes: 1));
        expect(find.text('Auto-refresh in 2 min'), findsOneWidget);

        await tester.tap(find.byKey(const Key('fetch_weather_button')));
        await tester.pumpAndSettle();

        expect(find.text('Auto-refresh in 3 min'), findsOneWidget);
        expect(find.text('Updated just now'), findsOneWidget);
      },
    );

    testWidgets(
      'auto-refresh triggers a new fetch after 3 minutes',
      (tester) async {
        await pumpApp(tester);

        expect(find.text('API Calls: 1'), findsOneWidget);

        await tester.pump(const Duration(minutes: 3));
        await tester.pumpAndSettle();

        expect(find.text('API Calls: 2'), findsOneWidget);
        expect(find.text('Updated just now'), findsOneWidget);
      },
    );
  });

  group('WeatherApp — error paths', () {
    testWidgets(
      'shows no internet error message when NoInternetException is thrown',
      (tester) async {
        await pumpApp(
          tester,
          repository: const FakeWeatherRepository(
            errorToThrow: NoInternetException(),
          ),
        );

        expect(find.text('⚠️'), findsOneWidget);
        expect(
          find.textContaining('No internet connection'),
          findsOneWidget,
        );
        expect(find.byKey(const Key('fetch_weather_button')), findsOneWidget);
      },
    );

    testWidgets(
      'shows timeout error message when RequestTimeoutException is thrown',
      (tester) async {
        await pumpApp(
          tester,
          repository: const FakeWeatherRepository(
            errorToThrow: RequestTimeoutException(),
          ),
        );

        expect(find.text('⚠️'), findsOneWidget);
        expect(
          find.textContaining('took too long'),
          findsOneWidget,
        );
        expect(find.byKey(const Key('fetch_weather_button')), findsOneWidget);
      },
    );

    testWidgets(
      'shows no internet error then recovers after retry succeeds',
      (tester) async {
        var hasInternet = false;
        final repo = _TogglableRepository(
          shouldFail: () => hasInternet ? null : const NoInternetException(),
        );

        await tester.pumpWidget(WeatherApp(repository: repo));
        await tester.pumpAndSettle();

        expect(find.textContaining('No internet connection'), findsOneWidget);

        // Simulate internet becoming available and retry.
        hasInternet = true;
        await tester.tap(find.byKey(const Key('fetch_weather_button')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('temperature_text')), findsOneWidget);
        expect(find.text('⚠️'), findsNothing);
      },
    );

    testWidgets(
      'shows error message on WeatherApiException',
      (tester) async {
        await pumpApp(
          tester,
          repository: FakeWeatherRepository(
            errorToThrow: const WeatherApiException(
              message: 'Failed to fetch weather data.',
              statusCode: 500,
            ),
          ),
        );

        // Failure view shows warning icon and retry button.
        expect(find.text('⚠️'), findsOneWidget);
        expect(find.byKey(const Key('fetch_weather_button')), findsOneWidget);
      },
    );

    testWidgets(
      'shows error message when location service is disabled',
      (tester) async {
        await pumpApp(
          tester,
          repository: const FakeWeatherRepository(
            errorToThrow: LocationServiceDisabledException(),
          ),
        );

        // LocationServiceDisabledException → failure view (not permission denied).
        expect(find.text('⚠️'), findsOneWidget);
        expect(find.text('🔒'), findsNothing);
      },
    );

    testWidgets(
      'shows permission denied view when location access is denied',
      (tester) async {
        await pumpApp(
          tester,
          repository: const FakeWeatherRepository(
            errorToThrow: LocationPermissionDeniedException(),
          ),
        );

        // Permission denied view shows lock icon and error message from the BLoC.
        expect(find.text('🔒'), findsOneWidget);
        expect(
          find.textContaining('Location access denied'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'shows permission denied view when location access is permanently denied',
      (tester) async {
        await pumpApp(
          tester,
          repository: const FakeWeatherRepository(
            errorToThrow: LocationPermissionPermanentlyDeniedException(),
          ),
        );

        // Permanently denied → same permission view but different message.
        expect(find.text('🔒'), findsOneWidget);
        expect(
          find.textContaining('permanently denied'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'API call counter also counts failed attempts',
      (tester) async {
        await pumpApp(
          tester,
          repository: FakeWeatherRepository(
            errorToThrow: const WeatherApiException(
              message: 'Error',
              statusCode: 503,
            ),
          ),
        );

        // Failed call counts as an attempt — we count attempts, not successes.
        expect(find.text('API Calls: 1'), findsOneWidget);
      },
    );

    testWidgets(
      'recovery after error — weather data visible after successful retry',
      (tester) async {
        // Start with a failing repository.
        Exception? errorToThrow = const WeatherApiException(
          message: 'Temporary error',
          statusCode: 503,
        );
        final repo = _TogglableRepository(shouldFail: () => errorToThrow);

        await tester.pumpWidget(WeatherApp(repository: repo));
        await tester.pumpAndSettle();

        // First fetch fails — error screen visible.
        expect(find.text('⚠️'), findsOneWidget);
        expect(find.byKey(const Key('temperature_text')), findsNothing);

        // Switch repository to success and tap retry.
        errorToThrow = null;
        await tester.tap(find.byKey(const Key('fetch_weather_button')));
        await tester.pumpAndSettle();

        // After successful retry, weather data is visible.
        expect(find.byKey(const Key('temperature_text')), findsOneWidget);
        expect(find.text('⚠️'), findsNothing);
      },
    );
  });
}

// ---------------------------------------------------------------------------
// Helper classes
// ---------------------------------------------------------------------------

/// Repository whose failure behaviour can be toggled per call via a callback.
/// [shouldFail] returns the exception to throw, or null for a successful fetch.
/// Used in recovery tests to change behaviour without rebuilding the widget tree.
class _TogglableRepository implements WeatherRepository {
  final Exception? Function() shouldFail;

  const _TogglableRepository({required this.shouldFail});

  @override
  Future<Weather> fetchWeatherForCurrentLocation() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final error = shouldFail();
    if (error != null) throw error;

    return FakeWeatherRepository.amsterdamWeather;
  }
}
