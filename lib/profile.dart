import 'package:amp_vpn/services/guest_user_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api_service.dart';

class ProfileScreen extends StatefulWidget {
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
    String? userID = prefs.getString('userID');

    print('Logged In: $loggedIn, Token: $token, UserID: $userID');

    if (loggedIn != null && loggedIn && token != null) {
      try {
        if (userID == null) {
          // Fetch guest username
          var guestDetails = await _guestUserService.getGuestUserDetails(token);
          setState(() {
            userDetails = guestDetails;
            isGuest = true;
          });
        } else {
          // Fetch registered user details by userID
          var userDetails = await _apiService.getUserById(userID, token);
          setState(() {
            this.userDetails = userDetails;
            isGuest = false;
          });
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
        SnackBar(content: Text('User not logged in')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: userDetails == null
          ? Center(child: CircularProgressIndicator())
          : isGuest
              ? GuestProfileView(userDetails: userDetails!)
              : RegisteredProfileView(userDetails: userDetails!),
    );
  }
}

class GuestProfileView extends StatelessWidget {
  final Map<String, dynamic> userDetails;

  GuestProfileView({required this.userDetails});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Guest Username: ${userDetails['username']}'),
        ],
      ),
    );
  }
}

class RegisteredProfileView extends StatelessWidget {
  final Map<String, dynamic> userDetails;

  RegisteredProfileView({required this.userDetails});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Name: ${userDetails['Name']}'),
          Text('Email: ${userDetails['Email']}'),
          Text('Subscription Type: ${userDetails['SubscriptionTypeID']}'),
          // Add more details as required
        ],
      ),
    );
  }
}
