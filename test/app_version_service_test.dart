import 'package:flutter_test/flutter_test.dart';
import 'package:miru/core/utils/app_version_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('初始化前版本字符串处理', () {
    final service = AppVersionService.instance;
    expect(service.version, isEmpty);
    expect(service.buildNumber, isEmpty);
    expect(service.shortVersion, isEmpty);
    expect(service.fullVersion, isEmpty);
  });

  test('读取平台动态版本号初始化', () async {
    PackageInfo.setMockInitialValues(
      appName: 'Miru',
      packageName: 'com.miru.app',
      version: '1.0.4',
      buildNumber: '1013',
      buildSignature: '',
    );

    final service = AppVersionService.instance;
    await service.initialize();

    expect(service.version, equals('1.0.4'));
    expect(service.buildNumber, equals('1013'));
    expect(service.shortVersion, equals('v1.0.4'));
    expect(service.fullVersion, equals('v1.0.4+1013'));
  });
}
