import 'package:flutter/material.dart';
import 'splash_screen.dart'; // Import the splash screen
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Loki VPN',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: GoogleFonts.poppins().fontFamily,
      ),
      home: const SplashScreen(), // Set SplashScreen as the initial screen
    );
  }
}
