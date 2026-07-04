import 'dart:convert';
import 'package:http/http.dart' as http;

class WorkingHoursService {
  static const String baseUrl = 'http://172.20.10.3:5000';

  Future<List<Map<String, dynamic>>> getWorkingHours({
    required int trainerUserId,
  }) async {
    final url = Uri.parse('$baseUrl/api/working-hours/$trainerUserId');
    final response = await http.get(url);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception(data['message'] ?? 'Çalışma saatleri alınamadı');
    }
  }

  Future<void> updateWorkingHour({
    required int id,
    required bool isAvailable,
    String? startTime,
    String? endTime,
    String? note,
  }) async {
    final url = Uri.parse('$baseUrl/api/working-hours/$id');

    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'isAvailable': isAvailable,
        'startTime': startTime,
        'endTime': endTime,
        'note': note,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Güncellenemedi');
    }
  }

  Future<void> addSpecialLesson({
    required int workingHourId,
    required int? clientId,
    required String startTime,
    required String endTime,
  }) async {
    final url =
    Uri.parse('$baseUrl/api/working-hours/$workingHourId/special-lessons');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'clientId': clientId,
        'startTime': startTime,
        'endTime': endTime,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 201) {
      throw Exception(data['message'] ?? 'Özel ders eklenemedi');
    }
  }

  Future<void> deleteSpecialLesson(int lessonId) async {
    final url = Uri.parse('$baseUrl/api/working-hours/special-lessons/$lessonId');

    final response = await http.delete(url);
    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Özel ders silinemedi');
    }
  }
}