import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tfg_chatbot_movil/chat_page.dart';
import 'package:tfg_chatbot_movil/settings.dart';
import 'login.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
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
    return Semantics(
        label: "Mobile Chatbot",
        child: MaterialApp(
          title: 'Mobile Chatbot',
          theme: ThemeData(
            primaryColor: Colors.orange[200],
            visualDensity: VisualDensity.adaptivePlatformDensity,
            textTheme: const TextTheme(
                bodyText1: TextStyle(fontSize: 20.0)
            ),
          ),
          debugShowCheckedModeBanner: false,
            initialRoute: '/',
            routes: {
              '/settings': (context) => SettingsPage(),
            },
          home: Semantics (
            child:SignInDemo(),
            label:"Sign In Screen")
    ),
    container: true);
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
        title: Text('Rasa Chatbot'),
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: IconButton(onPressed: () {
              Navigator.pushNamed(context, '/settings');
            }, icon: Icon(Icons.settings), tooltip: "Settings",)
          ),
          IconButton(onPressed: () {_handleSignOut(); }, icon: Icon(Icons.logout), tooltip: "SignOut",)
        ],
      ),
      body: Semantics(
        child: ChatPage(),
        label: "Chat Page Screen",)
    );
  }

  void _handleSignOut() {
    print("HandleSignOut $pendentMessages");
    if (pendentMessages.isNotEmpty) {
      showDialog(
          context: context,
          builder: (context) {
        return AlertDialog(
            title: Text('Attention'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const <Widget>[
                Text('By signing out all your pendent messages will be deleted'),
              ],
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  pendentMessages.clear();
                  Navigator.of(context).pop();
                  googleSignIn.signOut().whenComplete(() {
                    SignInDemo();
                    print("SignOut Done");
                  }).catchError((error) {
                    print("error in signout $error");
                  });
                },
                child: const Text('SignOut'),
              ),
              TextButton(
                onPressed: () {
                  print(pendentMessages);
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
            ]);
        });
    }
    else {
      googleSignIn.signOut().whenComplete(() {
        SignInDemo();
        print("SignOut Done");
      }).catchError((error) {
        print("error in signout $error");
      });
    }
  }
}