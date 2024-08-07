import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('About Loki VPN'),
      ),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(
            'About Loki VPN\n\n'
                'Welcome to Loki VPN, your ultimate tool for secure and private internet browsing. With Loki VPN, your online activities remain confidential and protected, ensuring a safe and unrestricted internet experience. Whether you\'re accessing sensitive information, streaming your favorite content, or simply browsing the web, Loki VPN offers top-notch security and performance tailored to your needs.\n\n'
                'Key Features:\n\n'
                '1. Military-Grade Encryption:\n\n'
                'Enjoy the highest level of security with AES-256 encryption, protecting your data from hackers, ISPs, and other third parties.\n\n'
                '2. Global Server Network:\n\n'
                'Connect to servers worldwide to bypass geo-restrictions and access content from different regions seamlessly.\n\n'
                '3. No Logs Policy:\n\n'
                'We prioritize your privacy with our strict no-logs policy, ensuring that your browsing history and personal information are never stored or shared.\n\n'
                '4. High-Speed Connections:\n\n'
                'Experience fast and reliable VPN connections with unlimited bandwidth, providing a seamless online experience.\n\n'
                '5. Easy-to-Use Interface:\n\n'
                'Our user-friendly interface makes connecting to the VPN simple and intuitive, even for those new to VPNs.\n\n'
                '6. Multi-Platform Support:\n\n'
                'Use Loki VPN on all your devices, including Android, iOS, Windows, and macOS, for consistent protection across platforms.\n\n'
                '7. Secure Public Wi-Fi:\n\n'
                'Protect your data on public Wi-Fi networks with encrypted connections, preventing unauthorized access to your information.\n\n'
                '8. 24/7 Customer Support:\n\n'
                'Our dedicated support team is available around the clock to assist with any questions or issues you may encounter.\n\n'
                'Why Choose Loki VPN?\n\n'
                'Unmatched Security:\n\n'
                'Our advanced encryption protocols and security features ensure that your data is protected at all times.\n\n'
                'Complete Privacy:\n\n'
                'We do not track or log your online activities, providing a private and anonymous browsing experience.\n\n'
                'Unlimited Access:\n\n'
                'Bypass censorship and geo-blocks to access your favorite websites and services from anywhere in the world.\n\n'
                'User-Friendly:\n\n'
                'Loki VPN is designed for ease of use, allowing you to connect with just a few taps.\n\n'
                'Reliable Performance:\n\n'
                'Our global server network ensures fast and stable connections, ideal for streaming, browsing, and downloading.\n\n'
                'Get Started Today!\n\n'
                'Download Loki VPN now and enjoy the following benefits:\n\n'
                '- Free Trial:\n\n'
                'Experience our premium features with a 7-day free trial. No commitment, cancel anytime.\n\n'
                '- Flexible Subscription Plans:\n\n'
                'Choose from our flexible subscription plans to find the one that best suits your needs.\n\n'
                '- In-App Purchases:\n\n'
                'Easily upgrade to premium features through our secure in-app purchase system.\n\n'
                'How to Use Loki VPN:\n\n'
                '1. Download and Install:\n\n'
                'Install Loki VPN from the Google Play Store and open the app.\n\n'
                '2. Sign Up or Log In:\n\n'
                'Create a new account or log in with your existing credentials.\n\n'
                '3. Choose a Server:\n\n'
                'Select a server from our global network to connect.\n\n'
                '4. Connect:\n\n'
                'Tap the connect button and enjoy secure and private browsing instantly.\n\n'
                '5. Upgrade:\n\n'
                'Upgrade to premium features directly within the app through in-app purchases.\n\n'
                'Need Help?\n\n'
                'Our 24/7 customer support team is here to help. Contact us through the app or visit our website for assistance.\n\n'
                'Stay secure, stay private, and stay connected with Loki VPN. Download now and take control of your online privacy.\n',
          ),
        ),
      ),
    );
  }
}
