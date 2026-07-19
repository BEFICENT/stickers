import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:stickers/src/data/pack_store.dart';
import 'package:stickers/src/settings/settings_controller.dart';

late PackStore packs;
final navigatorKey = GlobalKey<NavigatorState>();
late SettingsController settingsController;

PackageInfo? info;

final List<Color> colors = [
  Colors.pink,
  Colors.red,
  Colors.deepOrange,
  Colors.amber,
  Colors.yellow,
  Colors.lime,
  Colors.lightGreen,
  Colors.blueGrey,
  Colors.white,
  Colors.purple,
  Colors.deepPurple,
  Colors.indigo,
  Colors.blue,
  Colors.cyan,
  Colors.teal,
  Colors.green,
  Colors.brown,
  Colors.black,
  Colors.transparent,
];
