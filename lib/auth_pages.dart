import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';

import 'package:home_security_project_app/main.dart';
import 'package:keyboard_visibility/keyboard_visibility.dart';

class PinUpdatePage extends StatefulWidget {
  static const String id = 'pin_update';
  PinUpdatePage() : super();

  @override
  _PinUpdateState createState() => _PinUpdateState();
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
  String labelText = "PIN";
  Color labelTextColor = Colors.black;
  bool _isButtonDisabled = false;

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
  }

  void _onFocusChange() {
    setState(() {
      _opacity = 1 - _opacity;
    });
  }

  Future<bool> _onBackPressed() async {
    Navigator.popUntil(context, (route) {
      print(route.settings.name);
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
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: <Widget>[
                            Container(
                                width:
                                    (MediaQuery.of(context).size.width / 1.2) -
                                        60,
                                //color: Colors.white,
                                child: TextField(
                                  maxLength: 5,
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
                                      labelText: labelText,
                                      labelStyle:
                                          TextStyle(color: labelTextColor)),
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
        pin.length >= 512 - Message.eom.length) {
      setState(() {
        labelText = "PIN inserito non valido!";
        labelTextColor = Colors.red;
        myController.clear();
      });
      return;
    }

    if (_pinText == oldPIN) {
      //send pin request
      //widget.socket.add(utf8.encode(Message.pinRequest + Message.eom));
      //receive pin
      StreamSubscription<Uint8List> subscription;
      /*
      subscription = widget.socketStream.listen((data) {
        print(utf8.decode(data));
        String message = utf8.decode(data);
        if (message.contains(Message.eom)) {
          if (message.substring(0, message.indexOf(Message.eom)) ==
              Message.pinRequestSuccess)
            message = message.substring(
                Message.pinRequestSuccess.length + Message.eom.length,
                message.length - Message.eom.length);
          else if (message != pin) {
            setState(() {
              labelText = "PIN inserito non valido!";
              labelTextColor = Colors.red;
              myController.clear();
            });
            subscription.cancel();
            return;
          }
        }
        subscription.cancel();
      });*/
    }
  }

  void _updateState() {
    setState(() {
      _focus.unfocus();
      if (_pinText == confirmPIN) _isButtonDisabled = true;
      _pinText = _pinText == oldPIN ? newPIN : confirmPIN;
      myController.clear();
    });
  }
}

void f(String message, String data) {}
