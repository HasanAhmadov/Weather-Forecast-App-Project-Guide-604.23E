class WeatherData {
  final double temperature;
  final String condition;
  final int humidity;
  final double windSpeed;
  final double feelsLike;
  final String weatherIcon;
  final int? pressure; // Made optional with ?
  final double? tempMin; // Made optional with ?

  WeatherData({
    required this.temperature,
    required this.condition,
    required this.humidity,
    required this.windSpeed,
    required this.feelsLike,
    required this.weatherIcon,
    this.pressure,
    this.tempMin,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final main = json['main'];
    if (main == null) {
      throw Exception("Missing 'main' field in API response");
    }

    final weatherList = json['weather'] as List?;
    final weather = weatherList != null && weatherList.isNotEmpty ? weatherList[0] : null;

    return WeatherData(
      temperature: main['temp']?.toDouble() ?? 0.0,
      condition: weather?['main']?.toString() ?? '',
      humidity: main['humidity']?.toInt() ?? 0,
      windSpeed: (json['wind']?['speed'] ?? 0.0).toDouble(),
      feelsLike: main['feels_like']?.toDouble() ?? 0.0,
      weatherIcon: weather?['icon']?.toString() ?? '01d', // Default icon
      pressure: main['pressure']?.toInt(),
      tempMin: main['temp_min']?.toDouble(),
    );
  }
}