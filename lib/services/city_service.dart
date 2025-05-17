import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CityService {
  static Future<List<String>> fetchCitySuggestions(String query) async {
    final apiKey = dotenv.env['OPENWEATHERMAP_API_KEY']; // Ensure this is loaded in main.dart
    final url = Uri.parse('http://api.openweathermap.org/geo/1.0/direct?q=$query&limit=5&appid=$apiKey');

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map<String>((city) => "${city['name']}, ${city['country']}").toList();
    } else {
      return [];
    }
  }
}
