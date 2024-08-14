import 'dart:async';
import 'dart:convert';

import 'package:amp_vpn/signUppage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'homepage.dart';
class OtpVerificationPage extends StatefulWidget {
  final String userID;

  const OtpVerificationPage({super.key, required this.userID});

  @override
  _OtpVerificationPageState createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final TextEditingController _otpController1 = TextEditingController();
  final TextEditingController _otpController2 = TextEditingController();
  final TextEditingController _otpController3 = TextEditingController();
  final TextEditingController _otpController4 = TextEditingController();

  final FocusNode _otpFocusNode1 = FocusNode();
  final FocusNode _otpFocusNode2 = FocusNode();
  final FocusNode _otpFocusNode3 = FocusNode();
  final FocusNode _otpFocusNode4 = FocusNode();

  bool _isLoading = false;
  bool _isResending = false;
  int _resendCountdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startResendCountdown() {
    _resendCountdown = 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown == 0) {
        timer.cancel();
      } else {
        setState(() {
          _resendCountdown--;
        });
      }
    });
  }

  Future<void> _verifyOtp(BuildContext context) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final otp =
          '${_otpController1.text}${_otpController2.text}${_otpController3.text}${_otpController4.text}';
      final response = await http.post(
        Uri.parse('https://api.lokivpn.com/api/users/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userID': widget.userID,
          'otp': otp,
        }),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setBool('isFirstTime', false);
        await prefs.setString('token', responseData['token']);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const Homepage()),
        );
      } else {
        final responseData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to verify OTP: ${responseData['message']}')),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to verify OTP: ${e.toString()}')),
      );
    }
  }

  Future<void> _resendOtp() async {
    setState(() {
      _isResending = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://api.lokivpn.com/api/users/request-password-reset-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userID': widget.userID}),
      );

      setState(() {
        _isResending = false;
      });

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP resent successfully')),
        );
        _startResendCountdown();
      } else {
        final responseData = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error resending OTP: ${responseData['message']}')),
        );
      }
    } catch (error) {
      setState(() {
        _isResending = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error resending OTP: $error')),
      );
    }
  }

  Widget _buildOtpInput(TextEditingController controller, FocusNode focusNode, FocusNode? nextFocusNode) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
        ),
        onChanged: (value) {
          if (value.length == 1 && nextFocusNode != null) {
            FocusScope.of(context).requestFocus(nextFocusNode);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.lightBlueAccent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const SignUpPage()),
            );
          },
        ),
        title: const Text(
          'Enter Verification Code',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
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
                        padding: const EdgeInsets.only(top: 30.0), // Adjust padding to prevent hiding behind app bar
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
                        'Verify OTP',
                        style: TextStyle(
                          fontSize: 22,
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                          height: 4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildOtpInput(_otpController1, _otpFocusNode1, _otpFocusNode2),
                          _buildOtpInput(_otpController2, _otpFocusNode2, _otpFocusNode3),
                          _buildOtpInput(_otpController3, _otpFocusNode3, _otpFocusNode4),
                          _buildOtpInput(_otpController4, _otpFocusNode4, null),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: _resendCountdown == 0 ? _resendOtp : null,
                          child: Text(
                            _resendCountdown == 0
                                ? 'Resend OTP'
                                : 'Resend OTP in $_resendCountdown seconds',
                            style: TextStyle(
                              color: _resendCountdown == 0 ? Colors.blue : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
                      _isLoading
                          ? const CircularProgressIndicator()
                          : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _verifyOtp(context),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 15.0),
                          ).copyWith(
                            backgroundColor: WidgetStateProperty.resolveWith(
                                  (states) {
                                return Colors.transparent;
                              },
                            ),
                            elevation: WidgetStateProperty.resolveWith(
                                  (states) {
                                return 0.0;
                              },
                            ),
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: <Color>[
                                  Colors.blue.shade700,
                                  Colors.blue.shade300,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              child: const Text(
                                'Verify',
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
                      _isLoading || _isResending
                          ? const CircularProgressIndicator()
                          : const SizedBox.shrink(),
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
}
