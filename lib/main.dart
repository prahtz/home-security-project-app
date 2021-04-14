import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:home_security_project_app/push_notifications.dart';
import 'package:home_security_project_app/register_pages.dart';
import 'package:home_security_project_app/auth_pages.dart';
import 'package:alarm_notification/alarm_notification.dart';
import 'package:home_security_project_app/tcp_handler.dart';
import 'custom_icons_icons.dart';
import 'dart:io';
import 'dart:async';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:move_to_background/move_to_background.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(Phoenix(child: MyApp()));
}

class NoAnimationMaterialPageRoute<T> extends MaterialPageRoute<T> {
  NoAnimationMaterialPageRoute({
    @required WidgetBuilder builder,
    RouteSettings settings,
    bool maintainState = true,
    bool fullscreenDialog = false,
  }) : super(
            builder: builder,
            maintainState: maintainState,
            settings: settings,
            fullscreenDialog: fullscreenDialog);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateRoute: (settings) {
        if (settings.name == MyHomePage.id) {
          return MaterialPageRoute(
              settings: settings,
              builder: (_) {
                return MyHomePage(
                  title: 'Home Security Project',
                );
              });
        } else if (settings.name == PinFirstSetupPage.id) {
          return MaterialPageRoute(
              settings: settings,
              builder: (_) {
                return PinFirstSetupPage();
              });
        } else if (settings.name == PinUpdatePage.id) {
          return MaterialPageRoute(
              settings: settings,
              builder: (_) {
                return PinUpdatePage();
              });
        } else if (settings.name == PinCheckPage.id) {
          return MaterialPageRoute(
              settings: settings,
              builder: (_) {
                return PinCheckPage(settings.arguments);
              });
        } else if (settings.name == RegisterFirstPage.id) {
          return MaterialPageRoute(
              settings: settings, builder: (_) => RegisterFirstPage());
        } else if (settings.name == RegisterSecondPage.id) {
          return NoAnimationMaterialPageRoute(
              settings: settings, builder: (_) => RegisterSecondPage());
        } else if (settings.name == RegisterThirdPage.id) {
          return NoAnimationMaterialPageRoute(
              settings: settings,
              builder: (_) {
                return RegisterThirdPage();
              });
        }
        return MaterialPageRoute(builder: (_) => WaitingPage());
      },
      title: 'Home Security Project',
      theme: ThemeData(
        primarySwatch: Colors.grey,
        primaryColor: Colors.grey[200],
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: WaitingPage(),
    );
  }
}

class WaitingPage extends StatefulWidget {
  @override
  _WaitingPageState createState() => _WaitingPageState();
}

