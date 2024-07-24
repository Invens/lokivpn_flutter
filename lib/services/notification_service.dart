import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationService {
  final String baseUrl;

  NotificationService({required this.baseUrl});

  Future<List<dynamic>> getNotifications(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/notifications'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch notifications');
    }
  }
}
