import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/connectivity_provider.dart';
import 'no_internet_widget.dart';

class ConnectivityWrapper extends StatelessWidget {
  final Widget child;
  final Widget? offlineWidget;
  final Widget? loadingWidget;
  final VoidCallback? onRetry;

  const ConnectivityWrapper({
    super.key,
    required this.child,
    this.offlineWidget,
    this.loadingWidget,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivity, cachedChild) {
        // Only block on the very first probe.
        if (connectivity.isChecking && !connectivity.hasCheckedOnce) {
          return loadingWidget ??
              const Center(child: CircularProgressIndicator());
        }

        // `== false` treats "unknown" as connected (no false-offline flash).
        if (connectivity.isConnected == false) {
          return offlineWidget ??
              NoInternetWidget(
                onRetry: onRetry ?? connectivity.checkConnectivity,
                message: 'No Internet Connection',
                subMessage: 'Please check your connection and try again',
              );
        }

        return cachedChild!;
      },
      child: child,
    );
  }
}