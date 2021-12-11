import 'package:test/test.dart';
import 'package:device_apps/device_apps.dart';

void main() {
  test('Get Notifications', () async {
    DeviceApps.openappNotifications("com.google.android.youtube");
  });
  test('Get Installed Aps', () async {
    DeviceApps.getInstalledApplications(onlyAppsWithLaunchIntent: true, includeAppIcons: true, includeSystemApps: true);
  });

}

