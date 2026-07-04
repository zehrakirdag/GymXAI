import 'dart:convert';
import 'package:http/http.dart' as http;

class TrainerService {
  static const String baseUrl = 'http://172.20.10.3:5000';

  Future<List<Map<String, dynamic>>> getMyClients({
    required int trainerUserId,
  }) async {
    final url = Uri.parse('$baseUrl/api/trainer/$trainerUserId/clients');

    final response = await http.get(url);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception(data['message'] ?? 'Danışanlar alınamadı');
    }
  }

  Future<List<Map<String, dynamic>>> getTodayAppointments({
    required int trainerUserId,
  }) async {
    final url = Uri.parse('$baseUrl/api/trainer/$trainerUserId/appointments');

    final response = await http.get(url);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception(data['message'] ?? 'Randevular alınamadı');
    }
  }

  Future<int> getTrainerProfileId({
    required int trainerUserId,
  }) async {
    final url = Uri.parse('$baseUrl/api/trainer/$trainerUserId/profile');

    final response = await http.get(url);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data["id"] != null) {
      return data["id"];
    } else {
      throw Exception(data["message"] ?? "Trainer profile id bulunamadı");
    }
  }

  Future<void> updateAppointmentStatus({
    required int appointmentId,
    required String status,
    String? cancelReason,
  }) async {
    final url = Uri.parse(
      '$baseUrl/api/trainer/appointments/$appointmentId/status',
    );

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'status': status,
        if (cancelReason != null) 'cancelReason': cancelReason,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Randevu durumu güncellenemedi');
    }
  }
}