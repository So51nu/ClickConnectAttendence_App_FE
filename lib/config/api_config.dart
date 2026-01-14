class ApiConfig {
  static const String baseUrl = "http://192.168.1.6:8000";

  // Admin
  static String adminOffices() => "$baseUrl/api/admin/offices/";
  static String adminOfficeUpdate(int id) => "$baseUrl/api/admin/offices/$id/";
  static String adminGenerateQr(int id) => "$baseUrl/api/admin/offices/$id/generate-qr/";
  static String adminGetQr(int id) => "$baseUrl/api/admin/offices/$id/qr/";
}


