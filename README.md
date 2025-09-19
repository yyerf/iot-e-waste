# IoT Car E-Waste Monitoring System

A comprehensive Flutter mobile application for monitoring car electronics and predicting e-waste generation using IoT sensors.

## 🚗 Project Overview

This app helps car owners and mechanics track the health of electronic components in vehicles, predict failures before they occur, and locate proper e-waste disposal centers.

## ✨ Features

### 📊 Real-time Monitoring Dashboard
- Live voltage, temperature, and battery readings
- Visual charts and graphs for historical data
- Component health scoring (0-100)
- Customizable sensor thresholds

### 🔔 Predictive Alerts System
- Low voltage warnings
- Overheating notifications
- Battery degradation alerts
- AI-based failure predictions

### 📈 Data Logging for Mechanics
- Cloud storage of sensor readings
- Export functionality for analysis
- Maintenance history tracking
- Component lifecycle management

### 🗺️ E-Waste Location Finder
- Google Maps integration
- Nearby recycling centers
- Battery disposal locations
- Navigation support

### 👤 User Management
- Firebase Authentication
- Multiple vehicle support
- Profile management
- Social login options

## 🏗️ Project Structure

```
lib/
├── core/
│   ├── config/
│   │   └── app_config.dart
│   ├── models/
│   │   ├── sensor_data.dart
│   │   └── car_model.dart
│   ├── providers/
│   │   └── app_providers.dart
│   ├── router/
│   │   └── app_router.dart
│   ├── services/
│   │   ├── firebase_service.dart
│   │   └── mqtt_service.dart
│   └── theme/
│       └── app_theme.dart
├── features/
│   ├── auth/
│   │   └── presentation/pages/
│   ├── dashboard/
│   │   └── presentation/pages/
│   ├── monitoring/
│   │   └── presentation/pages/
│   ├── alerts/
│   │   └── presentation/pages/
│   ├── maps/
│   │   └── presentation/pages/
│   ├── profile/
│   │   └── presentation/pages/
│   └── onboarding/
│       └── presentation/pages/
├── shared/
│   └── presentation/widgets/
└── main.dart
```

## 📦 Key Dependencies

### State Management
- `flutter_riverpod: ^2.4.6` - Modern state management
- `riverpod_annotation: ^2.3.0` - Code generation for providers

### UI Components
- `fl_chart: ^0.64.0` - Beautiful charts and graphs
- `syncfusion_flutter_charts: ^23.1.36` - Advanced charting
- `lottie: ^2.7.0` - Smooth animations

### Backend & Database
- `firebase_core: ^2.17.0` - Firebase initialization
- `firebase_auth: ^4.10.1` - User authentication
- `cloud_firestore: ^4.9.3` - NoSQL database
- `firebase_storage: ^11.2.8` - File storage

### IoT Communication
- `mqtt_client: ^10.0.0` - MQTT protocol support
- `http: ^1.1.0` - HTTP requests
- `web_socket_channel: ^2.4.0` - WebSocket communication

### Maps & Location
- `google_maps_flutter: ^2.5.0` - Google Maps integration
- `geolocator: ^10.1.0` - GPS location services
- `geocoding: ^2.1.1` - Address conversion

### Local Storage
- `shared_preferences: ^2.2.2` - Simple key-value storage
- `hive: ^2.2.3` - Fast local database
- `sqflite: ^2.3.0` - SQL database

## 🚀 Getting Started

### Prerequisites

1. **Flutter SDK** (3.10.0 or higher)
2. **Firebase Project** setup
3. **Google Maps API Key**
4. **IoT Hardware** (ESP32/Arduino with sensors)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd iot-e-waste
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   ```bash
   # Install FlutterFire CLI
   dart pub global activate flutterfire_cli
   
   # Configure Firebase for your project
   flutterfire configure
   ```

4. **Add Google Maps API Key**
   
   **Android** (`android/app/src/main/AndroidManifest.xml`):
   ```xml
   <meta-data android:name="com.google.android.geo.API_KEY"
              android:value="YOUR_API_KEY"/>
   ```
   
   **iOS** (`ios/Runner/AppDelegate.swift`):
   ```swift
   GMSServices.provideAPIKey("YOUR_API_KEY")
   ```

5. **Generate code**
   ```bash
   flutter packages pub run build_runner build
   ```

6. **Run the app**
   ```bash
   flutter run
   ```

## 🔧 Configuration

### MQTT Broker Setup

Update `lib/core/config/app_config.dart`:

```dart
static const String mqttBrokerUrl = 'your-mqtt-broker.com';
static const int mqttPort = 1883;
```

### Sensor Thresholds

Customize alert thresholds in `app_config.dart`:

```dart
static const double lowVoltageThreshold = 11.5; // Volts
static const double highTemperatureThreshold = 80.0; // Celsius
static const double criticalBatteryLevel = 20.0; // Percentage
```

## 🏭 IoT Hardware Integration

### ESP32 Code Example

