import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;

class PaymentScreen extends StatefulWidget {
  final int subscriptionTypeId;
  final String userId; // userId parameter
  final String description;
  final int amount;

  const PaymentScreen({
    super.key,
    required this.subscriptionTypeId,
    required this.userId, // userId parameter
    required this.description,
    required this.amount,
  });

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isLoading = false;
  String _publishableKey = '';

  @override
  void initState() {
    super.initState();
    _fetchAndInitializeStripe();
  }

  Future<void> _fetchAndInitializeStripe() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _publishableKey = await _fetchPublishableKey();
      Stripe.publishableKey = _publishableKey;
      await _makePayment();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error initializing Stripe: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String> _fetchPublishableKey() async {
    final response = await http.get(Uri.parse('https://api.lokivpn.com/api/stripe/publishable-key'));
    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      return responseBody['publishableKey'];
    } else {
      throw Exception('Failed to fetch publishable key');
    }
  }

  Future<void> _makePayment() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final paymentIntent = await _createPaymentIntent(widget.amount, 'usd');
      final paymentIntentClientSecret = paymentIntent['clientSecret'];

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentClientSecret,
          style: ThemeMode.system,
          merchantDisplayName: 'Appmontize Media',
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Payment successful!')));

      // Navigate to profile page after successful payment
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ProfilePage()), // Ensure you have a ProfilePage
      );
    } catch (e) {
      if (e is StripeException) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error from Stripe: ${e.error.localizedMessage}')),
        );
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Unknown error: $e')));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> _createPaymentIntent(int amount, String currency) async {
    final response = await http.post(
      Uri.parse('https://api.lokivpn.com/api/stripe/create-order'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'amount': amount,
        'currency': currency,
        'description': widget.description,
        'userID': widget.userId,
        'SubscriptionTypeID': widget.subscriptionTypeId,
      }),
    );

    return jsonDecode(response.body);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subscription Details',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),
            Text('Description: ${widget.description}'),
            Text('Amount: \$${widget.amount / 100}'),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _makePayment,
                child: Text('Pay \$${widget.amount / 100}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Assuming you have a ProfilePage widget
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child: Text('Welcome to your profile!'),
      ),
    );
  }
}
