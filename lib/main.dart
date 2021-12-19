import 'package:flutter/material.dart';
import 'package:system_settings/system_settings.dart';
import 'dart:developer';
import 'package:device_apps/device_apps.dart';
import 'dart:io' show Platform;
import 'package:tfg_chatbot_movil/chat_page.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'login.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mobile Chatbot',
      theme: ThemeData(
        primaryColor: Colors.orange[200],
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: const TextTheme(
            bodyText1: TextStyle(fontSize: 20.0)
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: SignInDemo(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  var status = 'disconnected';
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Status: $status'),
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: IconButton(onPressed: () => _listapps22(), icon: Icon(Icons.settings), )
          ),
          IconButton(onPressed: () {_handleSignOut(); }, icon: Icon(Icons.logout))
        ],
      ),
      body: ChatPage(),
    );
  }

  Future<void> _handleSignOut() async {
    googleSignIn.disconnect().whenComplete(() {
      SignInDemo();
      print("SignOut Done");
    }).catchError((error) {
      print("error in signout $error");
    });
  }

  Future<void> _listapps22() async {
    // Returns a list of only those apps that have launch intent
    List _apps = await DeviceApps.getInstalledApplications(onlyAppsWithLaunchIntent: true, includeAppIcons: true, includeSystemApps: true);
    log(_apps.toString());
    print(_apps.runtimeType);
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

  void changeState() {
    setState(() {
      status = 'working';
    });
  }
}