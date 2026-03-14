import 'package:package_info_plus/package_info_plus.dart';
import '../core/utils/logger.dart';

/// Service for managing app version information
/// Uses package_info_plus to fetch dynamic version from pubspec.yaml
class AppVersionService {
  static final AppVersionService _instance = AppVersionService._internal();
  static AppVersionService get instance => _instance;
  factory AppVersionService() => _instance;
  AppVersionService._internal();

  PackageInfo? _packageInfo;
  
  /// Initialize the service - call this during app startup
  Future<void> init() async {
    try {
      _packageInfo = await PackageInfo.fromPlatform();
    } catch (e) {
      AppLogger.warning('Failed to get package info: $e');
    }
  }

  /// Get the app version string (e.g., "1.0.0")
  String get version => _packageInfo?.version ?? '1.0.0';

  /// Get the build number (e.g., "1")
  String get buildNumber => _packageInfo?.buildNumber ?? '1';

  /// Get the full version string (e.g., "1.0.0+1")
  String get fullVersion => '$version+$buildNumber';

  /// Get display version with label (e.g., "Version 1.0.0 Beta")
  String get displayVersion {
    final v = version;
    // Add Beta suffix for pre-1.0.0 or explicit beta versions
    final isBeta = v.startsWith('0.') || v.contains('beta') || v.contains('Beta');
    return isBeta ? 'Version $v Beta' : 'Version $v';
  }

  /// Get short display (e.g., "v1.0.0")
  String get shortVersion => 'v$version';

  /// App name
  String get appName => _packageInfo?.appName ?? 'MVGR NexUs';

  /// Package name
  String get packageName => _packageInfo?.packageName ?? 'com.mvgr.mvgr_nexus';
}
