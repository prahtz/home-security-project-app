
import 'package:flutter/material.dart';

class AlarmIcon extends StatefulWidget {
  final bool alarmActive;
  final bool defensesActive;
  const AlarmIcon(this.alarmActive, this.defensesActive);
  @override
  _AlarmIconState createState() => _AlarmIconState();
}

class _AlarmIconState extends State<AlarmIcon>
    with SingleTickerProviderStateMixin {
  AnimationController _animationController;

  @override
  void initState() {
    _animationController = new AnimationController(vsync: this, duration: Duration(milliseconds: 500));
    _animationController.repeat(reverse: true);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Icon icon = Icon(
                  Icons.fiber_manual_record,
                  color: widget.alarmActive ? Colors.red[500] : Colors.green[500],
                );
    if(widget.defensesActive) {
      return FadeTransition(
        opacity: _animationController,
        child:icon
      );
    }
    return icon;
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}