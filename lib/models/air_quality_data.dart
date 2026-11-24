class AirQualityData {
  final int aqi;
  final String cityName;
  final String dominantPollutant;

  final double temperature;
  final int humidity;

  final double pm25;
  final double pm10;
  final double pressure;
  final double windSpeed;

  final DateTime? updatedAt;

  AirQualityData({
    required this.aqi,
    required this.cityName,
    required this.dominantPollutant,
    required this.temperature,
    required this.humidity,
    required this.pm25,
    required this.pm10,
    required this.pressure,
    required this.windSpeed,
    required this.updatedAt,
  });

  factory AirQualityData.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;

      if (value is num) {
        return value.toDouble();
      }

      if (value is String) {
        return double.tryParse(value) ?? 0.0;
      }

      return 0.0;
    }

    final aqiValue = json['aqi'];
    final aqi = aqiValue is num ? aqiValue.toInt() : 0;

    // City
    final cityData = json['city'];
    final cityName =
    cityData is Map
        ? cityData['name']?.toString() ?? 'Unknown'
        : 'Unknown';

    // Dominant pollutant
    final dominantPollutant =
        json['dominentpol']?.toString() ?? 'N/A';

    // Instant AQI values
    final iaqi = json['iaqi'] is Map
        ? json['iaqi'] as Map<String, dynamic>
        : <String, dynamic>{};

    final temperature = parseDouble(iaqi['t']?['v']);
    final humidity = parseDouble(iaqi['h']?['v']).toInt();

    final pm25 = parseDouble(iaqi['pm25']?['v']);
    final pm10 = parseDouble(iaqi['pm10']?['v']);

    final pressure = parseDouble(iaqi['p']?['v']);

    // WAQI uses `w` for wind speed
    final windSpeed = parseDouble(iaqi['w']?['v']);

    // Updated time
    DateTime? updatedAt;

    final time = json['time'];

    if (time is Map && time['iso'] != null) {
      updatedAt = DateTime.tryParse(time['iso'].toString());
    }

    return AirQualityData(
      aqi: aqi,
      cityName: cityName,
      dominantPollutant: dominantPollutant,
      temperature: temperature,
      humidity: humidity,
      pm25: pm25,
      pm10: pm10,
      pressure: pressure,
      windSpeed: windSpeed,
      updatedAt: updatedAt,
    );
  }
}