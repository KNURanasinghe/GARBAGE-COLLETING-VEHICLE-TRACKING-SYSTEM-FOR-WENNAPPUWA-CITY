import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:garbage_collecting_system/screens/homepage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/login.dart';
import 'screens/signUp.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //user keep login for 1h
  SharedPreferences pref = await SharedPreferences.getInstance();

  // Initialize Awesome Notifications
  AwesomeNotifications().initialize(
    // Set the 'app_icon' to the name of your app's launcher icon
    'resource://drawable/app_icon',
    [
      NotificationChannel(
        channelKey: 'basic_channel',
        channelName: 'Basic notifications',
        channelDescription: 'Notification channel for basic notifications',
        defaultColor: Colors.blue,
        ledColor: Colors.white,
      ),
    ],
  );
  runApp(MyApp(
    token: pref.getString('token'),
  ));
}

class MyApp extends StatelessWidget {
  // ignore: prefer_typing_uninitialized_variables
  final token;
  const MyApp({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Garbage collecting System',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: token == null
          ? const SignUpPage()
          : (JwtDecoder.isExpired(token) == false)
              ? HomeScreen(token: token)
              : const LoginPage(),
    );
  }
}
