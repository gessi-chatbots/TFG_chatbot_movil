import 'package:flutter/material.dart';
import 'package:system_settings/system_settings.dart';
import 'dart:developer';
import 'package:device_apps/device_apps.dart';
import 'dart:io' show Platform;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Startup Name Generator',
      theme: ThemeData(
        primaryColor: Colors.orange[200],
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Startup Name Generator'),
      ),
      body: Center(
        child: TextButton(
          child: Text('Show installed apps'),
          onPressed: () => _listapps22()
        )
      )
    );
  }
/*
  Future<void> _listapps() async {
    // Returns a list of only those apps that have launch intent
    List<Application> apps = await DeviceApps.getInstalledApplications(onlyAppsWithLaunchIntent: true, includeAppIcons: true, includeSystemApps: true);
    //log('apps: $apps');
    var map1 = {};
    apps.forEach((Application) => map1[Application.packageName]);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          final tiles = apps.map(
                (Application a) {
              return ListTile(
                leading: Image.memory(a is ApplicationWithIcon ? a.icon : null),
                title: Text(
                  a.appName
                ),
                onTap: () {
                  DeviceApps.openappNotifications(a.packageName);
                },
              );
            },
          );
          final divided = ListTile.divideTiles(
            context: context,
            tiles: tiles,
          ).toList();

          return Scaffold(
            appBar: AppBar(
              title: Text('Installed applications'),
            ),
            body: Scrollbar(
                child: ListView(children: divided)
            ),
            floatingActionButton: FloatingActionButton.extended(
                onPressed: () => DeviceApps.openAppSettings('com.google.android.youtube'),
                label: Text('Device settings')
            ),
          );
        }, // ...to here.
      ),
    );
  }*/

  Future<void> _listapps22() async {
    // Returns a list of only those apps that have launch intent
    List _apps = await DeviceApps.getInstalledApplications(onlyAppsWithLaunchIntent: true, includeAppIcons: true, includeSystemApps: true);
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
                trailing: IconButton(onPressed: () { DeviceApps.openappNotifications(a.packageName);}, icon: Icon(Icons.circle_notifications_rounded) )
              )
              );
            }
          final divided = ListTile.divideTiles(
            context: context,
            tiles: tiles,
          ).toList();

          return Scaffold(
            appBar: AppBar(
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
}
