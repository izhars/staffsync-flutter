import 'dart:async';
import 'package:flutter/foundation.dart';
import '../services/connectivity_service.dart';

class ConnectivityProvider extends ChangeNotifier {
  ConnectivityProvider({ConnectivityService? service})
      : _connectivityService = service ?? ConnectivityService() {
    _initConnectivity();
  }

  final ConnectivityService _connectivityService;

  bool _isConnected = true;
  bool _isChecking = false;
  bool _hasCheckedOnce = false;
  bool _disposed = false;

  StreamSubscription<bool>? _connectivitySubscription;

  /// Last known connectivity state. Assume connected until proven otherwise
  /// to avoid a false-offline flash at startup.
  bool get isConnected => _isConnected;

  /// True while a manual probe is in flight.
  bool get isChecking => _isChecking;

  /// True once the first probe has completed (success or failure).
  bool get hasCheckedOnce => _hasCheckedOnce;

  Future<void> _initConnectivity() async {
    await checkConnectivity();

    // Guard against a provider disposed before init finished.
    if (_disposed) return;

    _connectivitySubscription =
        _connectivityService.connectionStream.listen(
              (hasConnection) {
            if (_disposed) return;
            if (hasConnection == _isConnected) return; // skip redundant rebuilds
            _isConnected = hasConnection;
            notifyListeners();
          },
          onError: (Object _) {
            // Stream error → assume offline until next signal.
            if (_disposed || !_isConnected) return;
            _isConnected = false;
            notifyListeners();
          },
        );
  }

  Future<void> checkConnectivity() async {
    if (_isChecking) return; // debounce concurrent checks
    _isChecking = true;
    _safeNotify();

    try {
      _isConnected = await _connectivityService.hasConnection();
    } catch (_) {
      _isConnected = false;
    } finally {
      _isChecking = false;
      _hasCheckedOnce = true;
      _safeNotify();
    }
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    super.dispose();
  }
}