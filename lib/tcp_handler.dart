import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';

import 'main.dart';

class TcpHandler {
  static Socket socket;
  static Stream<Uint8List> myStream;
  static StreamController<String> messageStream;

  static String _payload = "";

  static Future<void> initSocket(String ip, int port) async {
      socket = await Socket.connect(ip, port, timeout: Duration(seconds: 10));
      myStream = socket.asBroadcastStream();
      messageStream = new StreamController.broadcast();
  }

  static Future<void> startService(BuildContext context) async {
      socket.listen((data) {
        _payload = _payload + utf8.decode(data);
        String message = _payload;
        while (message.length != 0 && message.contains(Message.eom)) {
          messageStream.add(message.substring(0, message.indexOf(Message.eom)));
          message = message
              .substring(message.indexOf(Message.eom) + Message.eom.length);
        }
        _payload = message;
      }, onError: (error) {
        print(error);
        messageStream.close();
        socket.close();
        onConnectionLost(context);
      }, onDone: () {
        messageStream.close();
        socket.close();
      }, cancelOnError: true);

    
  }

  static void sendMessage(String message, BuildContext context) {
    try {
      socket.add(utf8.encode(message + Message.eom));
    }
    catch(err) {
      print(err);
      onConnectionLost(context);
    }
  }

  static Stream<String> getMessageStream() {
    return messageStream.stream;
  }

  static StreamSubscription<String> getMessageStreamSubscription() {
    return messageStream.stream.listen((event) {});
  }

  static void closeSocket() {
    socket.close();
  }
}
