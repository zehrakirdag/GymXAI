import 'dart:convert';
import 'package:http/http.dart' as http;

class ClientService {
  static const String baseUrl = 'http://172.20.10.3:5000';

  Future<Map<String, dynamic>> getProfile({
    required int clientUserId,
  }) async {
    final url = Uri.parse(
      '$baseUrl/api/client/$clientUserId/profile',
    );

    final response = await http.get(url);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data);
    } else {
      throw Exception(
        data['message'] ?? 'Client profili alınamadı',
      );
    }
  }

  Future<Map<String, dynamic>> getAnalytics({
    required int clientId,
  }) async {
    final url = Uri.parse(
      '$baseUrl/api/client/$clientId/analytics',
    );

    final response = await http.get(url);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data);
    } else {
      throw Exception(
        data['message'] ?? 'Analiz verileri alınamadı',
      );
    }
  }

  Future<List<Map<String, dynamic>>> getTrainers() async {
    final url = Uri.parse(
      '$baseUrl/api/client/trainers/all',
    );

    final response = await http.get(url);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception(
        data['message'] ?? 'Antrenörler alınamadı',
      );
    }
  }

  Future<Map<String, dynamic>> getTrainerDetail({
    required int trainerId,
  }) async {
    final url = Uri.parse(
      '$baseUrl/api/client/trainers/$trainerId',
    );

    final response = await http.get(url);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(data);
    } else {
      throw Exception(
        data['message'] ?? 'Antrenör profili alınamadı',
      );
    }
  }

  Future<List<Map<String, dynamic>>> getAvailableSlots({
    required int trainerId,
    required String date,
  }) async {
    final url = Uri.parse(
      '$baseUrl/api/client/trainers/$trainerId/available-slots?date=$date',
    );

    final response = await http.get(url);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception(
        data['message'] ?? 'Uygun saatler alınamadı',
      );
    }
  }

  Future<void> createAppointment({
    required int clientId,
    required int trainerId,
    required String date,
    required String startTime,
    required String endTime,
    String? note,
  }) async {
    final url = Uri.parse(
      '$baseUrl/api/client/appointments',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'clientId': clientId,
        'trainerId': trainerId,
        'date': date,
        'startTime': startTime,
        'endTime': endTime,
        'note': note,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 201) {
      throw Exception(
        data['message'] ?? 'Randevu oluşturulamadı',
      );
    }
  }

  Future<void> completeWorkout({
    required int clientId,
    required int dayId,
  }) async {
    final url = Uri.parse(
      '$baseUrl/api/client/complete-workout',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'clientId': clientId,
        'dayId': dayId,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 201) {
      throw Exception(
        data['message'] ?? 'Antrenman tamamlanamadı',
      );
    }
  }

  Future<void> completeExercise({
    required int clientId,
    required int exerciseId,
    required bool isCompleted,
    double? weight,
  }) async {
    final url = Uri.parse(
      '$baseUrl/api/client/complete-exercise',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'clientId': clientId,
        'exerciseId': exerciseId,
        'isCompleted': isCompleted,
        'weight': weight,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 201) {
      throw Exception(
        data['message'] ?? 'Egzersiz tamamlanamadı',
      );
    }
  }

  Future<void> completeSet({
    required int clientId,
    required int exerciseId,
    required int setNumber,
    required bool isCompleted,
    double? weight,
  }) async {
    final url = Uri.parse(
      '$baseUrl/api/client/complete-set',
    );

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'clientId': clientId,
        'exerciseId': exerciseId,
        'setNumber': setNumber,
        'isCompleted': isCompleted,
        'weight': weight,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 201) {
      throw Exception(
        data['message'] ?? 'Set güncellenemedi',
      );
    }
  }
}