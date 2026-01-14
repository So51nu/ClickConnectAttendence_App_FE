import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'token_service.dart';
import 'auth_service.dart';

class AttendanceService {
  static Future<Map<String, String>> _headers() async {
    final token = await TokenService.getAccessToken();
    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  static Future<dynamic> mark({
    required String action, // CHECKIN / CHECKOUT
    required String qrToken,
    required double lat,
    required double lng,
    required double accuracyM,
  }) async {
    Future<http.Response> doCall() async {
      return http.post(
        Uri.parse("${ApiConfig.baseUrl}/api/attendance/mark/"),
        headers: await _headers(),
        body: jsonEncode({
          "action": action,
          "qr_token": qrToken,
          "lat": lat,
          "lng": lng,
          "accuracy_m": accuracyM,
        }),
      );
    }

    var res = await doCall();

    if (res.statusCode == 401) {
      await AuthService.refreshToken();
      res = await doCall();
    }

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }

    try {
      final data = jsonDecode(res.body);
      if (data is Map && data["detail"] != null) throw Exception(data["detail"].toString());
      throw Exception("Attendance failed (${res.statusCode})");
    } catch (_) {
      throw Exception("Attendance failed (${res.statusCode})");
    }
  }

  static Future<List<dynamic>> myAttendance({String? from, String? to}) async {
    final qp = <String, String>{};
    if (from != null && from.isNotEmpty) qp["from"] = from;
    if (to != null && to.isNotEmpty) qp["to"] = to;

    Uri uri = Uri.parse("${ApiConfig.baseUrl}/api/attendance/me/").replace(queryParameters: qp.isEmpty ? null : qp);

    Future<http.Response> doCall() async {
      return http.get(uri, headers: await _headers());
    }

    var res = await doCall();
    if (res.statusCode == 401) {
      await AuthService.refreshToken();
      res = await doCall();
    }

    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List<dynamic>;
    }

    throw Exception("Failed to load attendance (${res.statusCode})");
  }
}
