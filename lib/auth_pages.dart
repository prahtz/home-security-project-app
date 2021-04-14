import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';

import 'package:home_security_project_app/main.dart';
import 'package:home_security_project_app/tcp_handler.dart';
import 'package:keyboard_visibility/keyboard_visibility.dart';
import 'package:move_to_background/move_to_background.dart';

class PinFirstSetupPage extends StatefulWidget {
  static const String id = 'pin_first_setup';
  PinFirstSetupPage() : super();

  @override
  _PinFirstSetupState createState() => _PinFirstSetupState();
}

class PinCheckPage extends StatefulWidget {
  static const String id = 'pin_check';
  final Function function;
  PinCheckPage(this.function) : super();

  @override
  _PinCheckState createState() => _PinCheckState();
}

class PinUpdatePage extends StatefulWidget {
  static const String id = 'pin_update';
  PinUpdatePage() : super();

  @override
  _PinUpdateState createState() => _PinUpdateState();
}

class _PinFirstSetupState extends State<PinFirstSetupPage>
    with SingleTickerProviderStateMixin {
  final myController = TextEditingController();
  FocusNode _focus = new FocusNode();
  double imagesHeight = 94;
  double transmitterWidth = 50;
  double magnetWidth = 22;
  double imagesSpacing = 10;
  double totalWidth;
  double _opacity = 1;
  bool go = false;
  String _labelText = "PIN";
  Color _labelTextColor = Colors.black;
  bool _isButtonDisabled = false;
  String _firstPin;

  final String newPIN =
      "Il PIN non è stato ancora inizializzato.\nInserisci il nuovo PIN";
  final String confirmPIN = "Conferma il nuovo PIN";
  String _pinText;

  @override
  void initState() {
    super.initState();
    _pinText = newPIN;
    _focus.addListener(_onFocusChange);
    KeyboardVisibilityNotification().addNewListener(
      onHide: () {
        FocusScope.of(context).requestFocus(new FocusNode());
      },
    );
    var subscription = TcpHandler.getMessageStreamSubscription();
    subscription.onData((message) {
      switch (message) {
        case Message.timeOut:
          showAlertDialog(context, "Tempo scaduto!",
              "Sarai reindirizzato verso la pagina iniziale", (v) {
            Phoenix.rebirth(context);
            return v;
          });
          subscription.cancel();
          break;
        case Message.pinFirstSetupSuccess:
          Navigator.pushNamed(context, MyHomePage.id);
          subscription.cancel();
          break;
      }
    });
  }

  void _onFocusChange() {
    setState(() {
      _opacity = 1 - _opacity;
    });
  }

  Future<bool> _onBackPressed() async {
    print("Pin Update abort");
    if (Platform.isAndroid) {
      MoveToBackground.moveTaskToBack();
      return false;
    }
    return false;
  }

  @override
  void dispose() {
    myController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: _onBackPressed,
        child: GestureDetector(
            onTap: () {
              FocusScope.of(context).requestFocus(new FocusNode());
            },
            child: Scaffold(
                appBar: AppBar(
                  leading: Container(),
                  title: Text("Inizializza PIN"),
                ),
                backgroundColor: Colors.grey[200],
                body: Stack(
                  children: <Widget>[
                    Builder(builder: (context) {
                      return Container(
                          height: MediaQuery.of(context).size.height -
                              Scaffold.of(context).appBarMaxHeight,
                          width: MediaQuery.of(context).size.width);
                    }),
                    Builder(builder: (context) {
                      return Positioned(
                          top: (MediaQuery.of(context).size.height -
                                  Scaffold.of(context).appBarMaxHeight) /
                              4,
                          left: (MediaQuery.of(context).size.width -
                                  (MediaQuery.of(context).size.width / 1.2)) /
                              2,
                          child: Container(
                              width: MediaQuery.of(context).size.width / 1.2,
                              child: Opacity(
                                  opacity: _opacity,
                                  child: Text(_pinText,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.normal,
                                          color: Colors.black87)))));
                    }),
                    Builder(builder: (context) {
                      return Center(
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: <Widget>[
                            Container(
                                width:
                                    (MediaQuery.of(context).size.width / 1.2) -
                                        60,
                                //color: Colors.white,
                                child: TextField(
                                  maxLength: 8,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'[0-9]')),
                                  ],
                                  decoration: InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(
                                          vertical: 17.0, horizontal: 10.0),
                                      fillColor: Colors.white,
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Colors.black, width: 1.0),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Colors.black, width: 1.0),
                                      ),
                                      labelText: _labelText,
                                      labelStyle:
                                          TextStyle(color: _labelTextColor)),
                                  controller: myController,
                                  onSubmitted: (text) => sendPIN(text),
                                  focusNode: _focus,
                                )),
                            Container(
                                height: 34.0 + 17.0 + 2.0,
                                child: FlatButton(
                                  onPressed: () {
                                    if (!_isButtonDisabled)
                                      sendPIN(myController.text);
                                  },
                                  color: Color(0xff3786ff),
                                  child: Icon(Icons.send, color: Colors.white),
                                ))
                          ]));
                    }),
                  ],
                ))));
  }

  void sendPIN(String pin) {
    if (pin.contains(Message.eom[0]) ||
        pin.contains(";") ||
        pin.isEmpty ||
        pin.length < 5) {
      setState(() {
        _labelText = pin.length < 5
            ? "PIN troppo corto (minimo 5 cifre)"
            : "PIN inserito non valido!";
        _labelTextColor = Colors.red;
        myController.clear();
      });
      return;
    }

    if (_pinText == newPIN) {
      _firstPin = pin;
      _updateState();
    } else if (_pinText == confirmPIN) {
      if (pin != _firstPin) {
        setState(() {
          _labelText = "Il PIN inserito non corrisponde al precedente!";
          _labelTextColor = Colors.red;
          myController.clear();
          _isButtonDisabled = false;
        });
      } else {
        TcpHandler.sendMessage(Message.string + pin);
        _updateState();
      }
    }
  }

  void _updateState() {
    setState(() {
      _focus.unfocus();
      if (_pinText == confirmPIN) _isButtonDisabled = true;
      _pinText = _pinText == newPIN ? confirmPIN : _pinText;
      _labelText = "PIN";
      _labelTextColor = Colors.black;
      myController.clear();
    });
  }
}

