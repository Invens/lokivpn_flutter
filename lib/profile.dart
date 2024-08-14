import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart'; // Import share_plus package
import 'services/guest_user_service.dart';
import 'subscription_screen.dart';
import 'api_service.dart';
import 'loginpage.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isGuest = false;
  Map<String, dynamic>? userDetails;
  final GuestUserService _guestUserService =
  GuestUserService(baseUrl: 'https://api.lokivpn.com');
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool? loggedIn = prefs.getBool('isLoggedIn');
    String? token = prefs.getString('token');
    String? guestUserID = prefs.getString('guestUserID');
    String? userID = prefs.getString('userID');

    print(
        'Logged In: $loggedIn, Token: $token, UserID: $userID, GuestUserID: $guestUserID');

    if (loggedIn != null && loggedIn && token != null) {
      try {
        if (guestUserID != null) {
          // Fetch guest user details
          var guestDetails = await _guestUserService.getGuestUserDetails(token);
          setState(() {
            userDetails = guestDetails;
            isGuest = true;
          });
        } else if (userID != null) {
          // Fetch registered user details by userID
          var userDetails = await _apiService.getUserById(userID, token);
          setState(() {
            this.userDetails = userDetails;
            isGuest = false;
          });
        } else {
          // Handle the case where both guestUserID and userID are null
          print('No valid userID or guestUserID found.');
        }
      } catch (e) {
        print('Error: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: ${e.toString()}')),
        );
      }
    } else {
      // Handle not logged in state
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
    }
  }

  Future<void> _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear all stored data

    // Navigate to the login page
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
          (Route<dynamic> route) => false,
    );
  }

  Future<void> _shareWithFriends() async {
    const String message =
        'Check out this awesome VPN app! Download it from the following links:\n\n'
        'Play Store: https://play.google.com/store/apps/details?id=com.example.app\n'
        'App Store: https://apps.apple.com/us/app/example-app/id123456789';
    await Share.share(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.blue,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.white, // Set status bar color to light gray
          statusBarIconBrightness: Brightness.dark, // Set icon brightness to dark
        ),
      ),
      body: userDetails == null
          ? const Center(child: CircularProgressIndicator())
          : isGuest
          ? GuestProfileView(
        userDetails: userDetails!,
        onLogin: _logout, // Pass the logout function to the guest view
        onShare: _shareWithFriends, // Pass the share function
      )
          : RegisteredProfileView(
        userDetails: userDetails!,
        onLogout: _logout,
        onShare: _shareWithFriends, // Pass the share function
      ),
    );
  }
}

class GuestProfileView extends StatelessWidget {
  final Map<String, dynamic> userDetails;
  final Future<void> Function(BuildContext context) onLogin;
  final Future<void> Function() onShare; // Add onShare parameter

  const GuestProfileView({
    super.key,
    required this.userDetails,
    required this.onLogin,
    required this.onShare, // Add onShare parameter
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundImage: AssetImage('assets/profile.png'), // Replace with actual asset
          ),
          const SizedBox(height: 10),
          Text('Guest Username: ${userDetails['username']}'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.remove('guestUserID'); // Remove guest user data
              await prefs.remove('token'); // Remove token
              await prefs.setBool('isLoggedIn', false); // Set logged in status to false
              // Navigate to the login page
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => LoginPage()),
                    (Route<dynamic> route) => false,
              );
            },
            child: const Text('Login'),
          ),
          ElevatedButton(
            onPressed: onShare,
            child: const Text('Share with Friends'),
          ),
        ],
      ),
    );
  }
}

class RegisteredProfileView extends StatelessWidget {
  final Map<String, dynamic> userDetails;
  final Future<void> Function(BuildContext context) onLogout;
  final Future<void> Function() onShare; // Add onShare parameter

  const RegisteredProfileView({
    super.key,
    required this.userDetails,
    required this.onLogout,
    required this.onShare, // Add onShare parameter
  });

  String getSubscriptionTypeName(int subscriptionTypeID) {
    switch (subscriptionTypeID) {
      case 1:
        return 'Free';
      case 8:
        return 'Basic';
      case 9:
        return 'Standard';
      case 10:
        return 'Premium';
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    int subscriptionTypeID = userDetails['SubscriptionTypeID'];
    String subscriptionTypeName = getSubscriptionTypeName(subscriptionTypeID);
    String? subscriptionEndDate = userDetails['SubscriptionEndDate'];
    bool isExpired = false;

    // Check if the subscription is expired
    if (subscriptionEndDate != null) {
      DateTime endDate = DateTime.parse(subscriptionEndDate);
      isExpired = DateTime.now().isAfter(endDate);
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundImage: AssetImage('assets/profile.png'), // Replace with actual asset
          ),
          const SizedBox(height: 10),
          Text('Name: ${userDetails['Name']}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text('Email: ${userDetails['Email']}',
              style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Subscription: $subscriptionTypeName',
                    style: const TextStyle(fontSize: 18)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          if (subscriptionEndDate != null && subscriptionTypeID != 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      'Expires On: ${DateFormat.yMMMd().format(DateTime.parse(subscriptionEndDate))}'),
                  if (isExpired)
                    const Text('Subscription Status: Expired',
                        style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          const SizedBox(height: 20),
          if (subscriptionTypeID == 1 || isExpired)
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SubscriptionScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                iconColor: Colors.yellow,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
              ),
              child: const Text('Upgrade to PRO',
                  style: TextStyle(color: Colors.black)),
            ),
          const SizedBox(height: 30),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Purchase History'),
            onTap: () {
              // Navigate to Purchase History screen
            },
          ),
          ListTile(
            leading: const Icon(Icons.support),
            title: const Text('Help & Support'),
            onTap: () {
              // Navigate to Help & Support screen
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_add),
            title: const Text('Invite a Friend'),
            onTap: onShare, // Call the onShare function
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () => onLogout(context),
          ),
        ],
      ),
    );
  }
}
