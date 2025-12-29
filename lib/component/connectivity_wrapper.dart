import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/connectivity_provider.dart';
import '../component/NoInternetWidget.dart';

class ConnectivityWrapper extends StatelessWidget {
  final Widget child;
  final Widget? offlineWidget;
  final VoidCallback? onRetry;

  const ConnectivityWrapper({
    super.key,
    required this.child,
    this.offlineWidget,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityProvider>(
      builder: (context, connectivity, childWidget) {
        // If provider is found, show connectivity-aware UI
        if (connectivity.isChecking) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!connectivity.isConnected) {
          return offlineWidget ??
              NoInternetWidget(
                onRetry: onRetry ?? () => connectivity.checkConnectivity(),
                message: "No Internet Connection",
                subMessage: "Please check your connection and try again",
              );
        }

        return childWidget!;
      },
      child: child,
    );
  }
}