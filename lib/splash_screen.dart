  import 'package:amp_vpn/featureSection.dart';
  import 'package:amp_vpn/loginpage.dart';
  import 'package:flutter/material.dart';
  import 'homepage.dart'; // Import the homepage
  import 'package:shared_preferences/shared_preferences.dart';

  class SplashScreen extends StatefulWidget {
    const SplashScreen({super.key});

    @override
    _SplashScreenState createState() => _SplashScreenState();
  }

  class _SplashScreenState extends State<SplashScreen> {
    @override
    void initState() {
      super.initState();
      navigateToNextScreen();
    }

    void navigateToNextScreen() async {
      await Future.delayed(const Duration(seconds: 4)); // Simulate a delay
      SharedPreferences prefs = await SharedPreferences.getInstance();
      bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      bool isFirstTime = prefs.getBool('isFirstTime') ?? true;

      if (isLoggedIn) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => const Homepage()));
      } else if (isFirstTime) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => const FeatureSection()));
      } else {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => LoginPage()));
      }
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/logo2.png', // Replace with your logo image
                width: 300, // Adjust the width to make it smaller
                height: 300, // Adjust the height to make it smaller
              ),
              const SizedBox(height: 20),
              // const Text(
              //   'Loki VPN',
              //   style: TextStyle(
              //     fontSize: 24,
              //     fontWeight: FontWeight.bold,
              //   ),
              // ),
            ],
          ),
        ),
      );
    }
  }
