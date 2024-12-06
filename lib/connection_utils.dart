import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:home_security_project_app/push_notifications.dart';
import 'tcp_handler.dart';
import 'main.dart';
import 'register_pages.dart';
import 'auth_pages.dart';

void tryConnection(BuildContext context) async {
  var ips = ["prah.homepc.it", "192.168.1.48"];
  int port = 33470;
  int connFailedCount = 0;
  for (String ip in ips) {
    try {
      await TcpHandler.initSocket(ip, port);
      await TcpHandler.startService(context);
      _initListener(context);
      _sendFirebaseToken(context);
      break;
    } catch (err) {
      connFailedCount = connFailedCount + 1;
    }
  }
  if (connFailedCount == ips.length) {
    showAlertDialog(context, "Impossibile connettersi alla centralina",
        "Verificare la connessione di rete e riprovare.", (void value) {
      Phoenix.rebirth(context);
      return value;
    });
  }
}

void _setupFirstPin(BuildContext context) async {
  var sub = TcpHandler.getMessageStreamSubscription();
  sub.onData((message) {
    if (message == Message.ack) {
      Navigator.pushNamed(context, PinFirstSetupPage.id);
      sub.cancel();
    } else if (message == Message.pinFirstSetupFailed) {
      Navigator.pushNamed(context, MyHomePage.id);
      sub.cancel();
    }
  });
  TcpHandler.sendMessage(Message.pinFirstSetup, context);
}

void _sendFirebaseToken(BuildContext context) async {
  if (Platform.isAndroid) {
    await PushNotificationsManager().init();
    var sub = TcpHandler.getMessageStreamSubscription();
    sub.onData((message) {
      if (message == Message.ack)
        TcpHandler.sendMessage(
            Message.string + PushNotificationsManager.token, context);
      else if (message == Message.firebaseTokenReceived) {
        _setupFirstPin(context);
        sub.cancel();
      }
    });
    TcpHandler.sendMessage(Message.firebaseToken, context);
  } else {
    _setupFirstPin(context);
  }
}

void _initListener(BuildContext context) {
  TcpHandler.getMessageStreamSubscription().onData((message) {
    switch (message) {
      case Message.nextCode:
        Navigator.pushNamed(context, RegisterSecondPage.id, arguments: null);
        break;
      case Message.stringRequest:
        Navigator.pushNamed(context, RegisterThirdPage.id);
        break;
      case Message.activationSuccess:
        TcpHandler.sendMessage(Message.requestInfo, context);
        showAlertDialog(context, "Allarme attivato!",
            "Tieni premuto sul pulsante \"Disattiva allarme\" per disattivare l'allarme",
            (v) {
          return v;
        });
        break;
      case Message.activationFailed:
        showAlertDialog(context, "Impossibile attivare l'allarme",
            "Controlla che tutti gli ingressi siano chiusi.\n\nPremi su \"Lista sensori\" per visualizzare lo stato attuale degli ingressi",
            (v) {
          return v;
        });
        break;
      case Message.deactivationSuccess:
        TcpHandler.sendMessage(Message.requestInfo, context);
        showAlertDialog(context, "Allarme disattivato!", "", (v) {
          return v;
        });
        break;
      case Message.deactivationFailed:
        showAlertDialog(context, "Impossibile disattivare l'allarme",
            "Assicurati che l'allarme sia già attivo!", (v) {
          return v;
        });
        break;
      case Message.timeOut:
        showAlertDialog(context, "Tempo scaduto!",
            "Sarai reindirizzato verso la pagina principale", (v) {
          Navigator.popUntil(
              context, (route) => route.settings.name == MyHomePage.id);
          return v;
        });
        break;
      default:
    }
  });
}
