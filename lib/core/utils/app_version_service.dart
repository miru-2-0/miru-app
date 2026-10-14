import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// 全局统一的应用版本信息服务，动态从原生平台与 pubspec.yaml 读取版本
class AppVersionService {
  static final AppVersionService instance = AppVersionService._internal();

  AppVersionService._internal();

  String _version = '';
  String _buildNumber = '';
  bool _initialized = false;

  /// 主版本号（例如 "1.0.4"，未初始化前为空）
  String get version => _version;

  /// 构建版本号（例如 "1013"，未初始化前为空）
  String get buildNumber => _buildNumber;

  /// 带有前缀的简洁版本号（例如 "v1.0.4"）
  String get shortVersion => _version.isNotEmpty ? 'v$_version' : '';

  /// 完整版本号（例如 "v1.0.4+1013"）
  String get fullVersion {
    if (_version.isEmpty) return '';
    return _buildNumber.isNotEmpty ? 'v$_version+$_buildNumber' : 'v$_version';
  }

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
