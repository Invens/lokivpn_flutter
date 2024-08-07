import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:openvpn_flutter/openvpn_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vpn_info/vpn_info.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'country_selection_screen.dart';
import 'recently_connected_screen.dart';
import 'settings.dart';
import 'subscription_screen.dart';
import 'services/guest_user_service.dart';
import 'loginpage.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> _requestPermissions() async {
  var status = await Permission.location.status;
  if (!status.isGranted) {
    await Permission.location.request();
  }
  status = await Permission.storage.status;
  if (!status.isGranted) {
    await Permission.storage.request();
  }
  status = await Permission.phone.status;
  if (!status.isGranted) {
    await Permission.phone.request();
  }
}
class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  _HomepageState createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  bool _isConnected = false;
  bool _isConnecting = false;
  bool _isTimerRunning = false; // New flag to indicate if the timer is running
  String _connectionStatus = 'CONNECT';
  late OpenVPN engine;
  VpnStatus? status;
  String? stage;
  final bool _granted = false;
  Map<String, dynamic>? _selectedServer;
  double _downloadSpeed = 0.0;
  double _uploadSpeed = 0.0;
  double _downloadBytes = 0.0;
  double _uploadBytes = 0.0;
  late Timer _vpnStateTimer;
  String? _selectedServerFlagUrl;
  Duration _connectionDuration = Duration.zero;
  Timer? _connectionTimer;

  ///All Stages of connection
  static const String vpnConnected = "connected";
  static const String vpnDisconnected = "disconnected";
  static const String vpnWaitConnection = "wait_connection";
  static const String vpnAuthenticating = "authenticating";
  static const String vpnReconnect = "reconnect";
  static const String vpnNoConnection = "no_connection";
  static const String vpnConnecting = "connecting";
  static const String vpnPrepare = "prepare";
  static const String vpnDenied = "denied";

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    engine = OpenVPN(
      onVpnStatusChanged: (data) {
        setState(() {
          status = data;
          _updateConnectionStatus();
        });
      },
      onVpnStageChanged: (data, raw) {
        setState(() {
          stage = raw;
          _updateConnectionStatus();
        });
      },
    );

    engine.initialize(
      groupIdentifier: "group.com.appmontize.lokivpn",
      providerBundleIdentifier: "id.appmontize.openvpnFlutterExample.VPNExtension",
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
    _connectionTimer?.cancel();
    super.dispose();
  }

  void _startVpnStateTimer() {
    _vpnStateTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      bool isConnected = await VpnInfo.isVpnConnected() ?? false;
      setState(() {
        _isConnected = isConnected;
        if (!_isConnected) {
          _isConnecting = false;
          _downloadSpeed = 0.0;
          _uploadSpeed = 0.0;
          _downloadBytes = 0.0;
          _uploadBytes = 0.0;
          _connectionTimer?.cancel();
          _connectionDuration = Duration.zero;
          _isTimerRunning = false; // Reset the flag when disconnected
        }
      });
      if (_isConnected) {
        _measureSpeed();
      }
    });
  }

  Future<void> _connectVPN() async {
    if (_selectedServer == null) {
      await _selectDefaultServer();
    }

    if (_selectedServer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a server first.')),
      );
      return;
    }

    String config = _selectedServer!['OVPNFile'] as String;
    String username = _selectedServer!['Username'];
    String password = _selectedServer!['Password'];

    setState(() {
      _isConnecting = true;
      _connectionStatus = 'CONNECTING...';
    });

    try {
      await engine.connect(
        config,
        _selectedServer!['CountryName'],
        username: username,
        password: password,
        certIsRequired: true,
      );
      _checkConnectionStatus();
    } catch (error) {
      print("Failed to connect VPN: $error");
      setState(() {
        _isConnecting = false;
        _connectionStatus = 'FAILED TO CONNECT';
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to connect VPN')),
        );
      });
    }
  }

  Future<void> _selectDefaultServer() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('https://api.lokivpn.com/api/servers'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        List<dynamic> servers = jsonDecode(response.body);
        if (servers.isNotEmpty) {
          setState(() {
            _selectedServer = servers.first;
            _selectedServerFlagUrl = servers.first['CountryFlag'];
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No servers available')),
          );
        }
      } else {
        throw Exception('Failed to load servers');
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch servers: $error')),
      );
    }
  }

  Future<void> _disconnectVPN() async {
    await _storeConnectedData();
    engine.disconnect();
    setState(() {
      _isConnected = false;
      _downloadSpeed = 0.0;
      _uploadSpeed = 0.0;
      _downloadBytes = 0.0;
      _uploadBytes = 0.0;
      _connectionDuration = Duration.zero;
      _connectionStatus = 'CONNECT';
      _isTimerRunning = false; // Reset the flag when disconnected
    });
    _connectionTimer?.cancel();
    await _sendConnectedData();
  }

  Future<void> _storeConnectedData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(
        'connectedServer',
        jsonEncode({
          'serverName': _selectedServer!['CountryName'],
          'connectionTime': DateTime.now().toIso8601String(),
          'dataUsed': _downloadBytes + _uploadBytes, // Simulated data used, replace with actual value
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
    Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!_isConnected) {
        timer.cancel();
      } else {
        // Simulated packet data for the sake of this example
        final downloadBytes = (1000 * (timer.tick % 5)).toDouble(); // Simulated bytes
        final uploadBytes = (500 * (timer.tick % 5)).toDouble(); // Simulated bytes

        setState(() {
          _downloadBytes += downloadBytes;
          _uploadBytes += uploadBytes;

          _downloadSpeed = _convertBytesToReadable(downloadBytes);
          _uploadSpeed = _convertBytesToReadable(uploadBytes);
        });
      }
    });
  }

  double _convertBytesToReadable(double bytes) {
    if (bytes >= 1 << 30) {
      return bytes / (1 << 30);
    } else if (bytes >= 1 << 20) {
      return bytes / (1 << 20);
    } else if (bytes >= 1 << 10) {
      return bytes / (1 << 10);
    } else {
      return bytes;
    }
  }

  String _formatBytes(double bytes) {
    if (bytes >= 1 << 30) {
      return "${(bytes / (1 << 30)).toStringAsFixed(2)} GB";
    } else if (bytes >= 1 << 20) {
      return "${(bytes / (1 << 20)).toStringAsFixed(2)} MB";
    } else if (bytes >= 1 << 10) {
      return "${(bytes / (1 << 10)).toStringAsFixed(2)} KB";
    } else {
      return "${bytes.toStringAsFixed(2)} B";
    }
  }

  void _startConnectionTimer() {
    if (_isTimerRunning) return; // Check if the timer is already running
    _isTimerRunning = true; // Set the flag to indicate the timer is running
    print("Starting connection timer...");
    _connectionDuration = Duration.zero;
    _connectionTimer?.cancel();
    _connectionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _connectionDuration = Duration(seconds: timer.tick);
        print("Connection duration updated: ${_connectionDuration.inSeconds} seconds");
      });
    });
  }

  Future<void> _checkConnectionStatus() async {
    await Future.delayed(const Duration(seconds: 5)); // Adjust delay as needed
    bool isConnected = await VpnInfo.isVpnConnected() ?? false;
    print("VPN connection status: $isConnected");
    if (isConnected) {
      setState(() {
        _isConnected = true;
        _isConnecting = false;
        _connectionStatus = 'CONNECTED';
      });
      _startConnectionTimer();  // Ensure this is called
    } else {
      setState(() {
        _isConnecting = false;
        _connectionStatus = 'FAILED TO CONNECT';
      });
    }
  }

  void _updateConnectionStatus() {
    print("VPN stage: $stage");
    switch (stage) {
      case vpnConnected:
        setState(() {
          _isConnected = true;
          _isConnecting = false;
          _connectionStatus = 'CONNECTED';
          _startConnectionTimer();  // Ensure this is called
        });
        break;
      case vpnConnecting:
        setState(() {
          _isConnecting = true;
          _connectionStatus = 'CONNECTING...';
        });
        break;
      case vpnWaitConnection:
        setState(() {
          _isConnecting = true;
          _connectionStatus = 'WAITING FOR CONNECTION...';
        });
        break;
      case vpnAuthenticating:
        setState(() {
          _isConnecting = true;
          _connectionStatus = 'AUTHENTICATING...';
        });
        break;
      case vpnReconnect:
        setState(() {
          _isConnecting = true;
          _connectionStatus = 'RECONNECTING...';
        });
        break;
      case vpnNoConnection:
        setState(() {
          _isConnecting = false;
          _isConnected = false;
          _connectionStatus = 'NO CONNECTION';
        });
        break;
      case vpnPrepare:
        setState(() {
          _isConnecting = true;
          _connectionStatus = 'PREPARING...';
        });
        break;
      case vpnDenied:
        setState(() {
          _isConnecting = false;
          _isConnected = false;
          _connectionStatus = 'CONNECTION DENIED';
        });
        break;
      case vpnDisconnected:
        setState(() {
          _isConnecting = false;
          _isConnected = false;
          _connectionStatus = 'DISCONNECTED';
          _connectionTimer?.cancel();
          _connectionDuration = Duration.zero;
          _isTimerRunning = false; // Reset the flag when disconnected
        });
        break;
      default:
        setState(() {
          _isConnecting = false;
          _connectionStatus = 'CONNECT';
        });
        break;
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
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
                        Text(
                          _formatBytes(_downloadBytes),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Text('Download', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          _formatBytes(_uploadBytes),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Text('Upload', style: TextStyle(color: Colors.grey)),
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
                  padding: const EdgeInsets.only(top: 90.0), // Adjusted top margin
                  child: Column(
                    children: [
                      Text(
                        _connectionStatus,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_isConnected)
                        Text(
                          _formatDuration(_connectionDuration),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 20.0), // Top margin for the button
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
                              builder: (context) => ServerScreen(onServerSelected: _onServerSelected)),
                        );
                      },
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
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
                                    errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.flag, color: Colors.white),
                                  ),
                                ),
                              Text(
                                _selectedServer == null ? 'Select Server' : _selectedServer!['CountryName'],
                                style: const TextStyle(
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
                        builder: (context) => const RecentlyConnectedScreen()),
                  );
                  break;
                case 3:
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const Settings()),
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
