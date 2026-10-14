import 'dart:convert';

import 'package:http/http.dart' as http;

class WeatherService {
  Future<Map<String, dynamic>> getWeather({
    required double latitude,
    required double longitude,
  }) async {
    if (latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      throw ArgumentError('Invalid latitude or longitude.');
    }

    final uri = Uri.https(
      'api.open-meteo.com',
      '/v1/forecast',
      {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'current':
            'temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m',
        'daily':
            'weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,precipitation_sum',
        'timezone': 'auto',
        'forecast_days': '7',
        'temperature_unit': 'celsius',
        'wind_speed_unit': 'kmh',
        'precipitation_unit': 'mm',
      },
    );

    try {
      final response = await http
          .get(
            uri,
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        var message = 'HTTP ${response.statusCode}';

        try {
          final error = jsonDecode(response.body);

          if (error is Map && error['reason'] != null) {
            message = error['reason'].toString();
          }
        } catch (_) {
          // Keep the HTTP status when the response isn't JSON.
        }

        throw Exception('Weather request failed: $message');
      }

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw const FormatException(
          'Invalid weather response received.',
        );
      }

      if (decoded['current'] is! Map ||
          decoded['daily'] is! Map) {
        throw const FormatException(
          'Weather response is missing current or daily data.',
        );
      }

      return decoded;
    } on http.ClientException catch (e) {
      throw Exception(
        'Could not connect to the weather service: $e',
      );
    } on FormatException {
      rethrow;
    }
  }

  static String weatherDescription(int code) {
    if (code == 0) return 'Clear sky';
    if ([1, 2, 3].contains(code)) return 'Partly cloudy';
    if ([45, 48].contains(code)) return 'Foggy';
    if ([51, 53, 55, 56, 57].contains(code)) return 'Drizzle';
    if ([61, 63, 65, 66, 67].contains(code)) return 'Rain';
    if ([71, 73, 75, 77].contains(code)) return 'Snow';
    if ([80, 81, 82].contains(code)) return 'Rain showers';
    if ([85, 86].contains(code)) return 'Snow showers';
    if ([95, 96, 99].contains(code)) return 'Thunderstorm';

    return 'Unknown conditions';
  }

  static List<String> farmingRecommendations({
    required int weatherCode,
    required double temperature,
    required int humidity,
    required double rainfallMm,
    required int rainProbability,
  }) {
    final recommendations = <String>[];

    if (rainProbability >= 60 || rainfallMm >= 5) {
      recommendations.add(
        'Rain is possible. Check field drainage and postpone pesticide spraying if rain is expected.',
      );
    }

    if (temperature >= 35) {
      recommendations.add(
        'High temperature: check soil moisture and water crops during cooler hours when irrigation is needed.',
      );
    }

    if (humidity >= 80) {
      recommendations.add(
        'High humidity: inspect crops for fungal symptoms and ensure good airflow.',
      );
    }

    if ([95, 96, 99].contains(weatherCode)) {
      recommendations.add(
        'Thunderstorms are possible. Avoid field work during lightning and secure exposed equipment.',
      );
    }

    if (recommendations.isEmpty) {
      recommendations.add(
        'Conditions look relatively favourable. Check soil moisture and crop needs before watering.',
      );
    }

    return recommendations;
  }
}