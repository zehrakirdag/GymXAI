import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/login_response_model.dart';

class AuthService {
  // Android emulator kullanıyorsan bunu kullan:

  static const String baseUrl = 'http://localhost:50550';


  Future<LoginResponseModel> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/api/auth/login');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return LoginResponseModel.fromJson(data);
    } else {
      throw Exception(data['message'] ?? 'Giriş başarısız');
    }
  }
}