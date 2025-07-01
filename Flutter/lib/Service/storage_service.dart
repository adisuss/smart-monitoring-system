import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static Future<void> saveUserData({
    required String uid,
    required String email,
    required String fcmToken,
    required String apiKey,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('uid', uid);
    await prefs.setString('email', email);
    await prefs.setString('fcmToken', fcmToken);
    await prefs.setString('apiKey', apiKey);
  }

  static Future<Map<String, String?>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'uid': prefs.getString('uid'),
      'email': prefs.getString('email'),
      'fcmToken': prefs.getString('fcmToken'),
      'apiKey': prefs.getString('apiKey'),
    };
  }
}
