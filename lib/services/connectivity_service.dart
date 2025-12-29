import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  // Check if device has internet connection
  Future<bool> hasConnection() async {
    final results = await _connectivity.checkConnectivity();
    return _hasConnectionResult(results);
  }

  // Check connectivity from connectivity results
  bool _hasConnectionResult(List<ConnectivityResult> results) {
    return results.contains(ConnectivityResult.mobile) ||
        results.contains(ConnectivityResult.wifi) ||
        results.contains(ConnectivityResult.ethernet) ||
        results.contains(ConnectivityResult.vpn) ||
        results.contains(ConnectivityResult.other);
  }

  // Stream for continuous connectivity monitoring
  Stream<bool> get connectionStream {
    return _connectivity.onConnectivityChanged.map((results) {
      return _hasConnectionResult(results);
    });
  }

  // Get current connectivity status as string
  Future<String> getConnectionStatus() async {
    final results = await _connectivity.checkConnectivity();

    if (results.contains(ConnectivityResult.mobile)) return 'Mobile';
    if (results.contains(ConnectivityResult.wifi)) return 'WiFi';
    if (results.contains(ConnectivityResult.ethernet)) return 'Ethernet';
    if (results.contains(ConnectivityResult.vpn)) return 'VPN';
    if (results.contains(ConnectivityResult.other)) return 'Other';

    return 'No Internet';
  }
}