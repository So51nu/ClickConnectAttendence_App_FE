import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'token_service.dart';
import 'auth_service.dart';

class AdminOfficeService {
  static Future<Map<String, String>> _headers() async {
    final token = await TokenService.getAccessToken();
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  static Future<http.Response> _safeGet(Uri url) async {
    var res = await http.get(url, headers: await _headers());
    if (res.statusCode == 401) {
      await AuthService.refreshToken();
      res = await http.get(url, headers: await _headers());
    }
    return res;
  }

  static Future<http.Response> _safePost(Uri url, {Object? body}) async {
    var res = await http.post(url, headers: await _headers(), body: body);
    if (res.statusCode == 401) {
      await AuthService.refreshToken();
      res = await http.post(url, headers: await _headers(), body: body);
    }
    return res;
  }

  static Future<http.Response> _safePatch(Uri url, {Object? body}) async {
    var res = await http.patch(url, headers: await _headers(), body: body);
    if (res.statusCode == 401) {
      await AuthService.refreshToken();
      res = await http.patch(url, headers: await _headers(), body: body);
    }
    return res;
  }

  static Future<List<dynamic>> listOffices() async {
    final res = await _safeGet(Uri.parse(ApiConfig.adminOffices()));
    if (res.statusCode == 200) return jsonDecode(res.body) as List<dynamic>;
    throw Exception("Failed to load offices");
  }

  static Future<Map<String, dynamic>> createOffice({
    required String name,
    required String address,
    required double lat,
    required double lng,
    required int radiusM,
  }) async {
    final res = await _safePost(
      Uri.parse(ApiConfig.adminOffices()),
      body: jsonEncode({
        "name": name,
        "address": address,
        "latitude": lat,
        "longitude": lng,
        "allowed_radius_m": radiusM,
        "is_active": true,
      }),
    );

    if (res.statusCode == 201) return jsonDecode(res.body);
    throw Exception("Office create failed");
  }

  static Future<Map<String, dynamic>> updateOffice(int id, Map<String, dynamic> patch) async {
    final res = await _safePatch(
      Uri.parse(ApiConfig.adminOfficeUpdate(id)),
      body: jsonEncode(patch),
    );

    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("Office update failed");
  }

  static Future<Map<String, dynamic>> generateQr(int officeId) async {
    final res = await _safePost(Uri.parse(ApiConfig.adminGenerateQr(officeId)));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("QR generate failed");
  }

  static Future<Map<String, dynamic>> getQr(int officeId) async {
    final res = await _safeGet(Uri.parse(ApiConfig.adminGetQr(officeId)));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("QR not found");
  }
}
