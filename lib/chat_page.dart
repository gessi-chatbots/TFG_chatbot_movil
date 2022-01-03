import 'dart:convert';
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:device_apps/device_apps.dart';
import 'dart:developer';
import 'dart:io' show Platform, SocketException;
import 'dart:async';
import 'package:http/http.dart' as http;
import 'login.dart';
import 'package:shared_preferences/shared_preferences.dart';

const rasaIP = 'http://3.143.242.230:5005';
const localIP = 'http://10.0.2.2:5005';
Timer? ping;
List<String> pendentMessages = [];
List<ChatBubble> messages = [];
bool soundOn = false;

class ChatPage extends StatefulWidget {
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  final TextEditingController _controller = TextEditingController();
  var status = 'undefined';
  bool isLoading = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Column(children: [
      Expanded(child: ListView(
          key: ValueKey(messages.length),
          children: messages)),
      Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30.0),
            color: Colors.blue
        ),
        margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(15),
                child: TextField(
                  style: TextStyle(color: Colors.white),
                  controller: _controller,
                  cursorColor: Colors.black,
                  decoration: const InputDecoration(
                      hintText: "Message",
                      labelStyle: TextStyle(color: Colors.black26)
                  ),
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(shape: StadiumBorder()),
              onPressed: () async{
                dynamic text = _controller.text;
                _controller.clear();
                FocusScope.of(context).requestFocus(FocusNode());
                setState(() {
                  isLoading = true;
                });
                await submitMessage(text);
                setState(() {
                  isLoading = false;
                  messages;
                });
              },
              child: (isLoading)
                ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 1.5,
                  ))
                  : Icon(Icons.send),
            ),
          ],
        ),
        )
    ]));
  }

  @override
  void initState() {
    super.initState();
    const seconds = Duration(seconds: 30);
    if(messages.isEmpty) welcomeMessage();
    WidgetsBinding.instance!.addPostFrameCallback((_) =>
        // _fetchData() is your function to fetch data
        ping = Timer.periodic(seconds, (Timer t) => checkStatus()));
  }

  @override
  void dispose() {
    super.dispose();
    ping!.cancel();
  }

  Future<void> submitMessage(String text) async {
    if (text.isEmpty) log("Empty text");
    else {
      ChatBubble message = ChatBubble(text: text, isCurrentUser: true);
      setState(() {
        messages.add(message);
      });
      await sendtoRasa(text, false, message.getKey());
    }
  }

  Future<String> sendtoRasa (String text, bool retry, dynamic questionKey) async {
    try {
    dynamic response = await http.post(
        Uri.parse(localIP + '/webhooks/rest/webhook'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "sender": currentUser!.email,
          "message": text
        })).timeout(
        const Duration(seconds: 10)
        );
    log('Request with statusCode : ${response.statusCode} and body: ${response.body}');

    if (response.statusCode == 200 && response.body != '[]') {
      List<dynamic> jsonresponse = json.decode(response.body);
      final responseBody = BotResponse.fromJson(jsonresponse[0]);

      if(retry) {
        ChatBubble message = ChatBubble(text: text, isCurrentUser: true);
        setState(() {
          messages.add(message);
        });
      }
      // If the server did return a 200 OK response,
      // then parse the JSON.
        if (responseBody.message is String) {
          ChatBubble message = ChatBubble(
              text: responseBody.message, isCurrentUser: false);
          messages.add(message);
        }
        else {
          final customAction = Map<String, dynamic>.from(responseBody.message);
          ChatBubble message = ChatBubble(
              text: customAction['text'], isCurrentUser: false);
          messages.add(message);
          if (customAction['flutteraction'] != "undefined") {
            actionhandler(customAction['flutteraction']);
          }
        }
      /*setState(() {
        messages;
      });*/
      return "success";
    }
    else {
      ChatBubble message = ChatBubble(
          text: 'Sorry I could not understand you', isCurrentUser: false);
      messages.add(message);
    }} catch (e) {
      messages.removeWhere((element) => element.getKey()==questionKey);
      /*setState(() {

      });*/
      if(!retry) {
         //MIRAR QUE BORRE EL QUE TOCA
        showDialog(context: context, builder: (BuildContext context) =>
        const AlertDialog(
            title: Text('Attention'),
            content: Text(
                "Timeout exceeded we will send your message when your device has connectivity")
        ));
        pendentMessages.add(text);
        print('Content: $pendentMessages');
        setState(() {
          isLoading = false;
          messages;
        });
        throw Exception('Failed to send a message $e');
      }
    }
    return "error";
  }

  void actionhandler(String action) async {
    final appName = action.split("_")[2];
    final action_type = action.split("_")[1];
    log('Entered in runAction');
    List<Application> _apps = await DeviceApps.getInstalledApplications(onlyAppsWithLaunchIntent: true, includeSystemApps: true) as List<Application>;
    switch (action_type) {
      case 'notification': {
        for (var app in _apps) {
          if(app.appName.contains(appName)) {
            showDialog(context: context, builder: (BuildContext context) => _buildPopupDialogNotification(context,action,app.packageName));
            break;
          }
        }
        break;
      }
      case 'datausage': {
        for (var app in _apps) {
          if(app.appName.contains(appName)) {
            showDialog(context: context, builder: (BuildContext context) => _buildPopupDialogDataUsage(context,action,app.packageName));
            break;
          }
        }
        break;
      }
      case 'batteryopt': {
        for (var app in _apps) {
          if(app.appName.contains(appName)) {
            showDialog(context: context, builder: (BuildContext context) => FutureBuilder(
                future: _buildPopupDialogBatteryOptimization(context,action,app.packageName),
                builder: (BuildContext context, AsyncSnapshot snapshot) {
                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }
                  return snapshot.data;
                }));
          }
        }
        break;
      }
      default : {
        throw(UnimplementedError);
      }

    }

  }

  Future<String> checkStatus() async {
    print("Entrando en checkStatus");
    if(pendentMessages.isNotEmpty) {
      String result = await sendtoRasa(pendentMessages.first, true, "null");
      if(result=="success") pendentMessages.removeAt(0);
    }
    /*
    try {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: const Text('Loading...'),
              duration: const Duration(seconds: 15)
          )
      );

      dynamic response = await http.get(
          Uri.parse(localIP + '/status')).timeout(
          Duration(seconds: 5));
      setState(() {
        isLoading = false;
      });
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: const Text('Connected...'),
                duration: const Duration(seconds: 2)
            )
        );
        return "connected: ";
      }
      else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: const Text('Disconnected...'),
                duration: const Duration(seconds: 2)
            )
        );
        return "disconnected";
      }
    }
    on TimeoutException catch (e) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: const Text('Could not connect to server...'),
              duration: const Duration(seconds: 2)
          )
      );
    }
      return "disconnected"; */
    return "";
  }

  void welcomeMessage() {
    String? name = currentUser!.displayName!.split(" ")[0];
    ChatBubble m = ChatBubble(text: "Hi $name, how can I help you?", isCurrentUser: false);
    setState(() {
      messages.add(m);
    });
  }
}

