class AppConstants {
  static const String appName = 'Employee Management';
  static const String appVersion = '1.0.0';

  // API
  // static const String baseUrl = 'https://staffsync-backend-xp3i.onrender.com';
  static const String baseUrl = 'http://192.168.1.51:7000';
  static const String apiBaseUrl = '$baseUrl/api';
  static const String apiBaseUrlNumber = '$baseUrl/api/plate';
  static const String socketBaseUrl = baseUrl;

  // Timeout & Retry
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration socketTimeout = Duration(seconds: 20);
  static const Duration reconnectDelay = Duration(seconds: 3);
  static const int maxRetries = 3;
  static const int maxReconnectAttempts = 5;

  // Services
  static const String olaApiKey =
      '81BdA7HuHsQVRzEShFlU0BZTyAjpmDBaxd4zBmiJ';

  static const String agoraAppId =
      '0c00953da2be40cda7d04640e5c2812b';
}