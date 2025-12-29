import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/connectivity_service.dart';

class ConnectivityProvider extends ChangeNotifier {
  final ConnectivityService _connectivityService = ConnectivityService();
  bool _isConnected = true;
  bool _isChecking = false;
  StreamSubscription<bool>? _connectivitySubscription;

  bool get isConnected => _isConnected;
  bool get isChecking => _isChecking;

  ConnectivityProvider() {
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    await checkConnectivity();

    // Listen to connectivity changes
    _connectivitySubscription = _connectivityService.connectionStream.listen((hasConnection) {
      _isConnected = hasConnection;
      notifyListeners();
    });
  }

  Future<void> checkConnectivity() async {
    _isChecking = true;
    notifyListeners();

    try {
      _isConnected = await _connectivityService.hasConnection();
    } catch (e) {
      _isConnected = false;
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}