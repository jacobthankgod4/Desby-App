import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/logging/logger.dart';

/// Device Info Provider
final deviceInfoProvider = FutureProvider<DeviceInfo>((ref) async {
  try {
    logger.debug('Fetching device information');
    
    final deviceInfoPlugin = DeviceInfoPlugin();
    final packageInfo = await PackageInfo.fromPlatform();
    
    return DeviceInfo(
      packageInfo: packageInfo,
      deviceInfoPlugin: deviceInfoPlugin,
    );
  } catch (e, stackTrace) {
    logger.error(
      'Failed to fetch device information',
      error: e,
      stackTrace: stackTrace,
    );
    rethrow;
  }
});

/// App Version Provider
final appVersionProvider = FutureProvider<String>((ref) async {
  final deviceInfo = await ref.watch(deviceInfoProvider.future);
  return deviceInfo.packageInfo.version;
});

/// App Build Number Provider
final appBuildNumberProvider = FutureProvider<String>((ref) async {
  final deviceInfo = await ref.watch(deviceInfoProvider.future);
  return deviceInfo.packageInfo.buildNumber;
});

/// Device Model Provider
final deviceModelProvider = FutureProvider<String>((ref) async {
  try {
    // Platform-specific device model
    // This is a simplified version - actual implementation would be platform-specific
    return 'Unknown Device';
  } catch (e) {
    logger.warning('Failed to get device model: $e');
    return 'Unknown Device';
  }
});

/// Device Info Class
class DeviceInfo {
  final PackageInfo packageInfo;
  final DeviceInfoPlugin deviceInfoPlugin;

  DeviceInfo({
    required this.packageInfo,
    required this.deviceInfoPlugin,
  });

  String get appName => packageInfo.appName;
  String get packageName => packageInfo.packageName;
  String get version => packageInfo.version;
  String get buildNumber => packageInfo.buildNumber;
  String get buildSignature => packageInfo.buildSignature;

  @override
  String toString() => '''
DeviceInfo(
  appName: $appName,
  packageName: $packageName,
  version: $version,
  buildNumber: $buildNumber,
)
''';
}

/// App Metadata Provider
final appMetadataProvider = FutureProvider<AppMetadata>((ref) async {
  try {
    final deviceInfo = await ref.watch(deviceInfoProvider.future);
    
    return AppMetadata(
      appName: deviceInfo.appName,
      packageName: deviceInfo.packageName,
      version: deviceInfo.version,
      buildNumber: deviceInfo.buildNumber,
      buildSignature: deviceInfo.buildSignature,
    );
  } catch (e, stackTrace) {
    logger.error(
      'Failed to fetch app metadata',
      error: e,
      stackTrace: stackTrace,
    );
    rethrow;
  }
});

/// App Metadata Class
class AppMetadata {
  final String appName;
  final String packageName;
  final String version;
  final String buildNumber;
  final String buildSignature;

  AppMetadata({
    required this.appName,
    required this.packageName,
    required this.version,
    required this.buildNumber,
    required this.buildSignature,
  });

  String get versionString => '$version+$buildNumber';

  @override
  String toString() => '''
AppMetadata(
  appName: $appName,
  packageName: $packageName,
  version: $versionString,
)
''';
}