class _WaitingPageState extends State<WaitingPage>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    tryConnection();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        body: Stack(children: <Widget>[
      Builder(builder: (context) {
        return Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
        );
      }),
      Center(
          child: SpinKitCircle(
              color: Colors.black,
              size: 50.0,
              controller: AnimationController(
                  vsync: this, duration: const Duration(milliseconds: 1200))))
    ]));
  }

  void tryConnection() async {
    String ip = "prah.homepc.it";
    int port = 33470;
    try {
      await TcpHandler.initSocket(ip, port);
      await TcpHandler.startService(context);
      _initListener();
      _sendFirebaseToken();
    } catch (err) {
      showAlertDialog(context, "Impossibile connettersi alla centralina",
          "Verificare la connessione di rete e riprovare.", (void value) {
        Phoenix.rebirth(context);
        return value;
      });
    }
  }

  void _setupFirstPin() async {
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
    TcpHandler.sendMessage(Message.pinFirstSetup);
  }

  void _sendFirebaseToken() async {
    if (Platform.isAndroid) {
      await PushNotificationsManager().init();
      var sub = TcpHandler.getMessageStreamSubscription();
      sub.onData((message) {
        if (message == Message.ack)
          TcpHandler.sendMessage(
              Message.string + PushNotificationsManager.token);
        else if (message == Message.firebaseTokenReceived) {
          _setupFirstPin();
          sub.cancel();
        }
      });
      TcpHandler.sendMessage(Message.firebaseToken);
    } else {
      _setupFirstPin();
    }
  }

  void _initListener() {
    TcpHandler.getMessageStreamSubscription().onData((message) {
      switch (message) {
        case Message.nextCode:
          Navigator.pushNamed(context, RegisterSecondPage.id, arguments: null);
          break;
        case Message.stringRequest:
          Navigator.pushNamed(context, RegisterThirdPage.id);
          break;
        case Message.activationSuccess:
          TcpHandler.sendMessage(Message.requestInfo);
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
          TcpHandler.sendMessage(Message.requestInfo);
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
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  static const String id = 'homepage';
  final String title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

Future<bool> _onBackPressed() async {
  if (Platform.isAndroid) {
    MoveToBackground.moveTaskToBack();
    return Future.value(false);
  }
  return false;
}

class _MyHomePageState extends State<MyHomePage> {
  int backgroundColor = 200;
  double iconSize = 100;
  int _selectedIndex = 0;
  PageController _pageController;
  List<List<String>> sensorInfoList = new List<List<String>>();
  bool _alarmActive = false;
  static const Map<String, int> _sensorIndexMap = {
    'type': 0,
    'id': 1,
    'status': 2,
    'enabled': 3,
    'charged': 4,
    'open_code': 5,
    'close_code': 6,
    'info': 7
  };

  @override
  void initState() {
    super.initState();
    _initListener();
    TcpHandler.sendMessage(Message.requestInfo);
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _initListener() {
    TcpHandler.getMessageStreamSubscription().onData((message) {
      if (message == Message.alarmActive || message == Message.alarmInactive) {
        setState(() {
          _alarmActive = message == Message.alarmActive ? true : false;
        });
      }
    });
  }

  void _activateAlarmPressed() async {
    TcpHandler.sendMessage(Message.activateAlarm);
  }

  void _deactivateAlarmPressed() {
    SendPort sp = IsolateNameServer.lookupPortByName("hsp");
    if (sp != null) sp.send("stop");
    AlarmNotification.stop();
    TcpHandler.sendMessage(Message.deactivateAlarm);
  }

  void _onSensorListInfo(List<String> sensorInfo, int index, bool tapped) {
    sensorInfoList = new List<List<String>>();
    for (String sensor in sensorInfo) {
      sensorInfoList.add(sensor.split(Message.separator));
    }
    print("LISTA SENSORI\n" + sensorInfoList.toString());
    setState(() {
      _selectedIndex = index;
    });
    if (tapped)
      _pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
  }

  void _getSensorList(int index, bool tapped) {
    var sensorInfo = new List<String>();
    var subscription = TcpHandler.getMessageStreamSubscription();
    subscription.onData((message) {
      switch (message) {
        case Message.endSensorList:
          setState(() {
            _selectedIndex = index;
          });
          if (tapped)
            _pageController.animateToPage(
              1,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            );
          subscription.cancel();
          _onSensorListInfo(sensorInfo, index, tapped);
          break;
        default:
          if (message.contains(Message.string)) {
            message = Message.clearStringMessage(message);
            sensorInfo.add(message);
          }
      }
    });
    TcpHandler.sendMessage(Message.sensorList);
  }

  void _onPageChanged(int index, bool tapped) {
    if (index == 1 && _selectedIndex == 0) {
      _getSensorList(index, tapped);
    } else if (index == 0 && _selectedIndex == 1) {
      setState(() {
        _selectedIndex = index;
      });
      if (tapped) {
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  String getSensorStateName(List<String> sensorInfo) {
    if (sensorInfo[_sensorIndexMap['enabled']] == "0") {
      return "DISABILITATO";
    }
    if (sensorInfo[_sensorIndexMap['status']] == "0")
      return "APERTO";
    else if (sensorInfo[2] == "1") return "CHIUSO";
    return "NON DETERMINATO";
  }

  Future<void> showOptionsDialog(
      BuildContext context, String title, int index, Function onClose) {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(title),
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () {
                deactivateSensor(index);
                Navigator.of(context).pop();
              },
              child: Text('Disattiva sensore'),
            ),
            SimpleDialogOption(
              onPressed: () {
                activateSensor(index);
                Navigator.of(context).pop();
              },
              child: Text('Attiva sensore'),
            ),
            SimpleDialogOption(
              onPressed: () {
                removeSensor(index, context);
                //Navigator.of(context).pop();
              },
              child: Text('Rimuovi sensore'),
            ),
            SimpleDialogOption(
              onPressed: () {
                updateBatteryStatus(index);
                Navigator.of(context).pop();
              },
              child: Text('Aggiorna stato batteria'),
            ),
          ],
        );
      },
    ).then(onClose);
  }

  void updateBatteryStatus(index) {
    String sensorID = sensorInfoList[index][_sensorIndexMap['id']];
    var subscription = TcpHandler.getMessageStreamSubscription();
    subscription.onData((message) {
      switch (message) {
        case Message.ack:
          TcpHandler.sendMessage(Message.string + sensorID);
          break;
        case Message.updateBatterySuccess:
          showAlertDialog(
              context, "Stato della batteria aggionato con successo!", "\n",
              (v) {
            _getSensorList(1, false);
            Navigator.popUntil(
                context, (route) => route.settings.name == MyHomePage.id);
            return v;
          });
          subscription.cancel();
          break;
        case Message.updateBatteryFailed:
          showAlertDialog(context, "Errore: batteria non scarica!",
              "La batteria non è scarica.\nNon è dunque necessario aggionare lo stato della batteria.",
              (v) {
            _getSensorList(1, false);
            Navigator.popUntil(
                context, (route) => route.settings.name == MyHomePage.id);
            return v;
          });
          subscription.cancel();
          break;
      }
    });
    TcpHandler.sendMessage(Message.updateBattery);
  }

  void removeSensor(index, context) {
    Function f = () {
      String sensorID = sensorInfoList[index][_sensorIndexMap['id']];
      var subscription = TcpHandler.getMessageStreamSubscription();
      subscription.onData((message) {
        switch (message) {
          case Message.ack:
            TcpHandler.sendMessage(Message.string + sensorID);
            break;
          case Message.removeSensorSuccess:
            showAlertDialog(context, "Sensore rimosso con successo!",
                "Il sensore è stato rimosso.\nPotrai riaggiungerlo con l'opzione \"Registra nuovo sensore\".",
                (v) {
              _getSensorList(1, false);
              Navigator.popUntil(
                  context, (route) => route.settings.name == MyHomePage.id);
              return v;
            });
            subscription.cancel();
            break;
          case Message.removeSensorFailed:
            showAlertDialog(context, "Errore: sensore non rimovibile!",
                "Non è stato possibile rimuovere il sensore.\nVerifica nuovamente lo stato attuale del sensore.",
                (v) {
              _getSensorList(1, false);
              Navigator.popUntil(
                  context, (route) => route.settings.name == MyHomePage.id);
              return v;
            });
            subscription.cancel();
            break;
        }
      });
    };
    var subscription = TcpHandler.getMessageStreamSubscription();
    subscription.onData((message) {
      switch (message) {
        case Message.ack:
          Navigator.pushNamed(context, PinCheckPage.id, arguments: f);
          subscription.cancel();
          break;
        case Message.pinCheckFailed:
          showAlertDialog(context, "PIN non inizializzato!",
              "Errore non previsto, sarai reindirizzato verso la pagina principale.",
              (v) {
            Navigator.popUntil(
                context, (route) => route.settings.name == MyHomePage.id);
            return v;
          });
          subscription.cancel();
          break;
      }
    });
    TcpHandler.sendMessage(Message.removeSensor);
  }

  void deactivateSensor(int index) {
    String sensorID = sensorInfoList[index][_sensorIndexMap['id']];
    var subscription = TcpHandler.getMessageStreamSubscription();
    subscription.onData((message) {
      print(message);
      switch (message) {
        case Message.ack:
          TcpHandler.sendMessage(Message.string + sensorID);
          break;
        case Message.deactivateSensorSuccess:
          showAlertDialog(context, "Sensore disattivato con successo!",
              "Il sensore è stato disattivato.\nPuoi riattivarlo in qualsiasi momento.",
              (v) {
            _getSensorList(1, false);
            Navigator.popUntil(
                context, (route) => route.settings.name == MyHomePage.id);
            return v;
          });
          subscription.cancel();
          break;
        case Message.deactivateSensorFailed:
          showAlertDialog(context, "Errore: sensore non disattivabile!",
              "Non è stato possibile disattivare il sensore.\nVerifica nuovamente lo stato attuale del sensore.",
              (v) {
            _getSensorList(1, false);
            Navigator.popUntil(
                context, (route) => route.settings.name == MyHomePage.id);
            return v;
          });
          subscription.cancel();
          break;
      }
    });
    TcpHandler.sendMessage(Message.deactivateSensor);
  }

  void activateSensor(int index) {
    String sensorID = sensorInfoList[index][_sensorIndexMap['id']];
    var subscription = TcpHandler.getMessageStreamSubscription();
    subscription.onData((message) {
      switch (message) {
        case Message.ack:
          TcpHandler.sendMessage(Message.string + sensorID);
          break;
        case Message.activateSensorSuccess:
          showAlertDialog(context, "Sensore attivato con successo!",
              "Il sensore è stato attivato.\nPuoi disattivarlo in qualsiasi momento.",
              (v) {
            _getSensorList(1, false);
            Navigator.popUntil(
                context, (route) => route.settings.name == MyHomePage.id);
            return v;
          });
          subscription.cancel();
          break;
        case Message.activateSensorFailed:
          showAlertDialog(context, "Errore: sensore non attivabile!",
              "Non è stato possibile attivare il sensore.\nVerifica nuovamente lo stato attuale del sensore.\nSe l'allarme è attivo, assicurati che il sensore sia nello stato CHIUSO prima di procedere con l'attivazione.",
              (v) {
            _getSensorList(1, false);
            Navigator.popUntil(
                context, (route) => route.settings.name == MyHomePage.id);
            return v;
          });
          subscription.cancel();
          break;
      }
    });
    TcpHandler.sendMessage(Message.activateSensor);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: _onBackPressed,
        child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              centerTitle: true,
              title: Text(
                widget.title,
              ),
              actions: <Widget>[
                Container(
                    child: Container(
                  child: Icon(
                    Icons.fiber_manual_record,
                    color: _alarmActive ? Colors.red[500] : Colors.green[500],
                  ),
                  padding: EdgeInsets.all(15),
                ))
              ],
            ),
            bottomNavigationBar: BottomNavigationBar(
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.event_note),
                  label: 'Lista Sensori',
                ),
              ],
              currentIndex: _selectedIndex,
              onTap: (index) => _onPageChanged(index, true),
              selectedItemColor: Colors.amber[800],
            ),
            backgroundColor: Colors.grey[backgroundColor],
            body: PageView(
                onPageChanged: (pageID) => _onPageChanged(pageID, false),
                controller: _pageController,
                children: [
                  Builder(builder: (BuildContext context) {
                    double spacing = 10;
                    const double padding = 20;
                    double bodyHeigth = MediaQuery.of(context).size.height -
                        Scaffold.of(context).appBarMaxHeight -
                        kBottomNavigationBarHeight;
                    double buttonHeigth =
                        (bodyHeigth - spacing - 2 * padding) / 2;
                    double buttonWidth = (MediaQuery.of(context).size.width -
                            spacing -
                            2 * padding) /
                        2;
                    return GridView.count(
                      crossAxisCount: 2,
                      padding: const EdgeInsets.all(padding),
                      mainAxisSpacing: spacing,
                      crossAxisSpacing: spacing,
                      childAspectRatio: (buttonWidth / buttonHeigth),
                      children: <Widget>[
                        FlatButton(
                            onLongPress: _deactivateAlarmPressed,
                            onPressed: () {
                              Fluttertoast.showToast(
                                  msg: "Tieni premuto per continuare!",
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.BOTTOM,
                                  timeInSecForIosWeb: 1,
                                  fontSize: 16.0);
                            },
                            color: Colors.white,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.lock_open,
                                    size: buttonWidth > buttonHeigth
                                        ? buttonWidth / 6
                                        : buttonHeigth / 3,
                                  ),
                                  SizedBox(height: buttonHeigth / 30),
                                  Text("Disattiva allarme",
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.openSans(
                                          textStyle: TextStyle(fontSize: 17)))
                                ])),
                        FlatButton(
                            onLongPress: _activateAlarmPressed,
                            onPressed: () {
                              Fluttertoast.showToast(
                                  msg: "Tieni premuto per continuare!",
                                  toastLength: Toast.LENGTH_SHORT,
                                  gravity: ToastGravity.BOTTOM,
                                  timeInSecForIosWeb: 1,
                                  fontSize: 16.0);
                            },
                            color: Colors.white,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.lock,
                                    size: buttonWidth > buttonHeigth
                                        ? buttonWidth / 6
                                        : buttonHeigth / 3,
                                  ),
                                  SizedBox(height: buttonHeigth / 30),
                                  Text("Attiva allarme",
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.openSans(
                                          textStyle: TextStyle(fontSize: 17)))
                                ])),
                        FlatButton(
                            onPressed: () => Navigator.pushNamed(
                                  context,
                                  RegisterFirstPage.id,
                                ),
                            color: Colors.white,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    CustomIcons.door_sensor,
                                    size: buttonWidth > buttonHeigth
                                        ? buttonWidth / 6
                                        : buttonHeigth / 3,
                                  ),
                                  SizedBox(height: buttonHeigth / 30),
                                  Text("Registra sensore magnetico",
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.openSans(
                                          textStyle: TextStyle(fontSize: 17)))
                                ])),
                        FlatButton(
                            onPressed: () => _pinUpdate(),
                            color: Colors.white,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.dialpad,
                                    size: buttonWidth > buttonHeigth
                                        ? buttonWidth / 6
                                        : buttonHeigth / 3,
                                  ),
                                  SizedBox(height: buttonHeigth / 30),
                                  Text("Modifica PIN",
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.openSans(
                                          textStyle: TextStyle(fontSize: 17)))
                                ])),
                      ],
                    );
                  }),
                  Stack(children: [
                    ListView.builder(
                      itemCount: sensorInfoList.length == 0
                          ? 1
                          : sensorInfoList.length,
                      itemBuilder: (_, index) {
                        if (sensorInfoList.length != 0) {
                          Column column = new Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: [
                                  Flexible(
                                      child: ListTile(
                                    onTap: () => showOptionsDialog(context,
                                        "Opzioni sensore", index, (v) {}),
                                    title: Text("Nome sensore: " +
                                        sensorInfoList[index]
                                            [_sensorIndexMap['info']] +
                                        "\nStato sensore: " +
                                        getSensorStateName(
                                            sensorInfoList[index])),
                                  )),
                                  Container(
                                      child: Container(
                                    child: sensorInfoList[index]
                                                [_sensorIndexMap['charged']] ==
                                            "0"
                                        ? Icon(
                                            Icons.battery_alert,
                                            color: Colors.red[500],
                                          )
                                        : Container(),
                                    padding: EdgeInsets.all(15),
                                  ))
                                ],
                              ),
                              Divider(),
                            ],
                          );
                          if (index == 0) column.children.insert(0, Divider());
                          return column;
                        } else {
                          Container c = new Container(
                            margin: const EdgeInsets.all(15.0),
                            child: Center(
                                child: Text("NESSUN SENSORE REGISTRATO")),
                          );
                          return c;
                        }
                      },
                    ),
                    Container(
                        alignment: Alignment.bottomRight,
                        padding: EdgeInsets.all(15),
                        child: FloatingActionButton(
                          onPressed: () {
                            _getSensorList(1, false);
                          },
                          child: Icon(Icons.refresh),
                          backgroundColor: Colors.amber[800],
                        ))
                  ])
                ])));
  }

  void _pinUpdate() {
    var subscription = TcpHandler.getMessageStreamSubscription();
    subscription.onData((message) {
      switch (message) {
        case Message.ack:
          Navigator.pushNamed(
            context,
            PinUpdatePage.id,
          );
          subscription.cancel();
          break;
        case Message.updatePinFailed:
          showAlertDialog(context, "Modifica PIN fallita!",
              "Errore non previsto, sarai reindirizzato verso la pagina principale.",
              (v) {
            Navigator.popUntil(
                context, (route) => route.settings.name == MyHomePage.id);
            return v;
          });
          subscription.cancel();
          break;
      }
    });

    TcpHandler.sendMessage(Message.updatePin);
  }
}

