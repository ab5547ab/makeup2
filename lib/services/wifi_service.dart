import 'package:flutter/services.dart';

/// גשר (Method Channel) לקוד האנדרואיד הנייטיבי, המאפשר חיבור לרשת Wi-Fi
/// ספציפית לפני ביצוע סנכרון - שימושי כשהסטודיו עובד מול נתב ייעודי.
/// דורש אנדרואיד 10 (API 29) ומעלה.
class WifiService {
  static const platform = MethodChannel('com.mua.studiocalendar/wifi');

  static Future<bool> connectAndSync({
    required String ssid,
    required String password,
  }) async {
    if (ssid.trim().isEmpty) return false;
    try {
      final String result = await platform.invokeMethod('connectAndSync', {
        'ssid': ssid,
        'password': password,
      });
      return result == 'CONNECTED';
    } on PlatformException {
      return false;
    }
  }
}
