import 'dart:async';
import 'dart:convert' show json;

import 'package:device_apps/device_apps.dart';
import "package:http/http.dart" as http;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tfg_chatbot_movil/main.dart';
import 'package:postgres/postgres.dart';

const rasaIP = '18.218.43.195';
const localIP = '10.0.2.2';
const IP = localIP;

GoogleSignIn googleSignIn = GoogleSignIn(
  // Optional clientId
  // clientId: '479882132969-9i9aqik3jfjd7qhci1nqf0bm2g71rm1u.apps.googleusercontent.com',
  scopes: <String>[
    'email',
  ],
);

GoogleSignInAccount? currentUser;

class SignInDemo extends StatefulWidget {
  @override
  State createState() => SignInDemoState();
}

class SignInDemoState extends State<SignInDemo> {

  @override
  void initState() {
    super.initState();
    googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      setState(() {
        currentUser = account;
      });
    });
    googleSignIn.signInSilently();
  }


  Future<void> _handleSignIn() async {
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
    List _apps = await DeviceApps.getInstalledApplications(onlyAppsWithLaunchIntent: true, includeAppIcons: true, includeSystemApps: true);
    _apps.sort((a, b) => (a.appName.toLowerCase()).compareTo(b.appName.toLowerCase()));
    final appList = _apps.map((h) => h.appName).toList();

    var postgreBD = PostgreSQLConnection(IP, 5432, "rasa", username: "project_admin", password: "root");
    try {
      await googleSignIn.signIn();
      Navigator.pop(context);
      await postgreBD.open();
      await postgreBD.query("INSERT INTO public.users (email,name,app_names) VALUES (@eValue,@nValue,@aValue) ON CONFLICT (email) DO UPDATE SET app_names =  @aValue;", substitutionValues: {
        "eValue" : currentUser!.email,
        "nValue" : currentUser!.displayName!,
        "aValue" : appList,
      }
      );

    } catch (error) {
      print(error);
    }
    await postgreBD.close();
  }

  Future<void> _handleSignOut() => googleSignIn.disconnect();

  Widget _loginPage() {
    GoogleSignInAccount? user = currentUser;
    if (user != null) {
      return MyHomePage();
    } else {
      return Scaffold(
          appBar: AppBar(
            title: const Text('Rasa Chatbot'),
          ),
          body: DecoratedBox(
              decoration: const BoxDecoration(
                image: DecorationImage(
                    image: AssetImage("images/background.jpg"),
                    fit: BoxFit.fitHeight),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints.expand(),
                child: _buildBody(),
              )));
    }
  }

  Widget _buildBody() {
      return Semantics(
        label: "Sign In Page",
          child:Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text("Sign in to continue",
          style: TextStyle(
            fontSize: 42)),
          Tooltip(message: "Sign In Button", child: ElevatedButton(
            child: const Text('SIGN IN'),
            onPressed: _handleSignIn,
          )
          ),
        ],
      ));
  }

  @override
  Widget build(BuildContext context) {
        return _loginPage();
  }
}