import 'dart:convert';
import 'package:http/http.dart' as http;

class ServerService {
  final String baseUrl;

  ServerService({required this.baseUrl});

  Future<List<dynamic>> getAllServers() async {
    final response = await http.get(Uri.parse('$baseUrl/api/servers'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch servers');
    }
  }
}
