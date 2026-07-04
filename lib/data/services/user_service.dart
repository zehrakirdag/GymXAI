import 'dart:convert';
import 'package:http/http.dart' as http;

class UserService {
  static const String baseUrl = 'http://172.20.10.3:5000';

  Future<void> createClient({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required String gender,
    String? birthDate,
    double? height,
    double? startWeight,
    double? targetWeight,
    String? goal,
    String? activityLevel,
    String? healthNotes,
    String? injuryNotes,
  }) async {
    final url = Uri.parse('$baseUrl/api/users/create');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fullName': fullName,
        'email': email,
        'password': password,
        'phone': phone,
        'role': 'CLIENT',
        'gender': gender,
        'birthDate': birthDate,
        'height': height,
        'startWeight': startWeight,
        'targetWeight': targetWeight,
        'goal': goal,
        'activityLevel': activityLevel,
        'healthNotes': healthNotes,
        'injuryNotes': injuryNotes,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 201) {
      throw Exception(data['message'] ?? 'Danışan oluşturulamadı');
    }
  }

  Future<List<Map<String, dynamic>>> getClients() async {
    final url = Uri.parse('$baseUrl/api/users/clients');

    final response = await http.get(url);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception(data['message'] ?? 'Danışanlar alınamadı');
    }
  }

  Future<void> updateClient({
    required int id,
    required String fullName,
    required String email,
    required String phone,
    required String gender,
    String? birthDate,
    double? height,
    double? startWeight,
    double? targetWeight,
    String? goal,
    String? activityLevel,
    String? healthNotes,
    String? injuryNotes,
  }) async {
    final url = Uri.parse('$baseUrl/api/users/$id');

    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'gender': gender,
        'birthDate': birthDate,
        'height': height,
        'startWeight': startWeight,
        'targetWeight': targetWeight,
        'goal': goal,
        'activityLevel': activityLevel,
        'healthNotes': healthNotes,
        'injuryNotes': injuryNotes,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Danışan güncellenemedi');
    }
  }

  Future<void> createTrainer({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required String specialty,
    required String bio,
    required bool isAvailable,
  }) async {
    final url = Uri.parse('$baseUrl/api/users/create');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fullName': fullName,
        'email': email,
        'password': password,
        'phone': phone,
        'role': 'TRAINER',
        'specialty': specialty,
        'bio': bio,
        'isAvailable': isAvailable,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 201) {
      throw Exception(data['message'] ?? 'Antrenör oluşturulamadı');
    }
  }

  Future<List<Map<String, dynamic>>> getTrainers() async {
    final url = Uri.parse('$baseUrl/api/users/trainers');

    final response = await http.get(url);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception(data['message'] ?? 'Antrenörler alınamadı');
    }
  }

  Future<void> updateTrainer({
    required int id,
    required String fullName,
    required String email,
    required String phone,
    required String specialty,
    required String bio,
    required bool isAvailable,
  }) async {
    final url = Uri.parse('$baseUrl/api/users/trainer/$id');

    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'specialty': specialty,
        'bio': bio,
        'isAvailable': isAvailable,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Antrenör güncellenemedi');
    }
  }

  Future<void> deleteTrainer(int id) async {
    final url = Uri.parse('$baseUrl/api/users/trainer/$id');

    final response = await http.delete(url);
    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Antrenör silinemedi');
    }
  }

  Future<void> assignTrainer({
    required int clientId,
    required int? trainerId,
  }) async {
    final url = Uri.parse('$baseUrl/api/users/assign-trainer/$clientId');

    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'trainerId': trainerId}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Atama başarısız');
    }
  }
}