import 'dart:convert';
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:device_apps/device_apps.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:developer';
import 'dart:io' show Platform, SocketException;
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:postgres/postgres.dart';
import 'login.dart';
import 'package:flutter_tts/flutter_tts.dart';

Timer? ping;
List<String> pendentMessages = [];
List<ChatBubble> messages = [];
bool soundOn = false;
final FlutterTts tts = FlutterTts();

class ChatPage extends StatefulWidget {
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  bool isLoading = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();

  setTTs() {
    tts.setLanguage('en');
    tts.setSpeechRate(0.3);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
        child: Scaffold(
      key: _scaffoldKey,
      body: Column(children: [
      Expanded(child: ListView(
          key: ValueKey(messages.length),
          children: messages,
          controller: _scrollController),
      ),
      Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30.0),
            color: Colors.blue,
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
                  decoration: InputDecoration(
                      hintText: "Type a message",
                      hintStyle: TextStyle(color: Colors.grey[300]),
                      labelStyle: TextStyle(color: Colors.white)
                  ),
                ),
              ),
            ),
            Tooltip(message: "Send",
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(shape: StadiumBorder()),
                onPressed: () async{
                  dynamic text = _controller.text;
                  if (text.isEmpty || isLoading) {
                  log("Empty text");
                  } else {
                    _controller.clear();
                    FocusScope.of(context).requestFocus(FocusNode());
                    setState(() {
                      isLoading = true;
                    });
                    await submitMessage(text);
                    setState(() {
                      isLoading = false;
                      messages;
                      print({_scrollController.position});
                      print({_scrollController.positions});
                      _scrollController.animateTo(2078.6,
                          duration: const Duration(seconds: 2), curve: Curves.easeIn);
                    });
                  }
                },
                child: (isLoading)
                  ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 1.5,
                    ))
                    : const Icon(Icons.send),
              ),
            )
          ],
        ),
        )
    ])),
        label: 'Chat Page Screen',
        readOnly: false
    );
  }

  @override
  void initState() {
    super.initState();
    const seconds = Duration(seconds: 30);
    messages.clear();
    DeviceApps.listenToAppsChanges().listen((event) async {
      switch (event.event) {
        case ApplicationEventType.installed:
          log("app installed ${event.appName}");
          var postgreBD = PostgreSQLConnection(IP, 5432, "rasa", username: "project_admin", password: "root");
          try {
            await postgreBD.open();
            await postgreBD.query("UPDATE public.users SET app_names = array_append(app_names,(@aValue)) WHERE email = (@eValue)", substitutionValues: {
              "eValue" : currentUser!.email,
              "aValue" : event.appName,
            }
            );

          } catch (error) {
            print(error);
          }
          await postgreBD.close();
          break;
        case ApplicationEventType.updated:
          break;
        case ApplicationEventType.uninstalled:
          var postgreBD = PostgreSQLConnection(IP, 5432, "rasa", username: "project_admin", password: "root");
          try {
            List _apps = await DeviceApps.getInstalledApplications(onlyAppsWithLaunchIntent: true, includeAppIcons: true, includeSystemApps: true);
            _apps.sort((a, b) => (a.appName.toLowerCase()).compareTo(b.appName.toLowerCase()));
            final appList = _apps.map((h) => h.appName).toList();
            await postgreBD.open();
            await postgreBD.query("UPDATE public.users SET app_names = @aValue WHERE email = (@eValue)", substitutionValues: {
              "eValue" : currentUser!.email,
              "aValue" : appList,
            }
            );

          } catch (error) {
            print(error);
          }
          await postgreBD.close();
          break;
        case ApplicationEventType.enabled:
          break;
        case ApplicationEventType.disabled:
          break;
      };
    });

    print("Created the stream");
    if(messages.isEmpty) welcomeMessage();
    setState(() {
      messages;
    });
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
      ChatBubble message = ChatBubble(text: text, isCurrentUser: true);
      setState(() {
        messages.add(message);
      });
      String resultRequest = await sendtoRasa(text, false, message.getKey(), context);
      if(resultRequest == "success") {

      }
      else if (resultRequest == "timeout"){
          showDialog(context: context, builder: (BuildContext context) =>
          const AlertDialog(
              title: Text('Attention'),
              content: Text(
                  "Timeout exceeded we will send your message when your device has connectivity")
          ));
          pendentMessages.add(text);
          print('Content: $pendentMessages');
          messages;
      }
      setState(() {
        messages;
        isLoading;
      });
  }

  Future<String> checkStatus() async {
    print("Entrando en checkStatus");
    if(pendentMessages.isNotEmpty) {
      String result = await sendtoRasa(pendentMessages.first, true, "null", context);
      if(result=="success") pendentMessages.removeAt(0);
    }
    return "";
  }


  void welcomeMessage() async{
    String? name = currentUser?.displayName?.split(" ")[0];
    ElevatedButton helpButton = ElevatedButton(onPressed: () { helpDialog(_scaffoldKey.currentContext); }, child: Text("Help"),style: ButtonStyle(
        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
            RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
                side: BorderSide(color: Colors.lightBlueAccent)
            )
        )
    ));
    ChatBubble m = ChatBubble(text: "Hi $name, how can I help you?", isCurrentUser: false, butt: helpButton);
    messages.add(m);
    var postgreBD = PostgreSQLConnection(IP, 5432, "rasa", username: "project_admin", password: "root");
    /*try {
      await postgreBD.open();
      await postgreBD.query("INSERT INTO public.events (sender_id,type_name,timestamp, action_name,data) VALUES (@eValue,@tValue,@timeValue,@aValue,@dValue);", substitutionValues: {
        "eValue": currentUser!.email,
        "tValue": "app",
        "aValue": "welcome",
        "dValue": m.text,
        "timeValue": DateTime.now().millisecondsSinceEpoch,
      });

    } catch (error) {
      print(error);
    }*/
    await postgreBD.close();
    if(soundOn) tts.speak(m.text);
  }
}


