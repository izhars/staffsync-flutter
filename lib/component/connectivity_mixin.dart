import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import '../services/connectivity_service.dart';

mixin ConnectivityMixin<T extends StatefulWidget> on State<T> {
  final ConnectivityService _connectivityService = ConnectivityService();
  bool _isConnected = true;
  bool _isChecking = false;

  bool get isConnected => _isConnected;
  bool get isChecking => _isChecking;

  Stream<bool> get connectivityStream => _connectivityService.connectionStream;

  @override
  void initState() {
    super.initState();
    _initConnectivity();
  }

  Future<void> _initConnectivity() async {
    await checkConnectivity();

    // Listen to connectivity changes
    connectivityStream.listen((hasConnection) {
      if (mounted) {
        setState(() {
          _isConnected = hasConnection;
        });
        onConnectivityChanged(hasConnection);
      }
    });
  }

  Future<void> checkConnectivity() async {
    if (mounted) {
      setState(() => _isChecking = true);
    }

    try {
      final hasConnection = await _connectivityService.hasConnection();
      if (mounted) {
        setState(() {
          _isConnected = hasConnection;
          _isChecking = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnected = false;
          _isChecking = false;
        });
      }
    }
  }

  // Override this method to handle connectivity changes
  void onConnectivityChanged(bool hasConnection) {
    // Can be overridden by child classes
  }
}