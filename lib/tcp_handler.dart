import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:home_security_project_app/register_pages.dart';

import 'main.dart';

class TcpHandler {
  static Socket socket;
  static Stream<Uint8List> myStream;
  static StreamController<String> messageStream =
      new StreamController.broadcast();

  static String _payload = "";

  static Future<void> initSocket(String ip, int port) async {
    socket = await Socket.connect(ip, port, timeout: Duration(seconds: 10));
    myStream = socket.asBroadcastStream();
  }

  static Future<void> startService(BuildContext context) async {
    try {
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
        showSocketErrorDialog(context);
        messageStream.close();
        socket.close();
      }, onDone: () {
        messageStream.close();
        socket.close();
      }, cancelOnError: true);
    } catch (err) {
      socket.close();
      messageStream.close();
      print(err);
      print("Nessuna connessione disponibile");
      showAlertDialog(context, "Impossibile connettersi alla centralina",
          "Verificare la connessione di rete e riprovare.", (void value) {
        Phoenix.rebirth(context);
        return value;
      });
    }
  }

  static void sendMessage(String message) async {
    socket.add(utf8.encode(message + Message.eom));
  }

  static Stream<String> getMessageStream() {
    return messageStream.stream;
  }

  static StreamSubscription<String> getMessageStreamSubscription() {
    return messageStream.stream.listen((event) {});
  }
}
