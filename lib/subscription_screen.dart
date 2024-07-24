import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:amp_vpn/services/subscription_service.dart';

class SubscriptionScreen extends StatefulWidget {
  @override
  _SubscriptionScreenState createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService(baseUrl: 'http://your-backend-url.com');
  late Future<List<dynamic>> _subscriptionTypesFuture;

  @override
  void initState() {
    super.initState();
    _subscriptionTypesFuture = _subscriptionService.getSubscriptionTypes();
  }

  Future<void> _upgradeSubscription(int newSubscriptionID) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token != null) {
      await _subscriptionService.upgradeSubscription(token, newSubscriptionID);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Subscription upgraded successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please log in to upgrade your subscription')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Subscriptions')),
      body: FutureBuilder<List<dynamic>>(
        future: _subscriptionTypesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No subscriptions available'));
          } else {
            List<dynamic> subscriptions = snapshot.data!;
            return ListView.builder(
              itemCount: subscriptions.length,
              itemBuilder: (context, index) {
                var subscription = subscriptions[index];
                return ListTile(
                  title: Text(subscription['Name']),
                  subtitle: Text(subscription['Description']),
                  trailing: ElevatedButton(
                    onPressed: () => _upgradeSubscription(subscription['SubscriptionTypeID']),
                    child: Text('Upgrade'),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
