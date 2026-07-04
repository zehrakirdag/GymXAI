import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationService {
  static const String baseUrl = 'http://172.20.10.3:5000';

  Future<List<Map<String, dynamic>>> getNotifications({
    required int userId,
  }) async {
    final url = Uri.parse('$baseUrl/api/notifications/$userId');

    final response = await http.get(url);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception(data['message'] ?? 'Bildirimler alınamadı');
    }
  }

  Future<void> markAsRead({
    required int notificationId,
  }) async {
    final url = Uri.parse(
      '$baseUrl/api/notifications/$notificationId/read',
    );

    final response = await http.put(url);
    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Bildirim okundu yapılamadı');
    }
  }

  Future<void> markAllAsRead({
    required int userId,
  }) async {
    final url = Uri.parse(
      '$baseUrl/api/notifications/$userId/read-all',
    );

    final response = await http.put(url);
    final data = jsonDecode(response.body);

    if (response.statusCode != 200) {
      throw Exception(data['message'] ?? 'Bildirimler okundu yapılamadı');
    }
  }
}