import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'payment_screen.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  _SubscriptionScreenState createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  late Future<List<dynamic>> _subscriptionTypesFuture;
  String? userId;

  @override
  void initState() {
    super.initState();
    _fetchUserId();
    _subscriptionTypesFuture = _fetchSubscriptionTypes();
  }

  Future<void> _fetchUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userId = prefs.getString('userID');

    if (userId == null) {
      // Handle the case where userId is not found
      print('User ID not found in SharedPreferences.');
    } else {
      print('User ID found: $userId');
    }

    setState(() {}); // Update the state to reflect changes in the UI
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
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User ID not found')),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          subscriptionTypeId: subscription['SubscriptionTypeID'],
          userId: userId!, // Pass the userId as String
          description: subscription['Description'],
          amount: (double.parse(subscription['Price']) * 100).toInt(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0056FD),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Get Premium', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _subscriptionTypesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No subscription plans available'));
          } else {
            List<dynamic> subscriptions = snapshot.data!;
            return Column(
              children: [
                _buildFeatureList(),
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Select Your Subscription',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: subscriptions.length,
                    itemBuilder: (context, index) {
                      var subscription = subscriptions[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          title: Text(
                            subscription['Name'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(subscription['Description']),
                          trailing: Text(
                            '\$${subscription['Price']}',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                          onTap: () => _onSubscriptionSelected(subscription),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () {
                      // Handle buy premium button action
                    },
                    style: ElevatedButton.styleFrom(
                      iconColor: const Color(0xFF00B4DB),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'Buy Premium Now!',
                        style: TextStyle(color: Colors.blue, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildFeatureList() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildFeatureItem(Icons.check, 'Multi-Device',
              'Use on Multiple Devices.'),
          _buildFeatureItem(Icons.check, 'Faster', 'Unlimited bandwidth.'),
          _buildFeatureItem(
              Icons.check, 'All Server', 'All servers in 100+ countries.'),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Card(
      color: Colors.white.withOpacity(0.1),
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(icon, color: Colors.white),
        title: Text(
          title,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(description, style: const TextStyle(color: Colors.white70)),
      ),
    );
  }
}
