
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLockGate extends StatefulWidget {
  final Widget child;
  const AppLockGate({super.key, required this.child});

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  final LocalAuthentication _auth = LocalAuthentication();

  /// How long the app can be in the background before re-locking on resume.
  static const Duration _backgroundGracePeriod = Duration(minutes: 5);

  bool _lockEnabled = false;
  bool _isLocked = false;
  bool _authenticating = false;
  bool _initialized = false;
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final prefs = await SharedPreferences.getInstance();
    _lockEnabled = prefs.getBool('app_lock_enabled') ?? false;

    if (!mounted) return;
    setState(() {
      _initialized = true;
      _isLocked = _lockEnabled;
    });

    if (_lockEnabled) {
      await _authenticate();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_lockEnabled) return;

    if (state == AppLifecycleState.paused) {
      // Don't record a pause while the auth dialog itself is showing
      if (!_authenticating) {
        _pausedAt = DateTime.now();
      }
      return;
    }

    if (state == AppLifecycleState.resumed) {
      if (_authenticating || _pausedAt == null) return;
      final away = DateTime.now().difference(_pausedAt!);
      _pausedAt = null;
      if (away >= _backgroundGracePeriod && !_isLocked) {
        setState(() => _isLocked = true);
        _authenticate();
      }
    }
  }

  Future<void> _authenticate() async {
    if (_authenticating) return;
    _authenticating = true;
    try {
      final success = await _auth.authenticate(
        localizedReason: 'Please authenticate to unlock StaffSync',
        options: const AuthenticationOptions(
          biometricOnly: false, // allow PIN / pattern / passcode fallback
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      if (!mounted) return;
      if (success) {
        setState(() => _isLocked = false);
      }
      // If false, stay locked — the Unlock button lets the user retry.
    } catch (_) {
      // Stay locked on any platform error.
    } finally {
      _authenticating = false;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!_lockEnabled || !_isLocked) {
      return widget.child;
    }

    // Locked screen: block back button so the app cannot be dismissed.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Back button is intentionally a no-op while locked.
        // (Optional: show a snackbar "Authenticate to unlock".)
      },
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 64),
                const SizedBox(height: 16),
                const Text(
                  'StaffSync is locked',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Authenticate to continue',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _authenticating ? null : _authenticate,
                  child: _authenticating
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('Unlock'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => SystemNavigator.pop(),
                  child: const Text('Exit app'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}