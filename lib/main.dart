import 'dart:isolate';
import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:home_security_project_app/push_notifications.dart';
import 'package:home_security_project_app/register_pages.dart';
import 'package:alarm_notification/alarm_notification.dart';
import 'custom_icons_icons.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
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
                Map args = settings.arguments;
                return MyHomePage(
                  title: 'Home Security Project',
                  socket: args['socket'],
                  socketStream: args['socketStream'],
                );
              });
        } else if (settings.name == RegisterFirstPage.id) {
          return MaterialPageRoute(
              settings: settings,
              builder: (_) => RegisterFirstPage(socket: settings.arguments));
        } else if (settings.name == RegisterSecondPage.id) {
          return NoAnimationMaterialPageRoute(
              settings: settings,
              builder: (_) => RegisterSecondPage(socket: settings.arguments));
        } else if (settings.name == RegisterThirdPage.id) {
          return NoAnimationMaterialPageRoute(
              settings: settings,
              builder: (_) {
                Map args = settings.arguments;
                return RegisterThirdPage(
                  socket: args['socket'],
                  socketStream: args['socketStream'],
                );
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
    try {
      String ip = "prah.homepc.it";
      int port = 33470;
      Socket socket =
          await Socket.connect(ip, port, timeout: Duration(seconds: 10));
      Stream<Uint8List> myStream = socket.asBroadcastStream();
      myStream.listen((data) {
        print(utf8.decode(data) + " LISTEN 1");
        String message = utf8.decode(data);
        if (message.contains(Message.eom)) {
          message = message.substring(0, message.length - Message.eom.length);
          if (message == Message.nextCode)
            Navigator.pushNamed(context, RegisterSecondPage.id,
                arguments: socket);
          else if (message == MessageType.string) {
            Navigator.pushNamed(context, RegisterThirdPage.id,
                arguments: {'socket': socket, 'socketStream': myStream});
          } else if (message == Message.registerSuccess) {
            //MEX DI ERRORE
            showAlertDialog(
                context,
                "Registrazione del sensore completata!",
                "Il sensore da questo momento è attivo.",
                (v) => Navigator.popUntil(
                    context, (route) => route.settings.name == MyHomePage.id));
          } else if (message == Message.registerFailed) {
            //MEX DI ERRORE
            showAlertDialog(
                context,
                "ERRORE: registrazione del sensore fallita!",
                "Qualcosa è andato storto! Riprova!.",
                (v) => Navigator.popUntil(
                    context, (route) => route.settings.name == MyHomePage.id));
          } else if (message == Message.abort) {
            //MEX DI ERRORE
            Navigator.popUntil(
                context, (route) => route.settings.name == MyHomePage.id);
          } else if (message == Message.activationSuccess) {
            print("Allarme attivo");
            showAlertDialog(context, "Allarme attivato!",
                "Tieni premuto sul pulsante \"Disattiva allarme\" per disattivare l'allarme",
                (v) {
              return v;
            });
          } else if (message == Message.activationFailed) {
            print("Allarme non attivabile");
            showAlertDialog(context, "Impossibile attivare l'allarme",
                "Controlla che tutti gli ingressi siano chiusi.\n\nPremi su \"Lista sensori\" per visualizzare lo stato attuale degli ingressi",
                (v) {
              return v;
            });
          } else if (message == Message.deactivationSuccess) {
            print("Allarme disattivato");
            showAlertDialog(context, "Allarme disattivato!", "", (v) {
              return v;
            });
          } else if (message == Message.deactivationFailed) {
            print("Allarme non disattivabile");
            showAlertDialog(context, "Impossibile disattivare l'allarme",
                "Assicurati che l'allarme sia già attivo!", (v) {
              return v;
            });
          } else if (message == Message.timeOut) {
            print("Tempo scaduto");
            showAlertDialog(context, "Tempo scaduto!",
                "Sarai reindirizzato verso la pagina principale", (v) {
              Navigator.popUntil(
                  context, (route) => route.settings.name == MyHomePage.id);
              return v;
            });
          }
        } else {
          Navigator.popUntil(
              context, (route) => route.settings.name == MyHomePage.id);
          print("Valore inaspettato ricevuto");
        }
      }, onError: (error) {
        showSocketErrorDialog(context);
        socket.close();
      }, onDone: () {
        socket.close();
      }, cancelOnError: true);

      if (Platform.isAndroid) 
        await PushNotificationsManager().init();
      socket.add(utf8.encode(PushNotificationsManager.token + Message.eom));

      Navigator.pushNamed(
        context,
        MyHomePage.id,
        arguments: {'socket': socket, 'socketStream': myStream},
      );
    } catch (err) {
      print(err);
      print("Nessuna connessione disponibile");
      showAlertDialog(context, "Impossibile connettersi alla centralina",
          "Verificare la connessione di rete e riprovare.", (void value) {
        Phoenix.rebirth(context);
        return value;
      });
    }
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title, this.socket, this.socketStream})
      : super(key: key);

  static const String id = 'homepage';
  final String title;
  final Socket socket;
  final Stream<Uint8List> socketStream;
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


  @override
  void initState() {
    super.initState();

    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _activateAlarmPressed() {
    widget.socket.add(utf8.encode(Message.activateAlarm + Message.eom));
  }

  void _deactivateAlarmPressed() {
    
    SendPort sp = IsolateNameServer.lookupPortByName("hsp");
    if(sp != null)
      sp.send("stop");
    AlarmNotification.stop();
    widget.socket.add(utf8.encode(Message.deactivateAlarm + Message.eom));
  }

  void _onSensorListInfo(String message, int index, bool tapped) {
    message = message.substring(0, message.length - Message.eom.length);
    List<List<String>> sensorInfoList = new List<List<String>>();
    List<String> sensorInfo = new List<String>();
    int i = 0;
    int j = 0;
    bool go = true;
    while (go) {
      while (message[i] != ";" && message[i] != Message.eom[0]) i++;
      sensorInfo.add(message.substring(j, i));
      print(message.substring(j, i));
      if (message[i] == Message.eom[0]) {
        sensorInfoList.add(sensorInfo);
        sensorInfo = new List<String>();
        i = i + Message.eom.length;
        j = i;
        print(message.substring(i, message.length));
        if (message.substring(i, message.length) == Message.endSensorList)
          go = false;
      } else {
        i++;
        j = i;
      }
    }
    this.sensorInfoList = sensorInfoList;
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
    String message = "";
    sensorInfoList = new List<List<String>>();
    StreamSubscription<Uint8List> subscription;
    subscription = widget.socketStream.listen((data) {
      print(utf8.decode(data));
      message = message + utf8.decode(data);
      if (message.contains(Message.eom)) {
        if (message == Message.endSensorList + Message.eom) {
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
        }
        if (message
            .contains(Message.eom + Message.endSensorList + Message.eom)) {
          _onSensorListInfo(message, index, tapped);
          subscription.cancel();
        }
      }
    });
    widget.socket.add(utf8.encode(Message.sensorList + Message.eom));
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
    if (sensorInfo[3] == "0") {
      return "DISABILITATO";
    }
    if (sensorInfo[2] == "0")
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
                removeSensor(index);
                Navigator.of(context).pop();
              },
              child: Text('Rimuovi sensore'),
            ),
          ],
        );
      },
    ).then(onClose);
  }

  void removeSensor(index) {
    String sensorID = sensorInfoList[index][1];
    String message = "";
    StreamSubscription<Uint8List> subscription;
    subscription = widget.socketStream.listen((data) {
      print(utf8.decode(data));
      message = message + utf8.decode(data);
      if (message.contains(Message.eom)) {
        if (message.contains(Message.removeSensorSuccess + Message.eom)) {
          print("Sensore rimosso");
          showAlertDialog(context, "Sensore rimosso con successo!",
              "Il sensore è stato rimosso.\nPotrai riaggiungerlo con l'opzione \"Registra nuovo sensore\".",
              (v) {
            _getSensorList(1, false);
            Navigator.popUntil(
                context, (route) => route.settings.name == MyHomePage.id);
            return v;
          });
          subscription.cancel();
        } else if (message.contains(Message.removeSensorFailed + Message.eom)) {
          print("Errore: sensore non rimovibile!");
          showAlertDialog(context, "Errore: sensore non rimovibile!",
              "Non è stato possibile rimuovere il sensore.\nVerifica nuovamente lo stato attuale del sensore.",
              (v) {
            _getSensorList(1, false);
            Navigator.popUntil(
                context, (route) => route.settings.name == MyHomePage.id);
            return v;
          });
          subscription.cancel();
        }
      }
    });
    widget.socket
        .add(utf8.encode(sensorID + ";" + Message.removeSensor + Message.eom));
  }

  void deactivateSensor(int index) {
    String sensorID = sensorInfoList[index][1];
    String message = "";
    StreamSubscription<Uint8List> subscription;
    subscription = widget.socketStream.listen((data) {
      print(utf8.decode(data));
      message = message + utf8.decode(data);
      if (message.contains(Message.eom)) {
        if (message.contains(Message.deactivateSensorSuccess + Message.eom)) {
          print("Sensore disattivato");
          showAlertDialog(context, "Sensore disattivato con successo!",
              "Il sensore è stato disattivato.\nPuoi riattivarlo in qualsiasi momento.",
              (v) {
            _getSensorList(1, false);
            Navigator.popUntil(
                context, (route) => route.settings.name == MyHomePage.id);
            return v;
          });
          subscription.cancel();
        } else if (message
            .contains(Message.deactivateSensorFailed + Message.eom)) {
          print("Errore: sensore non disattivabile!");
          showAlertDialog(context, "Errore: sensore non disattivabile!",
              "Non è stato possibile disattivare il sensore.\nVerifica nuovamente lo stato attuale del sensore.",
              (v) {
            _getSensorList(1, false);
            Navigator.popUntil(
                context, (route) => route.settings.name == MyHomePage.id);
            return v;
          });
          subscription.cancel();
        }
      }
    });
    widget.socket.add(
        utf8.encode(sensorID + ";" + Message.deactivateSensor + Message.eom));
  }

  void activateSensor(int index) {
    String sensorID = sensorInfoList[index][1];
    String message = "";
    StreamSubscription<Uint8List> subscription;
    subscription = widget.socketStream.listen((data) {
      print(utf8.decode(data));
      message = message + utf8.decode(data);
      if (message.contains(Message.eom)) {
        if (message.contains(Message.activateSensorSuccess + Message.eom)) {
          print("Sensore attivato");
          showAlertDialog(context, "Sensore attivato con successo!",
              "Il sensore è stato attivato.\nPuoi disattivarlo in qualsiasi momento.",
              (v) {
            _getSensorList(1, false);
            Navigator.popUntil(
                context, (route) => route.settings.name == MyHomePage.id);
            return v;
          });
          subscription.cancel();
        } else if (message
            .contains(Message.activateSensorFailed + Message.eom)) {
          print("Errore: sensore non attivabile!");
          showAlertDialog(context, "Errore: sensore non attivabile!",
              "Non è stato possibile attivare il sensore.\nVerifica nuovamente lo stato attuale del sensore.\nSe l'allarme è attivo, assicurati che il sensore sia nello stato CHIUSO prima di procedere con l'attivazione.",
              (v) {
            _getSensorList(1, false);
            Navigator.popUntil(
                context, (route) => route.settings.name == MyHomePage.id);
            return v;
          });
          subscription.cancel();
        }
      }
    });
    widget.socket.add(
        utf8.encode(sensorID + ";" + Message.activateSensor + Message.eom));
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: _onBackPressed,
        child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              title: Center(
                  child: Text(
                widget.title,
              )),
            ),
            bottomNavigationBar: BottomNavigationBar(
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  title: Text('Home'),
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.event_note),
                  title: Text('Lista Sensori'),
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
                                context, RegisterFirstPage.id,
                                arguments: widget.socket),
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
                              ListTile(
                                  onTap: () => showOptionsDialog(context,
                                      "Opzioni sensore", index, (v) {}),
                                  title: Text("Nome sensore: " +
                                      sensorInfoList[index][6] +
                                      "\nStato sensore: " +
                                      getSensorStateName(
                                          sensorInfoList[index]))),
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
}

class MessageType {
  static final MessageType _singleton = MessageType._internal();
  static final String message = "a";
  static final String string = "b";

  factory MessageType() => _singleton;

  MessageType._internal(); // private constructor
}

class Message {
  static final Message _singleton = Message._internal();
  static final String activateAlarm = "00";
  static final String deactivateAlarm = "01";
  static final String registerDoorSensor = "02";
  static final String sensorList = "03";
  static final String ack = "04";
  static final String abort = "05";
  static final String nextCode = "06";
  static final String registerSuccess = "07";
  static final String registerFailed = "08";
  static final String activationSuccess = "09";
  static final String activationFailed = "0A";
  static final String deactivationSuccess = "0B";
  static final String deactivationFailed = "0C";
  static final String endSensorList = "0D";
  static final String timeOut = "0E";
  static final String deactivateSensor = "0F";
  static final String deactivateSensorSuccess = "10";
  static final String deactivateSensorFailed = "11";
  static final String activateSensor = "12";
  static final String activateSensorSuccess = "13";
  static final String activateSensorFailed = "14";
  static final String removeSensor = "15";
  static final String removeSensorSuccess = "16";
  static final String removeSensorFailed = "17";
  static final String eom = "//eom";

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