class Message {
  static final Message _singleton = Message._internal();
  static const String activateAlarm = "00";
  static const String deactivateAlarm = "01";
  static const String registerDoorSensor = "02";
  static const String sensorList = "03";
  static const String ack = "04";
  static const String abort = "05";
  static const String nextCode = "06";
  static const String registerSuccess = "07";
  static const String registerFailed = "08";
  static const String activationSuccess = "09";
  static const String activationFailed = "0A";
  static const String deactivationSuccess = "0B";
  static const String deactivationFailed = "0C";
  static const String endSensorList = "0D";
  static const String timeOut = "0E";
  static const String deactivateSensor = "0F";
  static const String deactivateSensorSuccess = "10";
  static const String deactivateSensorFailed = "11";
  static const String activateSensor = "12";
  static const String activateSensorSuccess = "13";
  static const String activateSensorFailed = "14";
  static const String removeSensor = "15";
  static const String removeSensorSuccess = "16";
  static const String removeSensorFailed = "17";
  static const String alarmActive = "18";
  static const String alarmInactive = "19";
  static const String requestInfo = "1A";
  static const String updateBattery = "1B";
  static const String updateBatterySuccess = "1C";
  static const String updateBatteryFailed = "1D";
  static const String updatePin = "1E";
  static const String updatePinSuccess = "1F";
  static const String updatePinFailed = "20";
  static const String pinCheck = "21";
  static const String pinCheckSuccess = "22";
  static const String pinCheckFailed = "23";
  static const String firebaseToken = "24";
  static const String firebaseTokenReceived = "25";
  static const String stringRequest = "26";
  static const String pinFirstSetup = "27";
  static const String pinFirstSetupSuccess = "28";
  static const String pinFirstSetupFailed = "29";
  static const String eom = "//eom";
  static const String none = "//none";
  static const String string = "//·";
  static const String separator = ";";
  static String clearStringMessage(String msg) {
    return msg.substring(string.length);
  }

  factory Message() => _singleton;

  Message._internal(); // private constructor
}

Future<void> showSocketErrorDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false, // user must tap button!
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Connessione al server persa'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text(
                  'Controlla la connessione ad internet, l\'applicazione verrà riavviata.'),
            ],
          ),
        ),
        actions: <Widget>[
          FlatButton(
            child: Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  ).then((value) => Phoenix.rebirth(context));
}

Future<void> showAlertDialog(
    BuildContext context, String title, String description, Function onClose) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text(description),
            ],
          ),
        ),
        actions: <Widget>[
          FlatButton(
            child: Text('OK'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  ).then(onClose);
}
