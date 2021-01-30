import 'dart:isolate';
import 'dart:ui';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:alarm_notification/alarm_notification.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';

class PushNotificationsManager {
  PushNotificationsManager._();

  static String token;

  factory PushNotificationsManager() => _instance;

  static final PushNotificationsManager _instance =
      PushNotificationsManager._();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  bool _initialized = false;

  static Map<String, String> channelMap = {
    "id": "ALARM",
    "name": "Alarm",
    "description": "Alarm notification",
  };

  static Map<String, String> channelRingMap = {
    "id": "RING",
    "name": "Ringtone",
    "description": "Ringtone notification",
  };
  static FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  Future<void> init() async {
    if (!_initialized) {
      await AlarmNotification.init();
      flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('app_icon');
      final InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
      );
      await flutterLocalNotificationsPlugin.initialize(initializationSettings,
          onSelectNotification: selectNotification);

      // For iOS request permission first.
      _firebaseMessaging.requestNotificationPermissions();
      _firebaseMessaging.configure(
          onMessage: (Map<String, dynamic> message) async {
            if (message['data'].toString().contains("battery")) {
              showRingtoneNotification();
            } else {
              showAlarmNotification();
            }
            print("onMessage: $message");
          },
          onBackgroundMessage: myBackgroundMessageHandler,
          onLaunch: (Map<String, dynamic> message) async {
            //showNotificationWithSound("onLaunch");
            print("onLaunch: $message");
          },
          onResume: (Map<String, dynamic> message) async {
            //showNotificationWithSound("onResume");
            print("onResume: $message");
          });

      // For testing purposes print the Firebase Messaging token
      token = await _firebaseMessaging.getToken();
      print("FirebaseMessaging token: $token");
      _initialized = true;
    }
  }

  Future showAlarmNotification() async {
    AlarmNotification.play();
    AlarmNotification.show();
  }

  Future showRingtoneNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails('RING', 'Ringtone', 'Ringtone notification',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: false);
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      'CORRENTE ASSENTE!',
      'Rilevata assenza di corrente presso la centralina.',
      platformChannelSpecifics,
    );
  }
}

Future selectNotification(String payload) async {}

Future<dynamic> myBackgroundMessageHandler(Map<String, dynamic> message) async {
  print("Back");
  if (message['data'].toString().contains('battery')) {
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: selectNotification);

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails('RING', 'Ringtone', 'Ringtone notification',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: false);
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0,
      'CORRENTE ASSENTE!',
      'Rilevata assenza di corrente presso la centralina.',
      platformChannelSpecifics,
    );
  } else {
    AlarmNotification.play();
    AlarmNotification.show();
    waitAndStop();
  }
  return Future<void>.value();
}

Future<void> waitAndStop() async {
  var rp = ReceivePort();
  IsolateNameServer.registerPortWithName(rp.sendPort, "hsp");
  rp.listen((message) {
    AlarmNotification.stop();
  });
}
