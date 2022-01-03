import 'package:flutter/material.dart';
import 'package:system_settings/system_settings.dart';
import 'dart:developer';
import 'package:device_apps/device_apps.dart';
import 'dart:io' show Platform;
import 'package:open_settings/open_settings.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:tfg_chatbot_movil/chat_page.dart';


class SettingsPage extends StatefulWidget {
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings️'),
      ),
      body: Container(
          padding: const EdgeInsets.all(15),
          child: IntrinsicWidth(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ElevatedButton(
                    child: const Text('Installed Apps'),
                    onPressed: () => _listapps22(context),
                  ),
                ElevatedButton(
                  child: const Text('Clear Messages'),
                  onPressed: () => messages.clear(),
                ),
                ElevatedButton(
                  child: const Text('Pendent Messages'),
                  onPressed: () => {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return Dialog(
                          child: pendentMessages.isEmpty ? Center(child: Text('No Pendent Messages')) : ListView.builder(
                            itemCount: pendentMessages.length,
                            itemBuilder: (context, index) => Container(
                              child: Text(
                              pendentMessages[index],//Reference an index & key here. This is why index is provided as a parameter in this callback
                              ),
                        )));
                      },
                    )
                  },
                ),
                ElevatedButton(
                  child: const Text('Help'),
                  onPressed: () =>throw(UnimplementedError),
                ),
                Row(
                    children: [
                      Text("Sound"), Switch(
                      value: soundOn,
                      onChanged: (value) {
                        setState(() {
                          soundOn = value;
                          print(soundOn);
                        });
                      },
                      activeTrackColor: Colors.lightGreenAccent,
                      activeColor: Colors.green,
                    )
                  ]
                ),
              ]
          ))
        ),
      );
  }

}

Future<void> _listapps22(BuildContext context) async {

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        child: IntrinsicHeight(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              CircularProgressIndicator(),
              Text("Loading"),
            ],
          ),
        ),
      );
    },
  );

  // Returns a list of only those apps that have launch intent
  List _apps = await DeviceApps.getInstalledApplications(onlyAppsWithLaunchIntent: true, includeAppIcons: true, includeSystemApps: true);
  log(_apps.toString());
  _apps.sort((a, b) => (a.appName.toLowerCase()).compareTo(b.appName.toLowerCase()));
  print(_apps.runtimeType);
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
                    IconButton(onPressed: () { DeviceApps.openappNotifications(a.packageName);}, icon: Icon(Icons.circle_notifications_rounded) ),
                    IconButton(onPressed: () { testingNotifications(a.packageName);}, icon: Icon(Icons.data_usage) ),
                    IconButton(onPressed: () { testingBattery(a.packageName);}, icon: Icon(Icons.battery_alert) ),
                    IconButton(onPressed: () { testingPermissions(a.packageName, context);}, icon: Icon(Icons.developer_mode) ),
                  ],
              ),
          )
          );
        }
        final divided = ListTile.divideTiles(
          context: context,
          tiles: tiles,
        ).toList();

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(onPressed: () { Navigator.pop(context); }, icon: Icon(Icons.close) ),
            title: Text('Installed applications'),
          ),
          body: Scrollbar(
              child: ListView(children: divided)
          ),
          floatingActionButton: FloatingActionButton.extended(
              onPressed: () => SystemSettings.system(),
              label: Text('Device settings')
          ),
        );
      }, // ...to here.
    ),
  );
}

Future<void> testingBattery(packageName) async {
  bool isBatteryOptimizationDisabled = await DeviceApps.isIgnoringBatteryOptimizations(packageName);
  Fluttertoast.showToast(
  msg: "Optimization is ${isBatteryOptimizationDisabled ? "Disabled" : "Enabled"}",
  );
  if(!isBatteryOptimizationDisabled) DeviceApps.ignoreBatteryOptimizations(packageName);
}

Future<void> testingNotifications(packageName) async {
  DeviceApps.ignoreBackgroundDataRestrictions(packageName);
}

Future<void> testingPermissions(packageName, BuildContext context) async {
  String? d = await DeviceApps.checkPermissions(packageName);
  print(d);
  List<String> permissionsSplited = d!.split(RegExp('android.permission.|com.google.android.providers.gsf.permission.|com.android.systemui.permission.'));
  print(permissionsSplited);
  showDialog(context: context, builder: (BuildContext context) => AlertDialog(
      title: Text((packageName.split('.')).last),
      content: Container (
        height: 300.0, 
        width: 300.0,
        child: ListView.builder(
              shrinkWrap: true,
              itemCount: permissionsSplited.length,
              itemBuilder: (context, index) {
                return Text(permissionsSplited[index]);
            }),
      ),
  ));
}