import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:device_apps/device_apps.dart';

void main() {
  test('Get Notifications', () async {
    DeviceApps.openappNotifications("com.google.android.youtube");
  });
  test('Try fuzzy', () async {
    print(await DeviceApps.findMostAccuratePackage("youtube"));
  });

/*  const MethodChannel channel =  MethodChannel('g123k/device_apps');

  test('Get Installed Aps', () async {
    await .invokeMethod('getInstalledApps', <String, bool>{
    'system_apps': includeSystemApps,
    'include_app_icons': includeAppIcons,
    'only_apps_with_launch_intent': onlyAppsWithLaunchIntent
    }); });

}
  void mockPackageInfo() {

    handler(MethodCall methodCall) async {
      if (methodCall.method == 'getInstalledApps') {
        return <String, dynamic>{
          'appName': 'myapp',
          'packageName': 'com.mycompany.myapp',
          'version': '0.0.1',
          'buildNumber': '1'
        };
      }
      return null;
    }

    TestWidgetsFlutterBinding.ensureInitialized();

    TestDefaultBinaryMessengerBinding.instance!.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, handler); */
  }

