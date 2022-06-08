import 'package:bubble/bubble.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:developer';

/// https://github.com/neon97/chatbot_dialogflow

void main() {
  runApp(MaterialApp(
    home: MyApp(),
    debugShowCheckedModeBanner: false,
  ));
}

const rasaIP = '0.0.0.0:5005';
const localIP = '0.0.0.0';
const IP = localIP;

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  final messageInsert = TextEditingController();
  List<Map> messsages = [];

  Future<String> sendToRasa (String text) async {
    log("started sent to rasa");
    try {
      dynamic response = await http.post(
          Uri.parse('http://' + IP + ':5005' + '/webhooks/rest/webhook'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "sender": "me",
            "message": text
          })).timeout(
          const Duration(seconds: 10)
      );
      log('Request with statusCode : ${response.statusCode} and body: ${response.body}');
    } on TimeoutException catch (e) {}
    return "error";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "CupcakeShop Bot",
        ),
        backgroundColor: Colors.deepOrange,
      ),
      body: Container(
        child: Column(
          children: <Widget>[
            Flexible(
                child: ListView.builder(
                    reverse: true,
                    itemCount: messsages.length,
                    itemBuilder: (context, index) => chat(
                        messsages[index]["message"].toString(),
                        messsages[index]["data"]))),
            Divider(
              height: 5.0,
              color: Colors.deepOrange,
            ),
            Container(
              padding: EdgeInsets.only(left: 15.0, right: 15.0),
              margin: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: <Widget>[
                  Flexible(
                      child: TextField(
                    controller: messageInsert,
                    decoration: InputDecoration.collapsed(
                        hintText: "Send your message",
                        hintStyle: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18.0)),
                  )),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 4.0),
                    child: IconButton(
                      
                        icon: Icon(
                          
                          Icons.send,
                          size: 30.0,
                          color: Colors.deepOrange,
                        ),
                        onPressed: () {
                          if (messageInsert.text.isEmpty) {
                            print("empty message");
                          } else {
                            setState(() {
                              messsages.insert(0,
                                  {"data": 1, "message": messageInsert.text});
                            });
                            sendToRasa(messageInsert.text);
                            //response(messageInsert.text);
                            messageInsert.clear();
                          }
                        }),
                  )
                ],
              ),
            ),
            SizedBox(
              height: 15.0,
            )
          ],
        ),
      ),
    );
  }

  //for better one i have use the bubble package check out the pubspec.yaml

  Widget chat(String message, int data) {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Bubble(
          radius: Radius.circular(15.0),
          color: data == 0 ? Colors.deepOrange : Colors.orangeAccent,
          elevation: 0.0,
          alignment: data == 0 ? Alignment.topLeft : Alignment.topRight,
          nip: data == 0 ? BubbleNip.leftBottom : BubbleNip.rightTop,
          child: Padding(
            padding: EdgeInsets.all(2.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                CircleAvatar(
                  backgroundImage: AssetImage(
                      data == 0 ? "assets/bot.png" : "assets/user.png"),
                ),
                SizedBox(
                  width: 10.0,
                ),
                Flexible(
                    child: Text(
                  message,
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ))
              ],
            ),
          )),
    );
  }
}
  /*
    if (response.statusCode == 200 && response.body != '[]') {
      List<dynamic> jsonresponse = json.decode(response.body);
      final responseBody = BotResponse.fromJson(jsonresponse[0]);

      if(retry) {
        ChatBubble message = ChatBubble(text: text, isCurrentUser: true);
        messages.add(message);
      }
      // If the server did return a 200 OK response,
      // then parse the JSON.
      if (responseBody.message is String) {
        ChatBubble message = ChatBubble(
            text: responseBody.message, isCurrentUser: false);
        messages.add(message);
        if(soundOn) tts.speak(responseBody.message);
      }
      else {
        final customAction = Map<String, dynamic>.from(responseBody.message);
        ChatBubble message = ChatBubble(
            text: customAction['text'], isCurrentUser: false);
        messages.add(message);
        if (customAction['flutteraction'] != "undefined") {
          actionhandler(customAction['flutteraction'],context);
        }
        if(soundOn) tts.speak(customAction['text']);
      }
      return "success";
    }
    else {
      ChatBubble message = ChatBubble(
          text: 'Sorry I could not understand you', isCurrentUser: false);
      messages.add(message);
    }} on TimeoutException catch (e) {
    print(e);
    messages.removeWhere((element) => element.getKey()==questionKey);
    return "timeout";
  }*/