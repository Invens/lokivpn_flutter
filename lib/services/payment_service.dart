import 'dart:convert';
import 'package:http/http.dart' as http;

class PaymentService {
  final String baseUrl;

  PaymentService({required this.baseUrl});

  Future<Map<String, dynamic>> createOrder(int amount, String currency, String description) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/create-order'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'amount': amount,
        'currency': currency,
        'description': description,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to create order');
    }
  }
}
