import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'profile.dart'; // Ensure this import matches your file structure

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
        MaterialPageRoute(builder: (context) => const ProfileScreen()), // Ensure you have a ProfilePage
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
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/background_pattern.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SizedBox(height: 100),
                ClipRRect(
                  borderRadius: BorderRadius.circular(50.0),
                  child: Image.asset(
                    'assets/logo2.png',
                    height: 100,
                    width: 100,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: Colors.blueAccent,
                      width: 3.0,
                    ),
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Subscription Details',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Description: ${widget.description}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        'Amount: \$${(widget.amount / 100).toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton(
                          onPressed: _makePayment,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ).copyWith(
                            backgroundColor: MaterialStateProperty.resolveWith((states) {
                              return Colors.transparent;
                            }),
                            elevation: MaterialStateProperty.resolveWith((states) {
                              return 0.0;
                            }),
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: <Color>[
                                  Colors.blue.shade700,
                                  Colors.blue.shade300,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              child: Text(
                                'Pay \$${(widget.amount / 100).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  height: 2
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

