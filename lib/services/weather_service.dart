// ignore_for_file: avoid_print, non_constant_identifier_names, deprecated_member_use

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';
import 'package:geolocator/geolocator.dart';

class WeatherService extends ChangeNotifier {
  WeatherData? weatherData;
  bool isLoading = false;
  String? errorMessage;
  String? cityName;
  List<Map<String, dynamic>> hourlyForecast = [];
  List<Map<String, dynamic>> dailyForecast = [];

  final String _geoCodingBaseUrl = 'http://api.openweathermap.org/geo/1.0/direct';
  final String _5dayForecast = 'https://api.openweathermap.org/data/2.5/forecast';
  final String _currentWeather = 'https://api.openweathermap.org/data/2.5/weather';
  final String _weatherIcons = 'http://openweathermap.org/img/wn/';

  Future<void> fetchWeatherByLocation(double lat, double lon) async {
    final apiKey = dotenv.env['OPENWEATHERMAP_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      errorMessage = 'API key is missing.';
      notifyListeners();
      return;
    }

    final url = '$_currentWeather?lat=$lat&lon=$lon&units=metric&appid=$apiKey';
    final forecastUrl = '$_5dayForecast?lat=$lat&lon=$lon&units=metric&appid=$apiKey';

    try {
      isLoading = true;
      notifyListeners();

      final weatherResponse = await http.get(Uri.parse(url));
      final forecastResponse = await http.get(Uri.parse(forecastUrl));

      if (weatherResponse.statusCode == 200 && forecastResponse.statusCode == 200) {
        final weatherJson = jsonDecode(weatherResponse.body);
        final forecastJson = jsonDecode(forecastResponse.body);

        weatherData = WeatherData.fromJson(weatherJson);
        cityName = weatherJson['name'];

        // Hourly forecast (next 8 forecasts)
        hourlyForecast = List<Map<String, dynamic>>.from(
          forecastJson['list'].take(8).map((e) => {
            'time': e['dt_txt'],
            'temp': e['main']['temp'],
            'icon': e['weather'][0]['icon'],
          }),
        );

        // Daily forecast (7 days)
        dailyForecast = processDailyForecast(forecastJson['list']);

        errorMessage = null;
      } else {
        errorMessage = "Failed to fetch data.";
      }
    } catch (e) {
      errorMessage = "Error: $e";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  List<Map<String, dynamic>> processDailyForecast(List<dynamic> forecastList) {
    Map<String, List<dynamic>> groupedByDay = {};
    
    for (var forecast in forecastList) {
      DateTime date = DateTime.parse(forecast['dt_txt']);
      String dayKey = "${date.year}-${date.month}-${date.day}";
      
      if (!groupedByDay.containsKey(dayKey)) {
        groupedByDay[dayKey] = [];
      }
      groupedByDay[dayKey]!.add(forecast);
    }
    
    List<Map<String, dynamic>> dailyData = [];
    List<String> sortedDays = groupedByDay.keys.toList()..sort();
    
    for (var day in sortedDays.take(7)) {
      var dayForecasts = groupedByDay[day]!;
      
      double maxTemp = dayForecasts.map((f) => f['main']['temp_max'] as double).reduce((a, b) => a > b ? a : b);
      double minTemp = dayForecasts.map((f) => f['main']['temp_min'] as double).reduce((a, b) => a < b ? a : b);
      
      // Get the most common weather condition for the day
      var mostCommonCondition = dayForecasts
          .map((f) => f['weather'][0])
          .fold<Map<String, int>>({}, (map, condition) {
            String key = "${condition['id']}-${condition['main']}";
            map[key] = (map[key] ?? 0) + 1;
            return map;
          })
          .entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key
          .split('-')[1];
      
      String icon = dayForecasts.first['weather'][0]['icon'];
      
      dailyData.add({
        'date': dayForecasts.first['dt_txt'].toString().split(' ')[0],
        'day': _getDayName(DateTime.parse(dayForecasts.first['dt_txt'])),
        'max_temp': maxTemp,
        'min_temp': minTemp,
        'condition': mostCommonCondition,
        'icon': icon,
      });
    }
    
    return dailyData;
  }
  
  String _getDayName(DateTime date) {
    return ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][date.weekday % 7];
  }

  Future<void> fetchWeatherByCity(String city) async {
    final apiKey = dotenv.env['OPENWEATHERMAP_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      errorMessage = 'API key is missing.';
      notifyListeners();
      return;
    }

    final url = '$_geoCodingBaseUrl?q=$city&limit=1&appid=$apiKey';

    try {
      isLoading = true;
      notifyListeners();

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (data.isEmpty) {
          errorMessage = "City not found.";
        } else {
          final lat = data[0]['lat'];
          final lon = data[0]['lon'];
          cityName = city;
          await fetchWeatherByLocation(lat, lon);
          return;
        }
      } else {
        errorMessage = "Failed to fetch city coordinates.";
      }
    } catch (e) {
      errorMessage = "Error: $e";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchCurrentLocationWeather() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        errorMessage = "Location services are disabled.";
        notifyListeners();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          errorMessage = "Location permission denied.";
          notifyListeners();
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      await fetchWeatherByLocation(position.latitude, position.longitude);
    } catch (e) {
      errorMessage = "Location error: $e";
      notifyListeners();
    }
  }
}
