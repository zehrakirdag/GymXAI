import 'dart:convert';
import 'package:http/http.dart' as http;

class AIService {
  static const String baseUrl = "http://172.20.10.3:5000/api/ai";

  Future<Map<String, dynamic>> requestAIProgram(int clientProfileId) async {
    final response = await http.post(
      Uri.parse("$baseUrl/request-program/$clientProfileId"),
      headers: {
        "Content-Type": "application/json",
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return data;
    } else {
      throw Exception(data["message"] ?? "AI program talebi oluşturulamadı");
    }
  }

  Future<List<dynamic>> getTrainerAIRequests(int trainerProfileId) async {
    final response = await http.get(
      Uri.parse("$baseUrl/trainer/$trainerProfileId/requests"),
      headers: {
        "Content-Type": "application/json",
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data["message"] ?? "AI program talepleri alınamadı");
    }
  }

  Future<Map<String, dynamic>> updateAIRequestStatus({
    required int requestId,
    required String status,
    String? trainerNote,
  }) async {
    final response = await http.put(
      Uri.parse("$baseUrl/requests/$requestId/status"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "status": status,
        "trainerNote": trainerNote,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return data;
    } else {
      throw Exception(data["message"] ?? "AI program talebi güncellenemedi");
    }
  }
}