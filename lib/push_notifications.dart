import 'dart:isolate';
import 'dart:ui';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:alarm_notification/alarm_notification.dart';
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

  Future<void> init() async {
    if (!_initialized) {
      await AlarmNotification.init();

      // For iOS request permission first.
      _firebaseMessaging.requestNotificationPermissions();
      _firebaseMessaging.configure(
          onMessage: (Map<String, dynamic> message) async {
            showNotificationWithSound("onMessage");
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


  Future showNotificationWithSound(String message) async {
    AlarmNotification.play();
    AlarmNotification.show();
  }
}

Future<dynamic> myBackgroundMessageHandler(Map<String, dynamic> message) async {
  print("Back");
  AlarmNotification.play();
  AlarmNotification.show();
  waitAndStop();
  return Future<void>.value();
}

Future<void> waitAndStop() async {
  var rp = ReceivePort();
  IsolateNameServer.registerPortWithName(rp.sendPort, "hsp");
  rp.listen((message) {
    AlarmNotification.stop();
  });
}
