class WeatherData {
  final double temperature;
  final String condition;
  final int humidity;
  final double windSpeed;

  WeatherData({
    required this.temperature,
    required this.condition,
    required this.humidity,
    required this.windSpeed, required pressure, required temp,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
  final main = json['main'];
  if (main == null) {
    throw Exception("Missing 'main' field in API response");
  }

  return WeatherData(
    temperature: main['temp']?.toDouble() ?? 0.0,
    condition: json['weather'] != null && json['weather'].isNotEmpty ? json['weather'][0]['main'] ?? '' : '',
    humidity: main['humidity']?.toInt() ?? 0,
    windSpeed: json['wind'] != null ? (json['wind']['speed']?.toDouble() ?? 0.0) : 0.0, pressure: null, temp: null,
    // add other fields here safely
  );
}
}
