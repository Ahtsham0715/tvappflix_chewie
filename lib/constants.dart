import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'dart:io';
extension DeviceTypeExtension on BuildContext {
  Future<bool> get isTV async {
    // final mediaQuery = MediaQuery.of(this);
    // final diagonalSize = sqrt((mediaQuery.size.width * mediaQuery.size.width) +
    //     (mediaQuery.size.height * mediaQuery.size.height));
    // final diagonalInInches = diagonalSize / mediaQuery.devicePixelRatio / 160;

    // return diagonalInInches > 40;
    if (!kIsWeb) {
      if(Platform.isIOS){
        return false;
      }else{
 final deviceInfoPlugin = DeviceInfoPlugin();
      final deviceInfo = await deviceInfoPlugin.deviceInfo;
      final allInfo = deviceInfo.data;

      List<Object?> sysFeatures = allInfo['systemFeatures'];
      return sysFeatures.contains('android.hardware.type.television');
      }
    } else {
      return true;
    }
  }

  Future<bool> get isMobile async {
    // final mediaQuery = MediaQuery.of(this);
    // final diagonalSize = sqrt((mediaQuery.size.width * mediaQuery.size.width) +
    //     (mediaQuery.size.height * mediaQuery.size.height));
    // final diagonalInInches = diagonalSize / mediaQuery.devicePixelRatio / 160;
    // return diagonalInInches < 7;
    return !await isTV;
  }

  bool get isPortrait {
    return MediaQuery.of(this).orientation == Orientation.portrait;
  }

  bool get isLandscape {
    return MediaQuery.of(this).orientation == Orientation.landscape;
  }
}

void showCustomSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: Duration(seconds: 5), // Duration the snackbar stays visible
      // backgroundColor: Colors.white, // Customize background color
    ),
  );
}

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
