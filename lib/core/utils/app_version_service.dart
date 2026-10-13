import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// 全局统一的应用版本信息服务
class AppVersionService {
  static final AppVersionService instance = AppVersionService._internal();

  AppVersionService._internal();

  /// 与 pubspec.yaml (1.0.3+1008) 匹配的默认兜底版本号
  static const String _defaultVersion = '1.0.3';
  static const String _defaultBuildNumber = '1008';

  String _version = _defaultVersion;
  String _buildNumber = _defaultBuildNumber;
  bool _initialized = false;

  /// 主版本号（例如 "1.0.3"）
  String get version => _version;

  /// 构建版本号（例如 "1008"）
  String get buildNumber => _buildNumber;

  /// 带有前缀的简洁版本号（例如 "v1.0.3"）
  String get shortVersion => 'v$_version';

  /// 完整版本号（例如 "v1.0.3+1008"）
  String get fullVersion =>
      _buildNumber.isNotEmpty ? 'v$_version+$_buildNumber' : 'v$_version';

  /// 启动时异步读取平台原生版本号并缓存
  Future<void> initialize() async {
    if (_initialized) return;
    try {
      final info = await PackageInfo.fromPlatform();
      if (info.version.isNotEmpty) {
        _version = info.version;
      }
      if (info.buildNumber.isNotEmpty) {
        _buildNumber = info.buildNumber;
      }
      _initialized = true;
    } catch (e) {
      debugPrint('获取应用版本信息失败: $e');
    }
  }
}
