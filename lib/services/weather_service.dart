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

  
  final String _geoCodingBaseUrl = 'http://api.openweathermap.org/geo/1.0/direct';
  final String _5dayForecast = 'https://api.openweathermap.org/data/2.5/forecast';
  final String _currentWeather =  'https://api.openweathermap.org/data/2.5/weather';
  final String _weatherIcons =  'http://openweathermap.org/img/wn/'; 
  Future<void> fetchWeatherByLocation(double lat, double lon) async {
    final apiKey = dotenv.env['OPENWEATHERMAP_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      errorMessage = 'API key is missing.';
      notifyListeners();
      return;
    }

    final url = '$_currentWeather?lat=$lat&lon=$lon&units=metric&appid=$apiKey'; 
    '$_5dayForecast?lat=$lat&lon=$lon&units=metric&appid=$apiKey';
    print('Fetching weather from: $url');

    try {
      isLoading = true;
      notifyListeners();

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        weatherData = WeatherData.fromJson(json);
        errorMessage = null;
      } else {
        errorMessage = "Failed to fetch weather data: ${response.statusCode} ${response.body}";
      }
    } catch (e) {
      errorMessage = "Error: $e";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchWeatherByCity(String city) async {
    final apiKey = dotenv.env['OPENWEATHERMAP_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      errorMessage = 'API key is missing.';
      notifyListeners();
      return;
    }

    final url = '$_geoCodingBaseUrl?q=$city&limit=1&appid=$apiKey';
    print('Fetching coordinates for: $city → $url');

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
          await fetchWeatherByLocation(lat, lon);
          return;
        }
      } else {
        errorMessage = "Failed to fetch city coordinates: ${response.statusCode}";
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
