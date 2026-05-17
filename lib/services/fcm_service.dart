import 'package:firebase_messaging/firebase_messaging.dart';

class FcmService {
  static final _fcm = FirebaseMessaging.instance;
  static String? _token;

  static Future<void> init() async {
    await _fcm.requestPermission(alert: true, badge: true, sound: true);
    _token = await _fcm.getToken();
    FirebaseMessaging.onMessage.listen((_) {});
  }

  static String? get token => _token;
}
