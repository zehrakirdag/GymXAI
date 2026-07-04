import 'dart:convert';
import 'package:http/http.dart' as http;

class ProgramService {
  static const String baseUrl = 'http://172.20.10.3:5000';

  Future<List<Map<String, dynamic>>> getClientPrograms({
    required int clientProfileId,
  }) async {
    final url = Uri.parse('$baseUrl/api/program/client/$clientProfileId');

    final response = await http.get(url);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception(data['message'] ?? 'Programlar alınamadı');
    }
  }

  Future<void> createProgram({
    required int clientProfileId,
    required String title,
    required String description,
    required List<Map<String, dynamic>> days,
  }) async {
    final url = Uri.parse('$baseUrl/api/program/create');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'clientId': clientProfileId,
        'title': title,
        'description': description,
        'days': days,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 201) {
      throw Exception(data['message'] ?? 'Program oluşturulamadı');
    }
  }

  Future<void> updateProgram({
    required int programId,
    required String title,
    required String description,
    required List<Map<String, dynamic>> days,
  }) async {
    final url = Uri.parse('$baseUrl/api/program/$programId/full-update');

    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'description': description,
        'days': days,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Program güncellenemedi');
    }
  }
}