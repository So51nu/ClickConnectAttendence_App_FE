import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'token_service.dart';

class AuthService {

  // REGISTER
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
        "email": email,
        "password": password,
        "full_name": fullName,
        "phone": phone,
      }),
    );

    if (res.statusCode != 201) {
      throw Exception(jsonDecode(res.body)["detail"] ?? "Register failed");
    }
  }

  // VERIFY OTP
  static Future<void> verifyOtp(String email, String otp) async {
    final res = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/api/auth/verify-otp/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "otp": otp}),
    );

    if (res.statusCode != 200) {
      throw Exception(jsonDecode(res.body)["otp"] ?? "OTP failed");
    }
  }

  // RESEND OTP
  static Future<void> resendOtp(String email) async {
    final res = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/api/auth/resend-otp/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );

    if (res.statusCode != 200) {
      throw Exception("Resend OTP failed");
    }
  }

  // LOGIN
  static Future<void> login(String email, String password) async {
    final res = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/api/auth/login/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "password": password}),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      await TokenService.saveTokens(data["access"], data["refresh"]);
    } else {
      throw Exception("Login failed");
    }
  }

  // ME
  static Future<Map<String, dynamic>> me() async {
    final token = await TokenService.getAccessToken();

    final res = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/api/auth/me/"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    } else {
      throw Exception("Unauthorized");
    }
  }

  // REFRESH TOKEN
  static Future<void> refreshToken() async {
    final refresh = await TokenService.getRefreshToken();

    final res = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/api/auth/refresh/"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"refresh": refresh}),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      await TokenService.saveTokens(data["access"], refresh!);
    }
  }
}
