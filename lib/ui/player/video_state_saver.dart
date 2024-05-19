import 'package:shared_preferences/shared_preferences.dart';

class VideoStateSaver {
  static SharedPreferences? prefs;
  static Future<bool> saveVideoState(int position, String key) async {
    prefs = await SharedPreferences.getInstance();
    prefs!.setInt(key, position);
    return true;
  }

  static Future<int?> getVideoState({required String key}) async {
    prefs = await SharedPreferences.getInstance();

    int? val = prefs!.getInt(key);
    print(val);
    return val;
  }
}