Future<String> sendtoRasa (String text, bool retry, dynamic questionKey, context) async {
  try {
    dynamic response = await http.post(
        Uri.parse('http://' + IP + ':5005' + '/webhooks/rest/webhook'),
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
  }
  return "error";
}

void actionhandler(String action, context) async {
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
    case 'permissions': {
      for (var app in _apps) {
        if(app.appName.contains(appName)) {
          showDialog(context: context, builder: (BuildContext context) => FutureBuilder(
              future: _buildPopupDialogPermissions(context,action,app),
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
        child: const Text('Go to the config'),
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
        child: const Text('Go to the configuration'),
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

void helpDialog(context) {
  List<String> examplePhrases =[
    "I want to disable youtube notifications",
    'Disable gmail background data',
    "Control chrome battery usage",
    "Show me facebook permissions"
  ];
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Semantics(
          container: true,
          label: "Example of actions screen",
          child:AlertDialog(
          title: Text('Example of actions'),
          content: Container(
              width: double.minPositive,
              child: ListView.builder(
                  itemCount: examplePhrases.length,
                  shrinkWrap: true,
                  itemBuilder: (BuildContext context, int index) {
                    return Card(
                      child: InkWell(
                        onLongPress: () {
                          Clipboard.setData(ClipboardData(text:examplePhrases[index]));
                          Fluttertoast.showToast(msg:"Copied to clipboard!");
                          },
                        child: Text(examplePhrases[index],
                        semanticsLabel: "Example phrase $index",
                        style: Theme.of(context).textTheme.bodyText1!.copyWith(
                        color: Colors.green),
                        ),
                      ),
                    );
                  }
              )
          )
      ));
    },
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
        Text('Do you want to change it?')
      ],
    ),
    actions: <Widget>[
      TextButton(
        onPressed: () {
          DeviceApps.openAppSettings(app);
        },
        child: const Text('Go to advanced configuration'),
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

Future<Widget> _buildPopupDialogPermissions(BuildContext context, String action, Application package) async {
  String app = package.packageName;
  String? d = await DeviceApps.checkPermissions(app);
  List<String> permissionsSplited = d!.split(RegExp(
      'android.permission.|com.google.android.providers.gsf.permission.|com.android.systemui.permission.|com.google.android.finsky.permission.'));
  return AlertDialog(
    title: Text(package.appName),
    content: Container(
      height: 300.0,
      width: 300.0,
      child: ListView.builder(
          shrinkWrap: true,
          itemCount: permissionsSplited.length,
          itemBuilder: (context, index) {
            return Text(permissionsSplited[index].split('_').join(" "));
          }),
    ),
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
    required this.isCurrentUser, this.butt,
  }) : key = UniqueKey();
  final String text;
  final bool isCurrentUser;
  final key;
  final ElevatedButton? butt;


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
                if (butt != null) Container(child: butt),
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