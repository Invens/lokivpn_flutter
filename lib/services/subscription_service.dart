import 'dart:convert';
import 'package:http/http.dart' as http;

class SubscriptionService {
  final String baseUrl;

  SubscriptionService({required this.baseUrl});

  Future<List<dynamic>> getSubscriptionTypes() async {
    final response = await http.get(Uri.parse('$baseUrl/api/subscription-types'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch subscription types');
    }
  }

  Future<Map<String, dynamic>> upgradeSubscription(String token, int newSubscriptionID) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/upgrade-subscription'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'newSubscriptionID': newSubscriptionID}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to upgrade subscription');
    }
  }
}
