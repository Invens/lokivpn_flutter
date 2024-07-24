import 'dart:convert';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class GuestUserService {
  final String baseUrl;

  GuestUserService({required this.baseUrl});

  Future<Map<String, dynamic>> registerOrLoginGuest() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final deviceID = androidInfo.fingerprint;

    final response = await http.post(
      Uri.parse('$baseUrl/api/guests/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'DeviceID': deviceID}),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', responseBody['token']);
      return responseBody;
    } else {
      throw Exception('Failed to register or login guest');
    }
  }

  Future<Map<String, dynamic>> getGuestUserDetails(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/guests/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch guest user details');
    }
  }

  Future<void> promoteToRegisteredUser(String name, String email, String password) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    if (token == null) throw Exception('No token found');

    final response = await http.post(
      Uri.parse('$baseUrl/api/users/promote-guest'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'Name': name,
        'Email': email,
        'Password': password,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      var responseBody = jsonDecode(response.body);
      await prefs.setString('token', responseBody['token']);
      await prefs.setString('userID', responseBody['user']['UserID'].toString());
    } else {
      throw Exception('Failed to promote guest to registered user');
    }
  }
}
