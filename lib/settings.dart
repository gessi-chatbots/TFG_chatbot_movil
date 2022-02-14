import 'package:flutter/material.dart';
import 'package:system_settings/system_settings.dart';
import 'dart:developer';
import 'package:device_apps/device_apps.dart';
import 'dart:io' show Platform;
import 'package:open_settings/open_settings.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tfg_chatbot_movil/chat_page.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login.dart';

class SettingsPage extends StatefulWidget {
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

  @override
  Widget build(BuildContext context) {
    return Semantics(
        label: "Settings screen",
        child: Scaffold(
        appBar: AppBar(
          title: Text('Settings️'),
        ),
        body: MergeSemantics( child: Container(
            padding: const EdgeInsets.only(top: 10),
            child: SettingsList(
              sections: [
                SettingsSection(
                  title: 'Device',
                  tiles: [
                    SettingsTile(
                      title: 'Installed apps',
                      subtitle:
                          'Display a list of the installed apps in the device',
                      leading: const Icon(Icons.apps_sharp, semanticLabel: "Installed Apps",),
                      onPressed: (BuildContext context) {
                        _listapps22(context);
                      },
                    ),
                    /*SettingsTile(
                      title: 'Clear Messages',
                      subtitle: '${messages.length} messages',
                      leading: Icon(Icons.remove_circle),
                      onPressed: (BuildContext context) {
                        throw (UnimplementedError);
                      },
                    ),*/
                    SettingsTile(
                      title: 'Pending Messages',
                      subtitle: '${pendentMessages.length} messages',
                      leading: const Icon(Icons.pending_rounded, semanticLabel: "Pending Messages",),
                      onPressed: (BuildContext context) {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return Dialog(
                                child: pendentMessages.isEmpty
                                    ? Container(
                                        height: 50,
                                        child: Center(child: Text('No Pendent Messages'))
                                      )
                                    : ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: pendentMessages.length,
                                        itemBuilder: (context, index) =>
                                            Card(
                                              child: Text(
                                                pendentMessages[index],
                                                style: Theme.of(context).textTheme.bodyText1!.copyWith(
                                                    color: Colors.blueAccent),
                                              ),
                                            ),
                                      )
                            );
                          },
                        );
                      },
                    ),
                    SettingsTile.switchTile(
                      title: 'Audio',
                      leading: Icon(Icons.multitrack_audio, semanticLabel: "Audio",),
                      switchValue: soundOn,
                      onToggle: (bool value) {
                        setState(() {
                          soundOn = value;
                        });
                        print(soundOn);
                      },
                    ),
                    SettingsTile(
                      title: 'Help',
                      subtitle: '',
                      leading: Icon(Icons.help, semanticLabel: "Help",),
                      onPressed: (BuildContext context) {
                        helpDialog(context);
                      },
                    ),
                  ],
                ),
                SettingsSection(
                  title: 'User',
                  tiles: [
                    SettingsTile(
                      title: '${currentUser!.displayName}',
                      subtitle: '${currentUser!.email}',
                      leading: Icon(Icons.account_circle, semanticLabel: "User info",),
                      onPressed: (BuildContext context) {},
                    ),
                  ],
                ),
              ],
            ))
        )));
  }
}

Future<void> _listapps22(BuildContext context) async {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        child: Container(
          height: 60,
          child: ListTile(
              leading: CircularProgressIndicator(),
              title: Text("Loading"),
          ),
        ),
      );
    },
  );

  // Returns a list of only those apps that have launch intent
  List _apps = await DeviceApps.getInstalledApplications(
      onlyAppsWithLaunchIntent: true,
      includeAppIcons: true,
      includeSystemApps: true);
  _apps.sort(
      (a, b) => (a.appName.toLowerCase()).compareTo(b.appName.toLowerCase()));
  Navigator.pop(context);
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (BuildContext context) {
        final tiles = <Widget>[];
        for (var a in _apps) {
          tiles.add(ListTile(
            leading: Image.memory(a.icon),
            title: Text(a.appName),
            onTap: () {
              DeviceApps.openApp(a.packageName);
            },
            trailing: Wrap(
              spacing: 12, // space between two icons
              children: <Widget>[
                IconButton(
                    onPressed: () {
                      DeviceApps.openappNotifications(a.packageName);
                    },
                    icon: Icon(Icons.circle_notifications_rounded)),
                IconButton(
                    onPressed: () {
                      testingNotifications(a.packageName);
                    },
                    icon: Icon(Icons.data_usage)),
                IconButton(
                    onPressed: () {
                      testingBattery(a.packageName);
                    },
                    icon: Icon(Icons.battery_alert)),
                IconButton(
                    onPressed: () {
                      testingPermissions(a.packageName, context);
                    },
                    icon: Icon(Icons.developer_mode)),
              ],
            ),
          ));
        }
        final divided = ListTile.divideTiles(
          context: context,
          tiles: tiles,
        ).toList();

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(Icons.close)),
            title: Text('Installed applications'),
          ),
          body: Scrollbar(child: ListView(children: divided)),
          floatingActionButton: FloatingActionButton.extended(
              onPressed: () => SystemSettings.system(),
              label: Text('Device settings')),
        );
      }, // ...to here.
    ),
  );
}

Future<void> testingBattery(packageName) async {
  bool isBatteryOptimizationDisabled =
      await DeviceApps.isIgnoringBatteryOptimizations(packageName);
  Fluttertoast.showToast(
    msg:
        "Optimization is ${isBatteryOptimizationDisabled ? "Disabled" : "Enabled"}",
  );
  if (!isBatteryOptimizationDisabled) {
    DeviceApps.ignoreBatteryOptimizations(packageName);
  }
}

Future<void> testingNotifications(packageName) async {
  DeviceApps.ignoreBackgroundDataRestrictions(packageName);
}

Future<void> testingPermissions(packageName, BuildContext context) async {
  String? d = await DeviceApps.checkPermissions(packageName);
  print(d);
  List<String> permissionsSplited = d!.split(RegExp(
      'android.permission.|com.google.android.providers.gsf.permission.|com.android.systemui.permission.'));
  print(permissionsSplited);
  showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
            title: Text((packageName.split('.')).last),
            content: Container(
              height: 300.0,
              width: 300.0,
              child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: permissionsSplited.length,
                  itemBuilder: (context, index) {
                    return Text(permissionsSplited[index]);
                  }),
            ),
      )
  );
}
