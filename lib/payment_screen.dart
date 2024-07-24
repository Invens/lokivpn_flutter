import 'package:flutter/material.dart';
import 'package:amp_vpn/services/payment_service.dart';

class PaymentScreen extends StatefulWidget {
  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PaymentService _paymentService = PaymentService(baseUrl: 'http://your-backend-url.com');
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  Future<void> _createOrder() async {
    int amount = int.parse(_amountController.text);
    String description = _descriptionController.text;

    try {
      var response = await _paymentService.createOrder(amount, 'usd', description);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order created successfully: ${response['clientSecret']}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create order: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Payment')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _amountController,
              decoration: InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _createOrder,
              child: Text('Create Order'),
            ),
          ],
        ),
      ),
    );
  }
}
