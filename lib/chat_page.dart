import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:device_apps/device_apps.dart';
import 'dart:developer';
import 'dart:io' show Platform;
import 'dart:async';
import 'package:http/http.dart' as http;
const rasaIP = 'http://3.143.242.230:5005';
const localIP = 'http://10.0.2.2:5005';

class ChatPage extends StatefulWidget {
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  List<ChatBubble> messages = [];

  @override
  Widget build(BuildContext context) {
    return Column(children: [
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
            IconButton(
              color: Colors.white,
              icon: Icon(Icons.send),
              onPressed: () {
                sendMessage(_controller.text);
                _controller.clear();
              },
            ),
          ],
        ),
      )
    ]);
  }

  Future<void> sendMessage(String text) async {
    if (text.isEmpty) return;
    final response = await http.post(
        Uri.parse(rasaIP + '/webhooks/rest/webhook'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "sender": "test_user",
          "message": text
        }));
    log('Request with statusCode : ${response.statusCode} and body: ${response.body}');

    List<dynamic> jsonresponse = json.decode(response.body);
    final responseBody = BotResponse.fromJson(jsonresponse[0]);
    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      setState(() {
        ChatBubble message2 = ChatBubble(text: text, isCurrentUser: true);
        messages.add(message2);
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
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to to send a message');
    }

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
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyText1!.copyWith(
                  color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}