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
          title: const Text("Search City"),
          content: SizedBox(
            height: 60,
            child: TypeAheadField<String>(
              textFieldConfiguration: const TextFieldConfiguration(
                decoration: InputDecoration(
                  hintText: "Enter city",
                ),
              ),
              suggestionsCallback: (pattern) async {
                return await CityService.fetchCitySuggestions(pattern);
              },
              itemBuilder: (context, String suggestion) {
                return ListTile(title: Text(suggestion));
              },
              onSuggestionSelected: (String suggestion) {
                selectedCity = suggestion.split(',')[0];
                Navigator.of(context).pop(selectedCity);
              },
            ),
          ),
          actions: [
            TextButton(
              child: const Text("Cancel"),
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
        title: const Text("Weather Forecast"),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search City',
            onPressed: _showCitySearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.bookmark),
            tooltip: 'Saved Locations',
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => SavedLocationsPage(savedCities: savedCities),
                ),
              );
              if (result != null) {
                if (result is String) {
                  // Выбран город - загружаем погоду
                  await weatherService.fetchWeatherByCity(result);
                } else if (result is List<String>) {
                  // Обновлен список сохраненных городов
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
                          Center(
                            child: Text(
                              weatherService.cityName ?? 'Unknown',
                              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w600, color: Colors.black),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Center(child: Text("Temperature: ${weatherService.weatherData!.temperature}°C", style: const TextStyle(color: Colors.black))),
                          Center(child: Text("Condition: ${weatherService.weatherData!.condition}", style: const TextStyle(color: Colors.black))),
                          Center(child: Text("Humidity: ${weatherService.weatherData!.humidity}%", style: const TextStyle(color: Colors.black))),
                          Center(child: Text("Wind Speed: ${weatherService.weatherData!.windSpeed} m/s", style: const TextStyle(color: Colors.black))),
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
              Text('$temp°C', style: const TextStyle(fontSize: 14, color: Colors.black)),
            ],
          ),
        );
      }).toList(),
    ),
  ),
),
const SizedBox(height: 30),

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
                                margin: const EdgeInsets.symmetric(vertical: 6),
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
                                    Text(
                                      daily['day'],
                                      style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black),
                                    ),
                                    Image.network(
                                      'http://openweathermap.org/img/wn/${daily['icon']}@2x.png',
                                      width: 40,
                                      height: 40,
                                    ),
                                    Text(
                                      daily['condition'],
                                      style: const TextStyle(fontSize: 14, color: Colors.black),
                                    ),
                                    Text(
                                      "H: ${ (daily['max_temp'] as num).toDouble().toStringAsFixed(1)}°C\nL: ${(daily['min_temp'] as num).toDouble().toStringAsFixed(1)}°C",
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(fontSize: 14, color: Colors.black),
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
}

// Экран сохраненных локаций
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
      appBar: AppBar(
        title: const Text('Saved Locations'),
        backgroundColor: Colors.blue,
      ),
      body: cities.isEmpty
          ? const Center(child: Text('No saved locations'))
          : ListView.builder(
              itemCount: cities.length,
              itemBuilder: (context, index) {
                final city = cities[index];
                return ListTile(
                  title: Text(city),
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
      floatingActionButton: cities.isEmpty
          ? null
          : FloatingActionButton.extended(
              icon: const Icon(Icons.save),
              label: const Text('Save Changes'),
              onPressed: () {
                Navigator.of(context).pop(cities);
              },
            ),
    );
  }
}