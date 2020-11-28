
import 'dart:async';

import 'package:flutter/services.dart';

class AlarmNotification {
  static const MethodChannel _channel =
      const MethodChannel('alarm_notification');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<int> play() async {
    return await _channel.invokeMethod('play');
  }

  static Future<int> stop() async {
    return await _channel.invokeMethod('stop');
  }

  static Future<int> init() async {
    return await _channel.invokeMethod('init');
  }

  static Future<int> show() async {
    return await _channel.invokeMethod('show');
  }
}
