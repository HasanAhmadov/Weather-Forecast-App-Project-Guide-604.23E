# 🌤️ Weather Forecast App 

A sleek and functional cross-platform weather forecast application built with **Flutter**. Fetch real-time weather data for any city and view it in a beautiful, intuitive interface.

## ✨ Features

- **🌍 Real-time Weather Data**: Get current weather conditions for any city worldwide.
- **📱 Cross-Platform**: Runs seamlessly on **Android**, **iOS**, **Web**, **Windows**, **Linux**, and **macOS**.
- **🎨 Clean UI**: Built with Flutter's modern toolkit for a smooth and responsive user experience.
- **🔐 Secure API Key Management**: Uses a `.env` file to securely store sensitive API keys.
- **🧩 Modular Architecture**: Organized codebase with clear separation of concerns.

## 🏗️ Project Structure
Weather-Forecast-App-Project-Guide-604.23E/
├── android/ 
├── ios/ 
├── lib/ 
│ ├── models/
│ │ └── weather_model.dart 
│ ├── pages/
│ │ └── home_page.dart 
│ ├── services/
│ │ ├── city_service.dart 
│ │ └── weather_service.dart 
│ ├── flutterapikey.env 
│ └── main.dart 
├── web/ 
├── windows/ 
├── pubspec.yaml 
└── pubspec.lock 

### Code Flow
`HomePage` (UI) → `WeatherService` (API Call) → `WeatherModel` (Data Parsing) → `HomePage` (UI Update)

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK**: Ensure you have Flutter installed on your machine. [Install Flutter](https://docs.flutter.dev/get-started/install)
- **An IDE**: **Visual Studio Code** (with Flutter/Dart extensions) or **Android Studio**.
- **Weather API Key**: You will need an API key from a weather service like [OpenWeatherMap](https://openweathermap.org/api).

### Installation & Setup

1.  **Clone the repository**
    ```bash
    git clone https://github.com/HasanAhmadov/Weather-Forecast-App-Project-Guide-604.23E.git
    cd Weather-Forecast-App-Project-Guide-604.23E
    ```

2.  **Get dependencies**
    Run the following command to install all the required packages listed in `pubspec.yaml`:
    ```bash
    flutter pub get
    ```

3.  **Configure your API Key**
    - The project expects a `flutterapikey.env` file in the `lib/` directory.
    - Create this file and add your API key in the following format:
      ```env
      WEATHER_API_KEY=your_actual_api_key_here
      ```
    - **CRUCIAL**: Ensure this file is listed in your **.gitignore** to prevent accidentally exposing your secret key.

4.  **Run the application**
    Connect a device/emulator or ensure Chrome is available for web, then run:
    ```bash
    flutter run
    ```
    You can also specify a target device:
    ```bash
    flutter run -d chrome    # for web
    flutter run -d android   # for android
    ```

## 🧪 Testing

To run the unit tests for the project, use the following command:

```bash
flutter test
📦 Dependencies
This project leverages the following key packages (as defined in pubspec.yaml):

http: For making HTTP requests to the weather API.

flutter_dotenv: For loading environment variables from the .env file.

🙏 Acknowledgments
The Flutter team for the incredible SDK.

Weather data providers like OpenWeatherMap.

The Dart and Flutter community for their packages and support.