Widget _buildPopupDialogNotification(BuildContext context, String action, String app) {
  final actionType = action.split("_")[0];
  return AlertDialog(
    title: Text('Attention'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('To ${actionType} the APP notifications please press the following button'),
      ],
    ),
    actions: <Widget>[
      TextButton(
        onPressed: () {
          Navigator.of(context).pop();
          DeviceApps.openappNotifications(app);
        },
        child: const Text('Go to the APP'),
      ),
      TextButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: const Text('Close'),
      ),
    ],
  );
}

Widget _buildPopupDialogDataUsage(BuildContext context, String action, String app) {
  return AlertDialog(
    title: Text('Attention'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('To control the APP data usage please press the following button'),
      ],
    ),
    actions: <Widget>[
      TextButton(
        onPressed: () {
          DeviceApps.ignoreBackgroundDataRestrictions(app);
        },
        child: const Text('Go to the APP'),
      ),
      TextButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: const Text('Close'),
      ),
    ],
  );
}

Future<Widget> _buildPopupDialogBatteryOptimization(BuildContext context, String action, String app) async {
  bool isBatteryOptimizationDisabled = await DeviceApps.isIgnoringBatteryOptimizations(app);
  return AlertDialog(
    title: Text('Attention'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Battery optimization is currently ${isBatteryOptimizationDisabled ? "disabled" : "enabled"} for ${action.split("_")[2]}'),
      ],
    ),
    actions: <Widget>[
      TextButton(
        onPressed: () {
          DeviceApps.ignoreBatteryOptimizations(app);
        },
        child: const Text('Go to the APP'),
      ),
      TextButton(
        onPressed: () {
          Navigator.of(context).pop();
        },
        child: const Text('Close'),
      ),
    ],
  );
}
class BotResponse {
  final id;
  String recipient_id;
  dynamic message;

  BotResponse({
    required this.recipient_id, required this.message,
  }) : id = UniqueKey();

  factory BotResponse.fromJson(Map<String, dynamic> json) {
    return BotResponse(
      recipient_id: json['recipient_id'],
      message: json['text'] ?? json["custom"],
    );
  }
}

class ChatBubble extends StatelessWidget {
  ChatBubble({
    final key,
    required this.text,
    required this.isCurrentUser,
  }) : key = UniqueKey();
  final String text;
  final bool isCurrentUser;
  final key;


  @override
  Widget build(BuildContext context) {
    return Padding(
      // add some padding
      padding: EdgeInsets.fromLTRB(
        isCurrentUser ? 64.0 : 16.0,
        4,
        isCurrentUser ? 16.0 : 64.0,
        4,
      ),
      child: Align(
        // align the child within the container
        alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
        child: DecoratedBox(
          // chat bubble decoration
          decoration: BoxDecoration(
            color: isCurrentUser ? Colors.blue : Colors.orange,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
              children: <Widget>[Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.bodyText1!.copyWith(
                      color: Colors.white),
                ),
              ),
          ],
          ),
        ),
      ),
    );
  }

  dynamic getKey() {
    return key;
  }
}