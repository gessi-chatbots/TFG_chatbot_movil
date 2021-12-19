import 'dart:convert';
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:device_apps/device_apps.dart';
import 'dart:developer';
import 'dart:io' show Platform, SocketException;
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
const rasaIP = 'http://3.143.242.230:5005';
const localIP = 'http://10.0.2.2:5005';

class ChatPage extends StatefulWidget {
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  List<ChatBubble> messages = [];
  var status = 'undefined';
  bool isLoading = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Column(children: [
      Expanded(child: ListView(children: messages)),
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
                  log('primer setState ${isLoading}');
                });
                await submitMessage(text);
                setState(() {
                  isLoading = false;
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

  void initState() {
    super.initState();
    const seconds = const Duration(seconds: 60);
    WidgetsBinding.instance!.addPostFrameCallback((_) =>
        // _fetchData() is your function to fetch data
        Timer.periodic(seconds, (Timer t) => checkStatus()));
  }

  Future<void> submitMessage(String text) async {
    if (text.isEmpty) log("Empty text");
    else {
      ChatBubble message = ChatBubble(text: text, isCurrentUser: true);
      setState(() {
        messages.add(message);
      });
      await sendtoRasa(text);
    }
  }

  Future<String> sendtoRasa (String text) async {
    try {
    dynamic response = await http.post(
        Uri.parse(localIP + '/webhooks/rest/webhook'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "sender": "test_user",
          "message": text
        })).timeout(
        Duration(seconds: 15)
        );
    log('Request with statusCode : ${response.statusCode} and body: ${response.body}');

    if (response.statusCode == 200 && response.body != '[]') {
    List<dynamic> jsonresponse = json.decode(response.body);
    final responseBody = BotResponse.fromJson(jsonresponse[0]);

      // If the server did return a 200 OK response,
      // then parse the JSON.
      setState(() {
        if (responseBody.message == '[]') {
          ChatBubble message = const ChatBubble(
              text: 'Sorry I could not understand you', isCurrentUser: false);
          messages.add(message);
        }
        else if (responseBody.message is String) {
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
            runAction(customAction['flutteraction']);
          }
        }
      });
    } } on TimeoutException catch (e) {
      showDialog(context: context, builder: (BuildContext context) => AlertDialog(
          title: Text('Attention'),
          content: Text("Timeout Exceed we will send your message when your device has connectivity")
      ));
      throw Exception('Failed to send a message');
    } on SocketException catch (e) {
      throw Exception('Socket Error: $e');
    } on Error catch (e) {
      throw Exception('General Error: $e');
    }
    return "Finished";
  }

  void runAction(String action) async {
    final appName = action.split("_")[2];
    log('Entered in runAction');
    List<Application> _apps = await DeviceApps.getInstalledApplications(onlyAppsWithLaunchIntent: true, includeSystemApps: true) as List<Application>;
    for (var app in _apps) {
      if(app.appName.contains(appName)) {
        showDialog(context: context, builder: (BuildContext context) => _buildPopupDialog(context,action,app.packageName));
        break;
      }
    }
  }

  Future<String> checkStatus() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: const Text('Loading...'),
              duration: const Duration(seconds: 15)
          )
      );
      dynamic response = await http.get(
          Uri.parse(localIP + '/status')).timeout(
          Duration(seconds: 15));
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
      return "disconnected";
  }
}

Widget _buildPopupDialog(BuildContext context, String action, String app) {
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

class BotResponse {
  String recipient_id;
  dynamic message;

  BotResponse({
    required this.recipient_id, required this.message
  });

  factory BotResponse.fromJson(Map<String, dynamic> json) {
    return BotResponse(
      recipient_id: json['recipient_id'],
      message: json['text'] ?? json["custom"],
    );
  }
}

class ChatBubble extends StatelessWidget {
  const ChatBubble({
    Key? key,
    required this.text,
    required this.isCurrentUser,
  }) : super(key: key);
  final String text;
  final bool isCurrentUser;

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
}