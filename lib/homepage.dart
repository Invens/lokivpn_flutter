import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:openvpn_flutter/openvpn_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vpn_info/vpn_info.dart';

import 'api_service.dart';
import 'country_selection_screen.dart';
import 'recently_connected_screen.dart';
import 'settings.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  bool _isConnected = false;
  bool _isConnecting = false;
  late OpenVPN engine;
  VpnStatus? status;
  String? stage;
  bool _granted = false;
  Map<String, dynamic>? _selectedServer;
  double _downloadSpeed = 0.0;
  double _uploadSpeed = 0.0;
  late Timer _vpnStateTimer;
  String? _selectedServerFlagUrl;

  @override
  void initState() {
    super.initState();
    engine = OpenVPN(
      onVpnStatusChanged: (data) {
        setState(() {
          status = data;
        });
      },
      onVpnStageChanged: (data, raw) {
        setState(() {
          stage = raw;
        });
      },
    );

    engine.initialize(
      groupIdentifier: "group.com.appmontize.lokivpn",
      providerBundleIdentifier:
          "id.appmontize.openvpnFlutterExample.VPNExtension",
      localizedDescription: "VPN by Appmontize.co.in",
      lastStage: (stage) {
        setState(() {
          this.stage = stage.name;
        });
      },
      lastStatus: (status) {
        setState(() {
          this.status = status;
        });
      },
    );

    _startVpnStateTimer();
  }

  @override
  void dispose() {
    _vpnStateTimer.cancel();
    super.dispose();
  }

  void _startVpnStateTimer() {
    _vpnStateTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
      bool isConnected = await VpnInfo.isVpnConnected() ?? false;
      setState(() {
        _isConnected = isConnected;
        if (!_isConnected) {
          _isConnecting = false;
          _downloadSpeed = 0.0;
          _uploadSpeed = 0.0;
        }
      });
      if (_isConnected) {
        _measureSpeed();
      }
    });
  }

  Future<void> _connectVPN() async {
    if (_selectedServer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a server first.')),
      );
      return;
    }

    String config = _selectedServer!['OVPNFile'] as String;
    String username = _selectedServer!['Username'];
    String password = _selectedServer!['Password'];

    setState(() {
      _isConnecting = true;
    });

    try {
      await engine.connect(
        config,
        _selectedServer!['CountryName'],
        username: username,
        password: password,
        certIsRequired: true,
      );
    } catch (error) {
      print("Failed to connect VPN: $error");
      setState(() {
        _isConnecting = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to connect VPN')),
        );
      });
    }
  }

  Future<void> _disconnectVPN() async {
    await _storeConnectedData();
    engine.disconnect();
    setState(() {
      _isConnected = false;
      _downloadSpeed = 0.0;
      _uploadSpeed = 0.0;
    });
    await _sendConnectedData();
  }

  Future<void> _storeConnectedData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(
        'connectedServer',
        jsonEncode({
          'serverName': _selectedServer!['CountryName'],
          'connectionTime': DateTime.now().toIso8601String(),
          'dataUsed': 100.0, // Simulated data used, replace with actual value
        }));
  }

  Future<void> _sendConnectedData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? connectedData = prefs.getString('connectedServer');
    if (connectedData != null) {
      Map<String, dynamic> data = jsonDecode(connectedData);
      await ApiService().addRecentlyConnectedServer(
        data['serverName'],
        data['connectionTime'],
        data['dataUsed'],
      );
      prefs.remove('connectedServer');
    }
  }

  void _onServerSelected(Map<String, dynamic> serverDetails) {
    setState(() {
      _selectedServer = serverDetails;
      _selectedServerFlagUrl = serverDetails['CountryFlag'];
    });
  }

  void _measureSpeed() {
    Timer.periodic(Duration(seconds: 1), (timer) {
      if (!_isConnected) {
        timer.cancel();
      } else {
        setState(() {
          _downloadSpeed =
              (10 + (30 * (timer.tick % 5))).toDouble(); // Simulated speed
          _uploadSpeed =
              (5 + (15 * (timer.tick % 5))).toDouble(); // Simulated speed
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 2,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: IconButton(
            icon: Image.asset('assets/menu_button.png'),
            onPressed: () {
              // Add your onPressed logic here
            },
          ),
        ),
        actions: const [
          Icon(Icons.share, color: Colors.blue),
        ],
        centerTitle: true,
        title: Image.asset('assets/singlelogo.png', width: 140, height: 50),
      ),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Lottie.asset(
              'assets/lottie/background.json', // Your Lottie file path
              fit: BoxFit.contain,
              width: 40,
              height: MediaQuery.of(context).size.height * 0.6,
            ),
          ),
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 0),
                const SizedBox(height: 0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        Text('${_downloadSpeed.toStringAsFixed(1)} MB/s',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const Text('Download',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                    Column(
                      children: [
                        Text('${_uploadSpeed.toStringAsFixed(1)} MB/s',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        const Text('Upload',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 60),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 250,
                      height: 250,
                      child: GestureDetector(
                        onTap: () async {
                          if (_isConnected) {
                            await _disconnectVPN();
                          } else {
                            await _connectVPN();
                          }
                        },
                        child: Lottie.asset(
                          _isConnected
                              ? 'assets/lottie/connect.json'
                              : 'assets/lottie/disconnect.json',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(
                      top: 110.0), // Added top margin here
                  child: Text(
                    _isConnecting
                        ? 'CONNECTING...'
                        : _isConnected
                            ? 'DISCONNECT'
                            : 'CONNECT',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(
                        top: 20.0), // Top margin for the button
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 0.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0.0),
                        ),
                        iconColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => ServerScreen(
                                  onServerSelected: _onServerSelected)),
                        );
                      },
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue, Colors.lightBlueAccent],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(30.0),
                        ),
                        child: Container(
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_selectedServerFlagUrl != null)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Image.network(
                                    _selectedServerFlagUrl!,
                                    width: 24,
                                    height: 24,
                                    errorBuilder: (context, error,
                                            stackTrace) =>
                                        Icon(Icons.flag, color: Colors.white),
                                  ),
                                ),
                              Text(
                                _selectedServer == null
                                    ? 'Select Server'
                                    : _selectedServer!['CountryName'],
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                  height: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 10, right: 10, bottom: 10),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(30.0),
          boxShadow: const [
            BoxShadow(
              color: Colors.blue,
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30.0),
          child: BottomNavigationBar(
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.dns),
                label: 'Server',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history),
                label: 'Recent',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
            onTap: (index) {
              switch (index) {
                case 0:
                  break;
                case 1:
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            ServerScreen(onServerSelected: _onServerSelected)),
                  );
                  break;
                case 2:
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => RecentlyConnectedScreen()),
                  );
                  break;
                case 3:
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => Settings()),
                  );
                  break;
              }
            },
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.grey,
            backgroundColor: Colors.transparent,
          ),
        ),
      ),
    );
  }
}