```cpp
#include <WiFi.h>
#include <PubSubClient.h>
#include <ArduinoJson.h>

// WiFi credentials
const char* ssid = "YOUR_WIFI_SSID";
const char* password = "YOUR_WIFI_PASSWORD";

// MQTT Broker
const char* mqtt_server = "broker.hivemq.com";
WiFiClient espClient;
PubSubClient client(espClient);

void setup() {
  Serial.begin(115200);
  setup_wifi();
  client.setServer(mqtt_server, 1883);
}

void loop() {
  if (!client.connected()) {
    reconnect();
  }
  client.loop();
  
  // Read sensors
  float voltage = analogRead(A0) * (5.0 / 1023.0);
  float temperature = readTemperature();
  
  // Send data
  sendSensorData("voltage", voltage, "V");
  sendSensorData("temperature", temperature, "C");
  
  delay(30000); // Send every 30 seconds
}

void sendSensorData(String sensorType, float value, String unit) {
  String topic = "car/" + String(CAR_ID) + "/" + sensorType;
  
  StaticJsonDocument<200> doc;
  doc["value"] = value;
  doc["unit"] = unit;
  doc["timestamp"] = millis();
  
  String payload;
  serializeJson(doc, payload);
  
  client.publish(topic.c_str(), payload.c_str());
}
```

## 🔐 Firebase Security Rules

### Firestore Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /cars/{carId} {
      allow read, write: if request.auth != null && request.auth.uid == resource.data.userId;
    }
    
    // Sensor data access
    match /sensor_data/{dataId} {
      allow read, write: if request.auth != null;
    }
    
    // E-waste locations (public read)
    match /ewaste_locations/{locationId} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

## 📱 UI/UX Design Guidelines

### Color Palette
- **Primary Green**: `#2E7D32` - Environmental theme
- **Secondary Green**: `#66BB6A` - Success states
- **Accent Orange**: `#FF8F00` - Warnings
- **Warning Red**: `#D32F2F` - Critical alerts

### Typography
- **Font Family**: Poppins
- **Sizes**: 12px (small), 14px (body), 16px (title), 24px (heading)

### Component Guidelines
- **Cards**: 12px border radius, 2dp elevation
- **Buttons**: 8px border radius, appropriate padding
- **Charts**: Smooth curves, subtle animations

## 🧪 Testing

### Unit Tests
```bash
flutter test
```

### Integration Tests
```bash
flutter test integration_test/
```

### Widget Tests
```bash
flutter test test/widget_test.dart
```

## 📊 Performance Optimization

### Data Management
- **Local Caching**: Use Hive for offline data
- **Pagination**: Load sensor data in chunks
- **Compression**: Compress historical data

### UI Performance
- **Lazy Loading**: Use ListView.builder for large lists
- **Image Caching**: Cache network images
- **Animation Optimization**: Use AnimationController properly

## 🔄 State Management Architecture

### Riverpod Providers

```dart
// Car data provider
final userCarsProvider = StreamProvider<List<Car>>((ref) {
  final firebaseService = ref.watch(firebaseServiceProvider);
  return firebaseService.getUserCars();
});

// Real-time sensor data
final sensorDataStreamProvider = StreamProvider.family<SensorData, String>((ref, carId) {
  final mqttService = ref.watch(mqttServiceProvider);
  return mqttService.getSensorDataStream(carId);
});
```

## 🗺️ Google Maps Integration

### Map Features
- **Custom Markers**: E-waste center types
- **Clustering**: Group nearby locations
- **Directions**: Navigate to selected center
- **Search**: Find centers by name/type

### Example Implementation
```dart
GoogleMap(
  onMapCreated: (GoogleMapController controller) {
    _controller.complete(controller);
  },
  markers: Set<Marker>.from(_ewasteLocations.map((location) =>
    Marker(
      markerId: MarkerId(location.id),
      position: LatLng(location.latitude, location.longitude),
      infoWindow: InfoWindow(title: location.name),
    ),
  )),
)
```

## 📈 Analytics & Monitoring

### Firebase Analytics Events
- `car_added` - New vehicle registration
- `alert_triggered` - Predictive alert fired
- `maintenance_scheduled` - User schedules maintenance
- `ewaste_center_visited` - User navigates to disposal center

### Performance Monitoring
- App crash reporting
- Network request monitoring
- User engagement metrics

## 🚢 Deployment

### Android Release
```bash
flutter build apk --release
```

### iOS Release
```bash
flutter build ios --release
```

### Play Store Setup
1. Create signed APK
2. Upload to Play Console
3. Configure app listing
4. Submit for review

## 🤝 Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/new-feature`)
3. Commit changes (`git commit -am 'Add new feature'`)
4. Push to branch (`git push origin feature/new-feature`)
5. Create Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Troubleshooting

### Common Issues

1. **MQTT Connection Failed**
   - Check broker URL and port
   - Verify network connectivity
   - Ensure firewall allows MQTT traffic

2. **Firebase Auth Errors**
   - Verify project configuration
   - Check API keys
   - Ensure proper platform setup

3. **Maps Not Loading**
   - Verify Google Maps API key
   - Check API quotas and billing
   - Ensure proper platform configuration

### Getting Help

- Create an issue in the repository
- Check the Flutter documentation
- Join the Flutter community on Discord

## 🔮 Future Enhancements

- **Machine Learning**: Advanced failure prediction models
- **Voice Commands**: Hands-free interaction while driving
- **AR Integration**: Augmented reality for component identification
- **Blockchain**: Immutable maintenance records
- **Multi-language**: Support for multiple languages

## 📞 Support

For support, email support@iot-ewaste.com or create an issue in this repository.
