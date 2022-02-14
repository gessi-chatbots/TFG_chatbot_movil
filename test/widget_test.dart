// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility that Flutter provides. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

import 'package:tfg_chatbot_movil/chat_page.dart';
import 'package:tfg_chatbot_movil/login.dart';
import 'test_http_requests.dart';

class _MyHttpOverrides extends HttpOverrides {}

void main() {

  Widget createWidgetForTesting({required Widget child}){
    return MaterialApp(
      home: child,
    );
  }

  testWidgets('Check if message disappears', (WidgetTester tester) async {
    // Create the widget by telling the tester to build it.

    await tester.pumpWidget(createWidgetForTesting(child: ChatPage()));

    await tester.enterText(find.byType(TextField), 'hello');

    await tester.tap(find.byTooltip('Send'));

    expect(find.text('hello'), findsNothing);
  });

  testWidgets('Check if help Message is shown', (WidgetTester tester) async {
    // Create the widget by telling the tester to build it.

    await tester.pumpWidget(createWidgetForTesting(child: ChatPage()));

    expect(find.textContaining("how can I help you?", skipOffstage: false), findsOneWidget);
  });

  testWidgets('Check if displays basic message', (WidgetTester tester) async {
    // Create the widget by telling the tester to build it.
    final dio = Dio(BaseOptions(
      connectTimeout: 30000,
      baseUrl: "10.0.2.2:5005",
      responseType: ResponseType.json,
      contentType: ContentType.json.toString(),
    ));

    final dioInterceptor = DioInterceptor(dio: dio);

    dio.interceptors.add(dioInterceptor);

    const path = '/webhooks/rest/webhook';

    dioInterceptor.onPost(path,
            (server) => server.reply(200, [{
              "recipient_id": "flutterchatbot.user@gmail.com",
              "text": "Hey! How are you?"
            }]));

    await tester.pumpWidget(createWidgetForTesting(child: ChatPage()));

    await tester.enterText(find.byType(TextField), 'hello');

    await tester.tap(find.byTooltip('Send'));

    expect(find.textContaining("Hey! How are you?", skipOffstage: false), findsOneWidget);
  });

  test('test simple BotResponse', () async {

    final responseBody = BotResponse.fromJson({
      "recipient_id": "flutterchatbot.user@gmail.com",
      "text": "Hey! How are you?"
    });

    expect("Hey! How are you?", responseBody.message);
  });

  test('test custom BotResponse', () async {
    // Create the widget by telling the tester to build it.

    final responseBody = BotResponse.fromJson({
      "recipient_id": "flutterchatbot.user@gmail.com",
      "custom": {
        "text": "restricting data usage for Facebook",
        "flutteraction": "restrict_datausage_Facebook"
      }
    });

    final customAction = Map<String, dynamic>.from(responseBody.message);

    expect("restricting data usage for Facebook", customAction['text']);
  });
}
