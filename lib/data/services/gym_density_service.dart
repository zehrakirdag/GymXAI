import 'dart:convert';
import 'package:http/http.dart' as http;

class GymDensityService {
  static const String baseUrl = 'http://172.20.10.3:5000/api/gym-density';

  Future<Map<String, dynamic>> getStatus() async {
    final response = await http.get(
      Uri.parse('$baseUrl/status'),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'Salon yoğunluğu alınamadı');
    }
  }

  Future<Map<String, dynamic>> scanQr({
    required int userId,
    required String qrCode,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/scan'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'userId': userId,
        'qrCode': qrCode,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data['message'] ?? 'QR işlemi yapılamadı');
    }
  }
}