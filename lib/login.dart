import 'dart:async';
import 'dart:convert' show json;

import "package:http/http.dart" as http;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:tfg_chatbot_movil/main.dart';
import 'package:postgres/postgres.dart';

GoogleSignIn googleSignIn = GoogleSignIn(
  // Optional clientId
  // clientId: '479882132969-9i9aqik3jfjd7qhci1nqf0bm2g71rm1u.apps.googleusercontent.com',
  scopes: <String>[
    'email',
    'https://www.googleapis.com/auth/contacts.readonly',
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
    var postgreBD = PostgreSQLConnection("10.0.2.2", 5432, "rasa", username: "project_admin", password: "root");
    try {
      await googleSignIn.signIn();
      await postgreBD.open();
      await postgreBD.query("INSERT INTO public.users (email,name) VALUES (@eValue,@nValue) ON CONFLICT (email) DO NOTHING", substitutionValues: {
        "eValue" : currentUser!.email,
        "nValue" : currentUser!.displayName!,
      }
      );

    } catch (error) {
      print(error);
    }
    await postgreBD.close();
  }

  Future<void> _handleSignOut() => googleSignIn.disconnect();

  Widget _loginPage() {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Rasa Chatbot'),
        ),
        body: DecoratedBox(
          decoration: const BoxDecoration(
          image: DecorationImage(image: AssetImage("images/background.jpg"), fit: BoxFit.fitHeight),
          ),
          child:ConstrainedBox(
            constraints: const BoxConstraints.expand(),
            child: _buildBody(),
        )));
  }

  Widget _buildBody() {
    GoogleSignInAccount? user = currentUser;
    if (user != null) {
      return MyHomePage();
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Text("Sign in to continue",
          style: TextStyle(
            fontSize: 42)),
          ElevatedButton(
            child: const Text('SIGN IN'),
            onPressed: _handleSignIn,
          ),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
        return _loginPage();
  }
}