import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static late SharedPreferences _prefs;
  
  // MQTT Configuration
  static const String mqttBrokerUrl = 'broker.hivemq.com';
  static const int mqttPort = 1883;
  static const String mqttClientId = 'flutter_iot_ewaste';
  
  // Topic patterns for different sensors
  static const String voltageTopicPattern = 'car/{carId}/voltage';
  static const String temperatureTopicPattern = 'car/{carId}/temperature';
  static const String batteryTopicPattern = 'car/{carId}/battery';
  static const String alternatorTopicPattern = 'car/{carId}/alternator';
  
  // Firebase Configuration
  static const String firestoreUsersCollection = 'users';
  static const String firestoreCarsCollection = 'cars';
  static const String firestoreSensorDataCollection = 'sensor_data';
  static const String firestoreEWasteLocationsCollection = 'ewaste_locations';
  
  // Google Maps API
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
  
  // Prediction Thresholds
  static const double lowVoltageThreshold = 11.5; // Volts
  static const double highTemperatureThreshold = 80.0; // Celsius
  static const double criticalBatteryLevel = 20.0; // Percentage
  
  // Cache durations
  static const Duration cacheRefreshInterval = Duration(minutes: 5);
  static const Duration dataRetentionPeriod = Duration(days: 30);

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static SharedPreferences get prefs => _prefs;
  
  // Helper methods for storing user preferences
  static Future<void> setThemeMode(String mode) async {
    await _prefs.setString('theme_mode', mode);
  }
  
  static String getThemeMode() {
    return _prefs.getString('theme_mode') ?? 'system';
  }
  
  static Future<void> setNotificationsEnabled(bool enabled) async {
    await _prefs.setBool('notifications_enabled', enabled);
  }
  
  static bool getNotificationsEnabled() {
    return _prefs.getBool('notifications_enabled') ?? true;
  }
}
