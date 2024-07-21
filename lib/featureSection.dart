import 'package:amp_vpn/loginpage.dart';
import 'package:flutter/material.dart';

class FeatureSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView(
              children: [
                FeaturePage(
                  'Your Trusted VPN Solution',
                  'Our VPN uses state-of-the-art encryption to safeguard your personal information.',
                  'assets/trust.png',
                ),
                FeaturePage(
                  'Unmatched Security',
                  'Our VPN employs military-grade encryption to keep your data safe.',
                  'assets/security.png',
                ),
                FeaturePage(
                  'Global Network Coverage',
                  'Enjoy seamless streaming, gaming, and browsing with our robust network.',
                  'assets/network.png',
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                iconColor: Colors.orange, backgroundColor: Colors.white, // Text color
                minimumSize: const Size(double.infinity, 60), // Full width button with increased height
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0), // Rounded corners
                ),
              ),
              child: const Text(
                'Get Started',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), // Increase text size
              ),
            ),
          ),
          SizedBox(height: 30), // More margin from the bottom
        ],
      ),
    );
  }
}

class FeaturePage extends StatelessWidget {
  final String title;
  final String description;
  final String imagePath;

  FeaturePage(this.title, this.description, this.imagePath);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(imagePath, height: 300, width: 300), // Adjust the height as needed
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
         const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
