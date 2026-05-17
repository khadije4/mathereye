import 'package:shared_preferences/shared_preferences.dart';

class PrefsService {
  static Future<String?> getChildId() async =>
      (await SharedPreferences.getInstance()).getString('child_id');

  static Future<void> setChildId(String id) async =>
      (await SharedPreferences.getInstance()).setString('child_id', id);

  static Future<String?> getPairedChildId() async =>
      (await SharedPreferences.getInstance()).getString('paired_child_id');

  static Future<void> setPairedChildId(String id) async =>
      (await SharedPreferences.getInstance()).setString('paired_child_id', id);

  static Future<String?> getPin() async =>
      (await SharedPreferences.getInstance()).getString('parent_pin');

  static Future<void> setPin(String pin) async =>
      (await SharedPreferences.getInstance()).setString('parent_pin', pin);

  static Future<void> clearChildData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('child_id');
  }

  static Future<void> clearParentData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('paired_child_id');
  }
}