class _PinCheckState extends State<PinCheckPage>
    with SingleTickerProviderStateMixin {
  final myController = TextEditingController();
  FocusNode _focus = new FocusNode();
  double imagesHeight = 94;
  double transmitterWidth = 50;
  double magnetWidth = 22;
  double imagesSpacing = 10;
  double totalWidth;
  double _opacity = 1;
  bool go = false;
  String _labelText = "PIN";
  Color _labelTextColor = Colors.black;
  bool _isButtonDisabled = false;
  String _pinText = "Inserisci il PIN";
  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChange);
    KeyboardVisibilityNotification().addNewListener(
      onHide: () {
        FocusScope.of(context).requestFocus(new FocusNode());
      },
    );
    var subscription = TcpHandler.getMessageStreamSubscription();
    subscription.onData((message) {
      switch (message) {
        case Message.pinCheckSuccess:
          //proceed with passed procedure
          setState(() {
            _isButtonDisabled = true;
            _labelText = "PIN";
            _labelTextColor = Colors.black;
            myController.clear();
          });
          widget.function();
          subscription.cancel();
          break;
        case Message.pinCheckFailed:
          setState(() {
            _labelText = "PIN inserito non valido!";
            _labelTextColor = Colors.red;
            myController.clear();
          });
          break;
      }
    });
  }

  void _onFocusChange() {
    setState(() {
      _opacity = 1 - _opacity;
    });
  }

  Future<bool> _onBackPressed() async {
    print("Pin Update abort");
    TcpHandler.sendMessage(Message.abort);
    Navigator.popUntil(context, (route) {
      return route.settings.name == MyHomePage.id;
    });
    return false;
  }

  @override
  void dispose() {
    myController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: _onBackPressed,
        child: GestureDetector(
            onTap: () {
              FocusScope.of(context).requestFocus(new FocusNode());
            },
            child: Scaffold(
                appBar: AppBar(
                  title: Text("Verifica PIN"),
                ),
                backgroundColor: Colors.grey[200],
                body: Stack(
                  children: <Widget>[
                    Builder(builder: (context) {
                      return Container(
                          height: MediaQuery.of(context).size.height -
                              Scaffold.of(context).appBarMaxHeight,
                          width: MediaQuery.of(context).size.width);
                    }),
                    Builder(builder: (context) {
                      return Positioned(
                          top: (MediaQuery.of(context).size.height -
                                  Scaffold.of(context).appBarMaxHeight) /
                              4,
                          left: (MediaQuery.of(context).size.width -
                                  (MediaQuery.of(context).size.width / 1.2)) /
                              2,
                          child: Container(
                              width: MediaQuery.of(context).size.width / 1.2,
                              child: Opacity(
                                  opacity: _opacity,
                                  child: Text(_pinText,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.normal,
                                          color: Colors.black87)))));
                    }),
                    Builder(builder: (context) {
                      return Center(
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: <Widget>[
                            Container(
                                width:
                                    (MediaQuery.of(context).size.width / 1.2) -
                                        60,
                                //color: Colors.white,
                                child: TextField(
                                  maxLength: 8,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'[0-9]')),
                                  ],
                                  decoration: InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(
                                          vertical: 17.0, horizontal: 10.0),
                                      fillColor: Colors.white,
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Colors.black, width: 1.0),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Colors.black, width: 1.0),
                                      ),
                                      labelText: _labelText,
                                      labelStyle:
                                          TextStyle(color: _labelTextColor)),
                                  controller: myController,
                                  onSubmitted: (text) => sendPIN(text),
                                  focusNode: _focus,
                                )),
                            Container(
                                height: 34.0 + 17.0 + 2.0,
                                child: FlatButton(
                                  onPressed: () {
                                    if (!_isButtonDisabled)
                                      sendPIN(myController.text);
                                  },
                                  color: Color(0xff3786ff),
                                  child: Icon(Icons.send, color: Colors.white),
                                ))
                          ]));
                    }),
                  ],
                ))));
  }

  void sendPIN(String pin) {
    if (pin.contains(Message.eom[0]) ||
        pin.contains(";") ||
        pin.isEmpty ||
        pin.length < 5) {
      setState(() {
        _labelText = pin.length < 5
            ? "PIN troppo corto (minimo 5 cifre)"
            : "PIN inserito non valido!";
        _labelTextColor = Colors.red;
        myController.clear();
      });
      return;
    }
    TcpHandler.sendMessage(Message.string + pin);
  }
}

