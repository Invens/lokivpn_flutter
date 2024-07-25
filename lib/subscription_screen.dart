import 'dart:convert';

import 'package:amp_vpn/payment.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SubscriptionScreen extends StatefulWidget {
  @override
  _SubscriptionScreenState createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  late Future<List<dynamic>> _subscriptionTypesFuture;

  @override
  void initState() {
    super.initState();
    _subscriptionTypesFuture = _fetchSubscriptionTypes();
  }

  Future<List<dynamic>> _fetchSubscriptionTypes() async {
    final response =
        await http.get(Uri.parse('https://api.lokivpn.com/api/subscriptions'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load subscription types');
    }
  }

  void _onSubscriptionSelected(Map<String, dynamic> subscription) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          subscriptionTypeId: subscription['SubscriptionTypeID'],
          description: subscription['Description'],
          amount: (double.parse(subscription['Price']) * 100)
              .toInt(), // Convert price to cents
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Subscription Plans')),
      body: FutureBuilder<List<dynamic>>(
        future: _subscriptionTypesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No subscription plans available'));
          } else {
            List<dynamic> subscriptions = snapshot.data!;
            return ListView.builder(
              itemCount: subscriptions.length,
              itemBuilder: (context, index) {
                var subscription = subscriptions[index];
                return ListTile(
                  title: Text(subscription['Name']),
                  subtitle: Text(subscription['Description']),
                  trailing: Text('\$${subscription['Price']}'),
                  onTap: () => _onSubscriptionSelected(subscription),
                );
              },
            );
          }
        },
      ),
    );
  }
}
