import 'package:amp_vpn/resetPassword.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'homepage.dart';
import 'services/guest_user_service.dart';
import 'signUppage.dart';

class LoginPage extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final ApiService _apiService = ApiService();
  final GuestUserService _guestUserService =
  GuestUserService(baseUrl: 'https://api.lokivpn.com');

  LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.lightBlueAccent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton(
              onPressed: () async {
                await _registerOrLoginGuest(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
              child: const Text(
                'Skip',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      height: 250,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        image: DecorationImage(
                          image: AssetImage('assets/background_pattern.jpg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(
                            top: 30.0), // Adjust padding to prevent hiding behind app bar
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(50.0), // Adjust the radius as needed
                          child: Image.asset(
                            'assets/logo2.png',
                            height: 200, // Adjust the height as needed
                            width: 200, // Adjust the width as needed
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: Colors.blueAccent,
                        width: 3.0,
                      ),
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30.0),
                      topRight: Radius.circular(30.0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Login',
                        style: TextStyle(
                            fontSize: 22,
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            height: 4),
                      ),
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Enter Email',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide.none,
                          ),
                          fillColor: Colors.grey[200],
                          filled: true,
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0),
                            borderSide: BorderSide.none,
                          ),
                          fillColor: Colors.grey[200],
                          filled: true,
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>  const RequestResetPasswordOtpScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(color: Colors.blue),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            await _login(context);
                          },
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 15.0),
                          ).copyWith(
                            backgroundColor:
                            WidgetStateProperty.resolveWith((states) {
                              return Colors.transparent;
                            }),
                            elevation:
                            WidgetStateProperty.resolveWith((states) {
                              return 0.0;
                            }),
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: <Color>[
                                  Colors.blue.shade700,
                                  Colors.blue.shade300
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              child: const Text(
                                'Log in',
                                style: TextStyle(
                                  height: 3, // Adjust the height as needed
                                  fontSize: 20,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Don't have an account?"),
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const SignUpPage()),
                              );
                            },
                            child: const Text('Sign up'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Column(
                          children: [
                            const Text(
                              'By continuing, you agree to our',
                              style: TextStyle(fontSize: 8, color: Colors.grey),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    // Handle Terms of Service
                                  },
                                  child: const Text(
                                    'Terms of Service',
                                    style: TextStyle(fontSize: 8),
                                  ),
                                ),
                                const Text('|',
                                    style: TextStyle(
                                        fontSize: 8, color: Colors.grey)),
                                TextButton(
                                  onPressed: () {
                                    // Handle Privacy Policy
                                  },
                                  child: const Text(
                                    'Privacy Policy',
                                    style: TextStyle(fontSize: 8),
                                  ),
                                ),
                                const Text('|',
                                    style: TextStyle(
                                        fontSize: 8, color: Colors.grey)),
                                TextButton(
                                  onPressed: () {
                                    // Handle Content Policy
                                  },
                                  child: const Text(
                                    'Content Policy',
                                    style: TextStyle(fontSize: 8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                          height: 20), // Add padding at the bottom of the login section
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

  Future<void> _login(BuildContext context) async {
    try {
      final response = await _apiService.login(
        _emailController.text,
        _passwordController.text,
      );

      print('Login response: $response'); // Debugging line to check the response

      // Save token or user information in shared preferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setBool('isFirstTime', false);
      await prefs.setString('token', response['token']);
      await prefs.setString('userID', response['userID'].toString());

      print('Token saved: ${response['token']}');
      print('UserID saved: ${response['userID']}');

      // Navigate to homepage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Homepage()),
      );
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to login: ${e.toString()}')),
      );
    }
  }

  Future<void> _registerOrLoginGuest(BuildContext context) async {
    try {
      final response = await _guestUserService.registerOrLoginGuest();

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setBool('isFirstTime', false);
      await prefs.setBool('isGuest', true);
      await prefs.setString('guestToken', response['token']);
      await prefs.setString('guestUserID', response['guestUserID'].toString());

      print('GuestToken saved: ${response['token']}'); // Debugging
      print('GuestUserID saved: ${response['guestUserID']}'); // Debugging

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Homepage()),
      );
    } catch (e) {
      print('Error during guest login: $e'); // Debugging
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Guest registration failed: $e')),
      );
    }
  }
}

