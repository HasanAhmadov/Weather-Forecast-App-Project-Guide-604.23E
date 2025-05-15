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
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "City: ${weatherService.cityName ?? 'Unknown'}",
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Text("Temperature: ${weatherService.weatherData!.temperature}°C"),
                        Text("Condition: ${weatherService.weatherData!.condition}"),
                        Text("Humidity: ${weatherService.weatherData!.humidity}%"),
                        Text("Wind Speed: ${weatherService.weatherData!.windSpeed} m/s"),
                        const SizedBox(height: 30),

                        const Text(
                          "Hourly Forecast",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: weatherService.hourlyForecast.length,
                            itemBuilder: (context, index) {
                              final forecast = weatherService.hourlyForecast[index];
                              final time = forecast['time'].toString().split(' ')[1].substring(0, 5);
                              final temp = forecast['temp'].toStringAsFixed(1);
                              final icon = forecast['icon'];
                              return Container(
                                width: 80,
                                margin: const EdgeInsets.symmetric(horizontal: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(time, style: const TextStyle(fontSize: 14)),
                                    Image.network(
                                      'http://openweathermap.org/img/wn/$icon@2x.png',
                                      width: 50,
                                      height: 50,
                                    ),
                                    Text('$temp°C', style: const TextStyle(fontSize: 14)),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 30),

                        const Text(
                          "Daily Forecast",
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Column(
                          children: weatherService.dailyForecast.map((daily) {
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        daily['day'],
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: Image.network(
                                        'http://openweathermap.org/img/wn/${daily['icon']}@2x.png',
                                        width: 40,
                                        height: 40,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        daily['condition'],
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        "H: ${daily['max_temp'].toStringAsFixed(1)}°C  L: ${daily['min_temp'].toStringAsFixed(1)}°C",
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
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
