import 'package:flutter/material.dart';

import '../services/weather_service.dart';

class WeatherScreen extends StatefulWidget {
  const WeatherScreen({super.key});

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  final WeatherService _weatherService = WeatherService();

  // Default coordinates: Coimbatore, Tamil Nadu.
  static const double _latitude = 11.0168;
  static const double _longitude = 76.9558;

  Map<String, dynamic>? _weather;
  bool _isLoading = true;
  String? _error;

  static const Color _green = Color(0xFF176B45);
  static const Color _background = Color(0xFFF5F8F4);

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _weatherService.getWeather(
        latitude: _latitude,
        longitude: _longitude,
      );

      if (!mounted) return;

      setState(() {
        _weather = result;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  double _number(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  int _integer(dynamic value) => _number(value).round();

  String _temperature(dynamic value) =>
      '${_number(value).round()}°C';

  IconData _weatherIcon(int code) {
    if (code == 0) return Icons.wb_sunny_rounded;
    if ([1, 2, 3].contains(code)) return Icons.cloud_rounded;
    if ([45, 48].contains(code)) return Icons.foggy;
    if ([51, 53, 55, 56, 57, 61, 63, 65, 66, 67, 80, 81, 82]
        .contains(code)) {
      return Icons.water_drop_rounded;
    }
    if ([95, 96, 99].contains(code)) {
      return Icons.thunderstorm_rounded;
    }
    if ([71, 73, 75, 77, 85, 86].contains(code)) {
      return Icons.ac_unit_rounded;
    }
    return Icons.cloud_outlined;
  }

  String _weekday(String date) {
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return date;

    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return days[parsed.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        title: const Text(
          'Weather & Forecast',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _background,
        foregroundColor: _green,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadWeather,
            tooltip: 'Refresh weather',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: _green),
                  SizedBox(height: 16),
                  Text('Loading weather information...'),
                ],
              ),
            )
          : _error != null
              ? _buildError()
              : _weather == null
                  ? _buildError()
                  : _buildWeather(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 64,
              color: _green,
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load weather',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Please try again.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _loadWeather,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: FilledButton.styleFrom(
                backgroundColor: _green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeather() {
    final current =
        Map<String, dynamic>.from(_weather!['current'] as Map);
    final daily =
        Map<String, dynamic>.from(_weather!['daily'] as Map);

    final temperature = _number(current['temperature_2m']);
    final humidity = _integer(current['relative_humidity_2m']);
    final feelsLike = _number(current['apparent_temperature']);
    final windSpeed = _number(current['wind_speed_10m']);
    final code = _integer(current['weather_code']);

    final dates = List<String>.from(daily['time'] as List);
    final maxTemps = List<dynamic>.from(
      daily['temperature_2m_max'] as List,
    );
    final minTemps = List<dynamic>.from(
      daily['temperature_2m_min'] as List,
    );
    final codes = List<dynamic>.from(
      daily['weather_code'] as List,
    );
    final rainProbabilities = List<dynamic>.from(
      daily['precipitation_probability_max'] as List,
    );
    final rainfall = List<dynamic>.from(
      daily['precipitation_sum'] as List,
    );

    final todayRainProbability = rainProbabilities.isNotEmpty
        ? _integer(rainProbabilities.first)
        : 0;
    final todayRainfall =
        rainfall.isNotEmpty ? _number(rainfall.first) : 0.0;

    final recommendations = WeatherService.farmingRecommendations(
      weatherCode: code,
      temperature: temperature,
      humidity: humidity,
      rainfallMm: todayRainfall,
      rainProbability: todayRainProbability,
    );

    return RefreshIndicator(
      onRefresh: _loadWeather,
      color: _green,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Farm weather overview',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF183D2B),
            ),
          ),
          const SizedBox(height: 4),
          const Row(
            children: [
              Icon(Icons.location_on_outlined, size: 17, color: _green),
              SizedBox(width: 4),
              Text(
                'Coimbatore, Tamil Nadu',
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Current weather card.
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF176B45), Color(0xFF104B32)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CURRENT WEATHER',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Icon(
                      _weatherIcon(code),
                      color: Colors.white,
                      size: 62,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _temperature(temperature),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 44,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            WeatherService.weatherDescription(code),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  'Feels like ${_temperature(feelsLike)}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Text(
            'Weather details',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.65,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _detailCard(
                icon: Icons.water_drop_outlined,
                title: 'Humidity',
                value: '$humidity%',
              ),
              _detailCard(
                icon: Icons.air_rounded,
                title: 'Wind speed',
                value: '${windSpeed.toStringAsFixed(1)} km/h',
              ),
              _detailCard(
                icon: Icons.umbrella_outlined,
                title: 'Rain probability',
                value: '$todayRainProbability%',
              ),
              _detailCard(
                icon: Icons.grain_rounded,
                title: 'Rainfall today',
                value: '${todayRainfall.toStringAsFixed(1)} mm',
              ),
            ],
          ),

          const SizedBox(height: 26),
          const Text(
            '7-day forecast',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          ...List.generate(dates.length, (index) {
            final dayCode = _integer(codes[index]);
            final rainChance = _integer(rainProbabilities[index]);
            final rainAmount = _number(rainfall[index]);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5ECE5)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      index == 0 ? 'Today' : _weekday(dates[index]),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    _weatherIcon(dayCode),
                    color: _green,
                    size: 25,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: Text(
                      '${_temperature(maxTemps[index])} / '
                      '${_temperature(minTemps[index])}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$rainChance%',
                          style: const TextStyle(
                            color: _green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${rainAmount.toStringAsFixed(1)} mm',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 18),
          const Text(
            'Farming recommendations',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          ...recommendations.map(
            (recommendation) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F4E9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.eco_outlined,
                    color: _green,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      recommendation,
                      style: const TextStyle(height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
          const Text(
            'Forecasts are estimates. Check local field conditions before making irrigation or crop-protection decisions.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _detailCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5ECE5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: _green, size: 27),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 5),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF183D2B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}