import 'dart:convert';
import 'package:http/http.dart' as http;

class MeasurementService {
  static const String baseUrl = 'http://172.20.10.3:5000';

  Future<void> createMeasurement({
    required int clientId,
    required double weight,
    double? bodyFat,
    double? height,
    double? bmi,
    double? waist,
    double? hip,
    double? shoulder,
    double? arm,
    double? leg,
    double? calf,
    String? note,
  }) async {
    final url = Uri.parse('$baseUrl/api/measurements/create');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'clientId': clientId,
        'weight': weight,
        'bodyFat': bodyFat,
        'height': height,
        'bmi': bmi,
        'waist': waist,
        'hip': hip,
        'shoulder': shoulder,
        'arm': arm,
        'leg': leg,
        'calf': calf,
        'note': note,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 201) {
      throw Exception(data['message'] ?? 'Ölçüm eklenemedi');
    }
  }

  Future<List<Map<String, dynamic>>> getMeasurements({
    required int clientId,
  }) async {
    final url = Uri.parse('$baseUrl/api/measurements/client/$clientId');

    final response = await http.get(url);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception(data['message'] ?? 'Ölçümler alınamadı');
    }
  }
}