class _PinUpdateState extends State<PinUpdatePage>
    with SingleTickerProviderStateMixin {
  final myController = TextEditingController();
  FocusNode _focus = new FocusNode();
  double imagesHeight = 94;
  double transmitterWidth = 50;
  double magnetWidth = 22;
  double imagesSpacing = 10;
  double totalWidth;
  double _opacity = 1;
  bool go = false;
  String _labelText = "PIN";
  Color _labelTextColor = Colors.black;
  bool _isButtonDisabled = false;
  String _firstPin;

  final String oldPIN = "Inserisci il vecchio PIN";
  final String newPIN = "Inserisci il nuovo PIN";
  final String confirmPIN = "Conferma il nuovo PIN";
  String _pinText;

  @override
  void initState() {
    super.initState();
    _pinText = oldPIN;
    _focus.addListener(_onFocusChange);
    KeyboardVisibilityNotification().addNewListener(
      onHide: () {
        FocusScope.of(context).requestFocus(new FocusNode());
      },
    );
    var subscription = TcpHandler.getMessageStreamSubscription();
    subscription.onData((message) {
      switch (message) {
        case Message.pinCheckSuccess:
          _updateState();
          break;
        case Message.pinCheckFailed:
          setState(() {
            _labelText = "PIN inserito non valido!";
            _labelTextColor = Colors.red;
            myController.clear();
          });
          break;
        case Message.updatePinFailed:
          print("UPDATE FAIL");
          showAlertDialog(context, "Modifica PIN fallita!",
              "Errore non previsto, sarai reindirizzato verso la pagina principale.",
              (v) {
            Navigator.popUntil(
                context, (route) => route.settings.name == MyHomePage.id);
            return v;
          });
          subscription.cancel();
          break;
        case Message.updatePinSuccess:
          showAlertDialog(context, "Modifica PIN avvenuta con successo!",
              "Sarai reindirizzato verso la pagina principale.", (v) {
            Navigator.popUntil(
                context, (route) => route.settings.name == MyHomePage.id);
            return v;
          });
          subscription.cancel();
          break;
      }
    });
  }

  void _onFocusChange() {
    setState(() {
      _opacity = 1 - _opacity;
    });
  }

  Future<bool> _onBackPressed() async {
    print("Pin Update abort");
    TcpHandler.sendMessage(Message.abort);
    Navigator.popUntil(context, (route) {
      return route.settings.name == MyHomePage.id;
    });
    return false;
  }

  @override
  void dispose() {
    myController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: _onBackPressed,
        child: GestureDetector(
            onTap: () {
              FocusScope.of(context).requestFocus(new FocusNode());
            },
            child: Scaffold(
                appBar: AppBar(
                  title: Text("Modifica PIN"),
                ),
                backgroundColor: Colors.grey[200],
                body: Stack(
                  children: <Widget>[
                    Builder(builder: (context) {
                      return Container(
                          height: MediaQuery.of(context).size.height -
                              Scaffold.of(context).appBarMaxHeight,
                          width: MediaQuery.of(context).size.width);
                    }),
                    Builder(builder: (context) {
                      return Positioned(
                          top: (MediaQuery.of(context).size.height -
                                  Scaffold.of(context).appBarMaxHeight) /
                              4,
                          left: (MediaQuery.of(context).size.width -
                                  (MediaQuery.of(context).size.width / 1.2)) /
                              2,
                          child: Container(
                              width: MediaQuery.of(context).size.width / 1.2,
                              child: Opacity(
                                  opacity: _opacity,
                                  child: Text(_pinText,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.normal,
                                          color: Colors.black87)))));
                    }),
                    Builder(builder: (context) {
                      return Center(
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: <Widget>[
                            Container(
                                width:
                                    (MediaQuery.of(context).size.width / 1.2) -
                                        60,
                                //color: Colors.white,
                                child: TextField(
                                  maxLength: 8,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                        RegExp(r'[0-9]')),
                                  ],
                                  decoration: InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(
                                          vertical: 17.0, horizontal: 10.0),
                                      fillColor: Colors.white,
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Colors.black, width: 1.0),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: Colors.black, width: 1.0),
                                      ),
                                      labelText: _labelText,
                                      labelStyle:
                                          TextStyle(color: _labelTextColor)),
                                  controller: myController,
                                  onSubmitted: (text) => sendPIN(text),
                                  focusNode: _focus,
                                )),
                            Container(
                                height: 34.0 + 17.0 + 2.0,
                                child: FlatButton(
                                  onPressed: () {
                                    if (!_isButtonDisabled)
                                      sendPIN(myController.text);
                                  },
                                  color: Color(0xff3786ff),
                                  child: Icon(Icons.send, color: Colors.white),
                                ))
                          ]));
                    }),
                  ],
                ))));
  }

  void sendPIN(String pin) {
    if (pin.contains(Message.eom[0]) ||
        pin.contains(";") ||
        pin.isEmpty ||
        pin.length < 5) {
      setState(() {
        _labelText = pin.length < 5
            ? "PIN troppo corto (minimo 5 cifre)"
            : "PIN inserito non valido!";
        _labelTextColor = Colors.red;
        myController.clear();
      });
      return;
    }

    if (_pinText == oldPIN)
      TcpHandler.sendMessage(Message.string + pin);
    else if (_pinText == newPIN) {
      _firstPin = pin;
      _updateState();
    } else if (_pinText == confirmPIN) {
      if (pin != _firstPin) {
        setState(() {
          _labelText = "Il PIN inserito non corrisponde al precedente!";
          _labelTextColor = Colors.red;
          myController.clear();
          _isButtonDisabled = false;
        });
      } else {
        TcpHandler.sendMessage(Message.string + pin);
        _updateState();
      }
    }
  }

  void _updateState() {
    setState(() {
      _focus.unfocus();
      if (_pinText == confirmPIN) _isButtonDisabled = true;
      _pinText = _pinText == oldPIN ? newPIN : confirmPIN;
      _labelText = "PIN";
      _labelTextColor = Colors.black;
      myController.clear();
    });
  }
}
