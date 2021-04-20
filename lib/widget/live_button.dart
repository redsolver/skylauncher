import 'dart:async';

import 'package:flutter/material.dart';

class LiveButton extends StatefulWidget {
  final Function builder;
  final Duration refreshRate;

  LiveButton({
    this.builder,
    this.refreshRate,
  });

  @override
  _LiveButtonState createState() => _LiveButtonState();
}

class _LiveButtonState extends State<LiveButton> {
  StreamSubscription sub;
  @override
  void initState() {
    sub = Stream.periodic(widget.refreshRate).listen((event) async {
      _updateWidget();
    });
    _updateWidget();
    super.initState();
  }

  Widget theWidget;

  @override
  void dispose() {
    if (sub != null) sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return theWidget == null
        ? Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(),
                ),
                SizedBox(
                  height: 4,
                ),
                Text('Loading...'),
              ],
            ),
          )
        : theWidget;
  }

  void _updateWidget() async {
    // print('_updateWidget');
    theWidget = await widget.builder();
    if (mounted) setState(() {});
  }
}
