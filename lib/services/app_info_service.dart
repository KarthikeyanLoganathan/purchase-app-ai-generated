import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Service for accessing application information like package name, version, etc.
/// Provides a singleton instance for app-wide access to package metadata.
class AppInfoService {
  static AppInfoService? _instance;
  static const String appPackageNameKey = "app-package";
  static const String appNameKey = "app-name";
  static const String appVersionKey = "app-version";
  static const String appBuildKey = "app-build";
  static const String appFullVersionKey = "app-full-version";

  static AppInfoService get instance {
    _instance ??= AppInfoService._();
    return _instance!;
  }

  AppInfoService._();

  PackageInfo? _packageInfo;

  /// Initialize the service by loading package information from the platform.
  /// Must be called before accessing any properties.
  Future<void> initialize() async {
    _packageInfo = await PackageInfo.fromPlatform();
    debugPrint(
        'App initialized: ${_packageInfo!.packageName} v${_packageInfo!.version}');
  }

  /// Returns true if the service has been initialized
  bool get isInitialized => _packageInfo != null;

  /// Package/Bundle identifier (e.g., com.purchase.purchase_app)
  String get packageName => _packageInfo?.packageName ?? 'unknown';

  /// App display name (e.g., purchase_app)
  String get appName => _packageInfo?.appName ?? 'Unknown App';

  /// Version string from pubspec.yaml (e.g., 1.0.0)
  String get version => _packageInfo?.version ?? '0.0.0';

  /// Build number from pubspec.yaml (e.g., 1)
  String get buildNumber => _packageInfo?.buildNumber ?? '0';

  /// Full version string with build number (e.g., 1.0.0+1)
  String get fullVersion => '$version+$buildNumber';

  /// User-Agent string for HTTP requests (e.g., purchase_app/1.0.0)
  String get userAgent => '$appName/$version';

  /// App properties map for Google Drive file tagging
  Map<String, String> get appProperties => {
        appPackageNameKey: packageName,
        appNameKey: appName,
        appVersionKey: version,
        appBuildKey: buildNumber,
        appFullVersionKey: fullVersion,
      };

  /// Build a Google Drive query to find files created by this app
  String buildDriveQuery({
    String? mimeType,
    bool includeTrashed = false,
  }) {
    final parts = <String>[
      "appProperties has { key='app-package' and value='$packageName' }",
    ];

    if (mimeType != null) {
      parts.add("mimeType='$mimeType'");
    }

    if (!includeTrashed) {
      parts.add("trashed=false");
    }

    return parts.join(' and ');
  }

  /// Compare current version with a required version
  /// Returns true if current version >= required version
  bool isVersionAtLeast(String requiredVersion) {
    final current = version.split('.').map(int.tryParse).toList();
    final required = requiredVersion.split('.').map(int.tryParse).toList();

    for (int i = 0; i < 3; i++) {
      final currentPart = i < current.length ? (current[i] ?? 0) : 0;
      final requiredPart = i < required.length ? (required[i] ?? 0) : 0;

      if (currentPart > requiredPart) return true;
      if (currentPart < requiredPart) return false;
    }

    return true; // Equal
  }

  /// HTTP headers for API requests
  Map<String, String> get httpHeaders => {
        'User-Agent': userAgent,
        'X-App-Package': packageName,
        'X-App-Version': version,
        'X-App-Build': buildNumber,
      };
}
