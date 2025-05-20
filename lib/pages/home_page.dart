// ignore_for_file: use_build_context_synchronously, unnecessary_string_interpolations

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/weather_service.dart';
import '../services/city_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> savedCities = [];

  @override
  void initState() {
    super.initState();
    _loadSavedCities();
    Future.microtask(() =>
        Provider.of<WeatherService>(context, listen: false).fetchCurrentLocationWeather());
  }

  Future<void> _loadSavedCities() async {
    final prefs = await SharedPreferences.getInstance();
    final cities = prefs.getStringList('savedCities') ?? [];
    setState(() {
      savedCities = cities;
    });
  }

  Future<void> _saveCities() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('savedCities', savedCities);
  }

  Future<void> _addCityToSaved(String city) async {
    if (!savedCities.contains(city)) {
      setState(() {
        savedCities.add(city);
      });
      await _saveCities();
    }
  }

  Future<void> _showCitySearchDialog() async {
  final weatherService = Provider.of<WeatherService>(context, listen: false);
  final city = await showDialog<String>(
    context: context,
    builder: (context) {
      String selectedCity = '';
      return AlertDialog(
        backgroundColor: Colors.white, // Set dialog background to white
        title: const Text("Search City", style: TextStyle(color: Colors.black)),
        content: SizedBox(
          height: 60,
          child: TypeAheadField<String>(
            textFieldConfiguration: TextFieldConfiguration(
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: "Enter city",
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Colors.white,
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  borderSide: BorderSide(color: Colors.blue, width: 2),
                ),
              ),
            ),
            suggestionsCallback: (pattern) async {
              return await CityService.fetchCitySuggestions(pattern);
            },
            suggestionsBoxDecoration: SuggestionsBoxDecoration(
              color: Colors.white, // Suggestions box background
              borderRadius: BorderRadius.circular(8),
            ),
            itemBuilder: (context, String suggestion) {
              return ListTile(
                title: Text(suggestion, style: const TextStyle(color: Colors.black)),
              );
            },
            onSuggestionSelected: (String suggestion) {
              selectedCity = suggestion.split(',')[0];
              Navigator.of(context).pop(selectedCity);
            },
          ),
        ),
        actions: [
          TextButton(
            child: const Text("Cancel", style: TextStyle(color: Colors.black)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
    },
  );
  if (city != null && city.isNotEmpty) {
    await weatherService.fetchWeatherByCity(city);
    await _addCityToSaved(city);
  }
}

  @override
  Widget build(BuildContext context) {
    final weatherService = Provider.of<WeatherService>(context);

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text(
  "Weather Forecast",
  style: TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.2,
    color: Colors.white,
    fontFamily: 'Roboto', // Optional: use a custom font
  ),
),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search City',
            onPressed: _showCitySearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.bookmark),
            tooltip: 'Recent Locations',
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => SavedLocationsPage(savedCities: savedCities),
                ),
              );
              if (result != null) {
                if (result is String) {
                  await weatherService.fetchWeatherByCity(result);
                } else if (result is List<String>) {
                  setState(() {
                    savedCities = result;
                  });
                  await _saveCities();
                }
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: weatherService.isLoading
            ? const Center(child: CircularProgressIndicator())
            : weatherService.errorMessage != null
                ? Center(child: Text(weatherService.errorMessage!, style: const TextStyle(color: Colors.red)))
                : weatherService.weatherData == null
                    ? const Center(child: Text("No weather data"))
                    : ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Current Weather Card - Enhanced
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.blue, Colors.lightBlueAccent],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  weatherService.cityName ?? 'Unknown',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.network(
                                      'http://openweathermap.org/img/wn/${weatherService.weatherData!.weatherIcon}@4x.png',
                                      width: 100,
                                      height: 100,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      '${weatherService.weatherData!.temperature}°C',
                                      style: const TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.w300,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  weatherService.weatherData!.condition,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildWeatherDetail(
                                      icon: Icons.water_drop,
                                      value: '${weatherService.weatherData!.humidity}%',
                                      label: 'Humidity',
                                    ),
                                    _buildWeatherDetail(
                                      icon: Icons.air,
                                      value: '${weatherService.weatherData!.windSpeed} m/s',
                                      label: 'Wind',
                                    ),
                                    _buildWeatherDetail(
                                      icon: Icons.thermostat,
                                      value: '${weatherService.weatherData!.feelsLike}°C',
                                      label: 'Feels Like',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),
const Center(
  child: Text(
    "Hourly Forecast",
    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
  ),
),
const SizedBox(height: 10),
Center(
  child: SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: weatherService.hourlyForecast.map((forecast) {
        final time = forecast['time'].toString().split(' ')[1].substring(0, 5);
        final temp = (forecast['temp'] as num).toDouble().toStringAsFixed(1);
        final icon = forecast['icon'];
        return Container(
          width: 80,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                offset: Offset(0, 2),
          )],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(time, style: const TextStyle(fontSize: 14, color: Colors.black)),
              Image.network(
                'http://openweathermap.org/img/wn/$icon@2x.png',
                width: 50,
                height: 50,
              ),
              Text(
                '$temp°C', 
                style: const TextStyle(
                  fontSize: 14, 
                  color: Colors.black,
                  fontWeight: FontWeight.bold, // Added this line
                ),
              ),
            ],
          ),
        );
      }).toList(),
    ),
  ),
),
const SizedBox(height: 30),

                          // Daily Forecast
                          const Center(
  child: Text(
    "Daily Forecast",
    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
  ),
),

                          const SizedBox(height: 10),
                          Column(
                            children: weatherService.dailyForecast.map((daily) {
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    SizedBox(
                                      width: 80,
                                      child: Text(
                                        daily['day'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                    Image.network(
                                      'http://openweathermap.org/img/wn/${daily['icon']}@2x.png',
                                      width: 40,
                                      height: 40,
                                    ),
                                    SizedBox(
                                      width: 100,
                                      child: Text(
                                        daily['condition'],
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black54,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          "H: ${(daily['max_temp'] as num).toDouble().toStringAsFixed(1)}°C",
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.red,
                                          ),
                                        ),
                                        Text(
                                          "L: ${(daily['min_temp'] as num).toDouble().toStringAsFixed(1)}°C",
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
      ),
    );
  }

  Widget _buildWeatherDetail({required IconData icon, required String value, required String label}) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 30),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class SavedLocationsPage extends StatefulWidget {
  final List<String> savedCities;
  const SavedLocationsPage({super.key, required this.savedCities});

  @override
  State<SavedLocationsPage> createState() => _SavedLocationsPageState();
}

class _SavedLocationsPageState extends State<SavedLocationsPage> {
  late List<String> cities;

  @override
  void initState() {
    super.initState();
    cities = List.from(widget.savedCities);
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      title: const Text('Recent Locations'),
      backgroundColor: Colors.blue,
    ),
    body: cities.isEmpty

        ? const Center(child: Text('No recent locations', style: TextStyle(color: Colors.black)))
        : ListView.builder(
            itemCount: cities.length,
            itemBuilder: (context, index) {
              final city = cities[index];
              return ListTile(
                title: Text(city, style: TextStyle(color: Colors.black, fontSize: 24),),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    setState(() {
                      cities.removeAt(index);
                    });
                  },
                ),
                onTap: () {
                  Navigator.of(context).pop(city);
                },
              );  
            },
          ),
    // Removed the floatingActionButton property completely
  );
}
} 