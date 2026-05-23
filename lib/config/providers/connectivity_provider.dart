import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/logging/logger.dart';

/// Connectivity Provider
/// Monitors network connectivity status
final connectivityProvider = StreamProvider<ConnectivityStatus>((ref) async* {
  final connectivity = Connectivity();
  
  // Get initial status
  final result = await connectivity.checkConnectivity();
  yield _mapConnectivityResult(result);
  
  // Listen to connectivity changes
  await for (final result in connectivity.onConnectivityChanged) {
    logger.info('Connectivity changed: $result');
    yield _mapConnectivityResult(result);
  }
});

/// Map connectivity result to status
ConnectivityStatus _mapConnectivityResult(ConnectivityResult result) {
  return switch (result) {
    ConnectivityResult.wifi => ConnectivityStatus.wifi,
    ConnectivityResult.mobile => ConnectivityStatus.mobile,
    ConnectivityResult.ethernet => ConnectivityStatus.ethernet,
    ConnectivityResult.vpn => ConnectivityStatus.vpn,
    ConnectivityResult.bluetooth => ConnectivityStatus.bluetooth,
    ConnectivityResult.other => ConnectivityStatus.other,
    ConnectivityResult.none => ConnectivityStatus.none,
  };
}

/// Connectivity Status
enum ConnectivityStatus {
  wifi('WiFi'),
  mobile('Mobile'),
  ethernet('Ethernet'),
  vpn('VPN'),
  bluetooth('Bluetooth'),
  other('Other'),
  none('No Connection');

  final String displayName;
  const ConnectivityStatus(this.displayName);

  bool get isConnected => this != ConnectivityStatus.none;
  bool get isOffline => this == ConnectivityStatus.none;
}

/// Is Online Provider
/// Simple boolean provider for checking if device is online
final isOnlineProvider = Provider<bool>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return connectivity.maybeWhen(
    data: (status) => status.isConnected,
    orElse: () => true, // Assume online if unknown
  );
});

/// Is Offline Provider
/// Simple boolean provider for checking if device is offline
final isOfflineProvider = Provider<bool>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return connectivity.maybeWhen(
    data: (status) => status.isOffline,
    orElse: () => false, // Assume online if unknown
  );
});
