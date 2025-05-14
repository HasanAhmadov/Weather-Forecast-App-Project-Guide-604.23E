// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/weather_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        Provider.of<WeatherService>(context, listen: false).fetchCurrentLocationWeather());
  }

  @override
  Widget build(BuildContext context) {
    final weatherService = Provider.of<WeatherService>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Weather Forecast")),
      body: weatherService.isLoading
          ? const Center(child: CircularProgressIndicator())
          : weatherService.errorMessage != null
              ? Center(child: Text(weatherService.errorMessage!))
              : weatherService.weatherData == null
                  ? const Center(child: Text("No weather data"))
                  : Column(
                      children: [
                        Text("Temperature: ${weatherService.weatherData!.temperature}°C"),
                        Text("Condition: ${weatherService.weatherData!.condition}"),
                        Text("Humidity: ${weatherService.weatherData!.humidity}%"),
                        Text("Wind Speed: ${weatherService.weatherData!.windSpeed} m/s"),
                        
                          
                        ],
                      ),
                      
                    
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final city = await showDialog<String>(
            context: context,
            builder: (context) {
              String? cityName;
              return AlertDialog(
                title: const Text("Enter City Name"),
                content: TextField(
                  onChanged: (value) {
                    cityName = value;
                  },
                  decoration: const InputDecoration(hintText: "City Name"),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(cityName),
                    child: const Text("OK"),
                  ),
                ],
              );
            },
          );
          if (city != null && city.isNotEmpty) {
            await weatherService.fetchWeatherByCity(city);
          }
        },
        child: const Icon(Icons.search),
      
      ),
    );
  }
}
