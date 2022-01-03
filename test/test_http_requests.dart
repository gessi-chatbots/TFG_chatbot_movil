import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:device_apps/device_apps.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;

void main() {
  /*test('Open Notifications', () async {
    DeviceApps.openappNotifications("com.google.android.youtube");
  });*/

  const BotResponseSimple = {
    "recipient_id": "123",
    "message": "111111",
  };

  const MethodChannel dev_apps_channel =  MethodChannel('g123k/device_apps');

  setUpAll(() async {
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
        .setMockMethodCallHandler(dev_apps_channel, handler);

  });

  test('Open Notifications', () async {
    bool b = await dev_apps_channel.invokeMethod('openappNotifications',
        <String, String>{'package_name': "com.google.android.youtube"});
  });
}

class MockPostHelper extends Mock implements http.Client {

}
