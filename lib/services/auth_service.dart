// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import '../config/api_config.dart';
// import 'token_service.dart';
//
// class AuthService {
//   static String _extractError(http.Response res) {
//     try {
//       final data = jsonDecode(res.body);
//       if (data is Map) {
//         if (data["detail"] != null) return data["detail"].toString();
//         if (data["otp"] != null) return data["otp"].toString();
//         for (final v in data.values) {
//           if (v is List && v.isNotEmpty) return v.first.toString();
//           if (v is String) return v;
//         }
//       }
//       return "Request failed (${res.statusCode})";
//     } catch (_) {
//       return "Request failed (${res.statusCode})";
//     }
//   }
//
//   static Future<void> login(String email, String password) async {
//     final res = await http.post(
//       Uri.parse("${ApiConfig.baseUrl}/api/auth/login/"),
//       headers: {"Content-Type": "application/json"},
//       body: jsonEncode({"email": email, "password": password}),
//     );
//
//     if (res.statusCode == 200) {
//       final data = jsonDecode(res.body);
//       await TokenService.saveTokens(data["access"], data["refresh"]);
//     } else {
//       throw Exception(_extractError(res));
//     }
//   }
//
//   static Future<Map<String, dynamic>> me() async {
//     final token = await TokenService.getAccessToken();
//     if (token == null) throw Exception("No token. Please login.");
//
//     final res = await http.get(
//       Uri.parse("${ApiConfig.baseUrl}/api/auth/me/"),
//       headers: {"Authorization": "Bearer $token"},
//     );
//
//     if (res.statusCode == 200) {
//       return jsonDecode(res.body);
//     } else {
//       throw Exception(_extractError(res));
//     }
//   }
//
//   static bool isAdmin(Map<String, dynamic> me) {
//     // backend me is_staff / is_superuser aana chahiye
//     return (me["is_staff"] == true) || (me["is_superuser"] == true);
//   }
// }

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'token_service.dart';

class AuthService {
  static String _extractError(http.Response res) {
    try {
      final data = jsonDecode(res.body);
      if (data is Map) {
        if (data["detail"] != null) return data["detail"].toString();
        if (data["otp"] != null) return data["otp"].toString();
        if (data["message"] != null) return data["message"].toString();

        for (final v in data.values) {
          if (v is List && v.isNotEmpty) return v.first.toString();
          if (v is String) return v;
        }
      }
      return "Request failed (${res.statusCode})";
    } catch (_) {
      return "Request failed (${res.statusCode})";
    }
  }

  // ---------------------------
  // LOGIN
  // ---------------------------
  static Future<void> login(String email, String password) async {
    final res = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/api/auth/login/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email.trim(), "password": password}),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      await TokenService.saveTokens(data["access"], data["refresh"]);
      return;
    }

    throw Exception(_extractError(res));
  }

  // ---------------------------
  // REGISTER  (used in RegisterScreen)
  // ---------------------------
  static Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    final res = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/api/auth/register/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email.trim(),
        "password": password,
        "full_name": fullName.trim(),
        "phone": phone.trim(),
      }),
    );

    // many backends return 201/200
    if (res.statusCode == 201 || res.statusCode == 200) return;

    throw Exception(_extractError(res));
  }

  // ---------------------------
  // OTP VERIFY (used in OtpVerifyScreen)
  // ---------------------------
  static Future<void> verifyOtp(String email, String otp) async {
    final res = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/api/auth/verify-otp/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email.trim(),
        "otp": otp.trim(),
      }),
    );

    if (res.statusCode == 200) return;

    throw Exception(_extractError(res));
  }

  // ---------------------------
  // OTP RESEND (used in OtpVerifyScreen)
  // ---------------------------
  static Future<void> resendOtp(String email) async {
    final res = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/api/auth/resend-otp/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "email": email.trim(),
      }),
    );

    if (res.statusCode == 200) return;

    throw Exception(_extractError(res));
  }

  // ---------------------------
  // ME
  // ---------------------------
  static Future<Map<String, dynamic>> me() async {
    final token = await TokenService.getAccessToken();
    if (token == null) throw Exception("No token. Please login.");

    final res = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/api/auth/me/"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) return jsonDecode(res.body);

    throw Exception(_extractError(res));
  }

  // ---------------------------
  // REFRESH TOKEN (used in services)
  // tries /api/auth/token/refresh/ then fallback /api/auth/refresh/
  // ---------------------------
  static Future<void> refreshToken() async {
    final refresh = await TokenService.getRefreshToken();
    if (refresh == null) {
      await TokenService.clear();
      throw Exception("Session expired. Please login again.");
    }

    Future<http.Response> call(String path) {
      return http.post(
        Uri.parse("${ApiConfig.baseUrl}$path"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"refresh": refresh}),
      );
    }

    // Primary (common in JWT setups)
    var res = await call("/api/auth/token/refresh/");

    // Fallback if your backend uses different path
    if (res.statusCode == 404) {
      res = await call("/api/auth/refresh/");
    }

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);

      final newAccess = data["access"];
      final newRefresh = data["refresh"] ?? refresh;

      if (newAccess == null) {
        await TokenService.clear();
        throw Exception("Refresh failed: access token missing.");
      }

      await TokenService.saveTokens(newAccess, newRefresh);
      return;
    }

    // If refresh itself is invalid -> logout
    await TokenService.clear();
    throw Exception(_extractError(res));
  }

  static bool isAdmin(Map<String, dynamic> me) {
    return (me["is_staff"] == true) || (me["is_superuser"] == true);
  }
}
