import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenService {
  static const _storage = FlutterSecureStorage();

  static const _access = "access_token";
  static const _refresh = "refresh_token";

  static Future<void> saveTokens(String access, String refresh) async {
    await _storage.write(key: _access, value: access);
    await _storage.write(key: _refresh, value: refresh);
  }

  static Future<String?> getAccessToken() async {
    return _storage.read(key: _access);
  }

  static Future<String?> getRefreshToken() async {
    return _storage.read(key: _refresh);
  }

  static Future<void> clear() async {
    await _storage.deleteAll();
  }
}
