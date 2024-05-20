import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<int?> getSubtitleValue(String subtitleKey) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getInt(subtitleKey);
}

List<Color> subtitleBackgroundColors = [
  Colors.transparent,
  Colors.black,
  Colors.white,
  Colors.red,
  Colors.green,
  Colors.blue,
  Colors.yellow,
  Colors.orange,
  Colors.brown,
  Colors.purple,
  Colors.pink,
  Colors.teal
];

List<Color> subtitleTextColors = [
  Colors.black,
  Colors.white,
  Colors.red,
  Colors.green,
  Colors.blue,
  Colors.yellow,
  Colors.orange,
  Colors.brown,
  Colors.purple,
  Colors.pink,
  Colors.teal
];
