class VersionConfig {
  static const String appName = 'Desby OS';
  static const String version = '1.0.0';
  static const String buildNumber = '1';
  static const String environment = 'Alpha';
  
  static String get fullVersion => '$version ($buildNumber)-$environment';
}
