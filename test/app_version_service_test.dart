import 'package:flutter_test/flutter_test.dart';
import 'package:miru/core/utils/app_version_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('默认版本与格式校验', () {
    final service = AppVersionService.instance;
    expect(service.version, equals('1.0.3'));
    expect(service.buildNumber, equals('1008'));
    expect(service.shortVersion, equals('v1.0.3'));
    expect(service.fullVersion, equals('v1.0.3+1008'));
  });

  test('读取平台版本号初始化', () async {
    PackageInfo.setMockInitialValues(
      appName: 'Miru',
      packageName: 'com.miru.app',
      version: '1.0.3',
      buildNumber: '1008',
      buildSignature: '',
    );

    final service = AppVersionService.instance;
    await service.initialize();

    expect(service.fullVersion, equals('v1.0.3+1008'));
  });
}
