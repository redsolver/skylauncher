import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
// import 'package:skylauncher/interfaces/homeassistant.dart';

const methodChannel = const MethodChannel('net.redsolver.skylauncher/native');

Box<int> appLaunchCountBox;
Box dataBox;

final services = Services();

class Services {
  // final homeAssistant = HomeAssistantService();
}
extension NavigatorExtension on BuildContext {
  NavigatorState get nav => Navigator.of(this);
}
