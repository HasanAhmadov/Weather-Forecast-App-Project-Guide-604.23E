import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'pages/home_page.dart' ;
import 'services/weather_service.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "lib/flutterapikey.env"); // Updated line
  runApp(const WeatherApp());
}

class WeatherApp extends StatelessWidget {
  const WeatherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => WeatherService(),
      child: MaterialApp(
        title: 'Weather App',
        theme: ThemeData(useMaterial3: true),
        home: const HomePage(),
      ),
    );
  }
}
