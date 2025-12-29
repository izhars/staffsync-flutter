class AppConstants {
  static const String appName = 'Employee Management';
  static const Duration apiTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;
  static const String olaApiKey = '81BdA7HuHsQVRzEShFlU0BZTyAjpmDBaxd4zBmiJ';

  // Centralized base URLs
  static const String _baseLocal = 'http://192.168.1.67:5000';
  // static const String _baseProduction = 'https://hrmbackend-production-0020.up.railway.app';

  // Choose active base (easy switch for dev/prod)
  static const String _activeBase = _baseLocal;
  // static const String _activeBase = _baseProduction;

  // Exposed URLs - NO direct hardcoding anywhere else
  static const String apiBaseUrl = '$_activeBase/api';
  static const String socketBaseUrl = _activeBase;  // Socket.IO base (no /api)
}

// final NetworkService _networkService = NetworkService();
// final AuthService _authService = AuthService();
//
// // ---------------------------------------------------------
// // 🔐 Get current user ID
// // ---------------------------------------------------------
// Future<String> getCurrentUserId() async {
//   final userData = await _authService.getCurrentUser();
//   if (userData == null) {
//     throw Exception('User not authenticated. Please login.');
//   }
//   return userData.id;
// }