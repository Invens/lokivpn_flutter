import 'dart:convert';

import 'package:amp_vpn/subscription_screen.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'homepage.dart';
import 'recently_connected_screen.dart';
import 'settings.dart';

class ServerScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onServerSelected;

  const ServerScreen({super.key, required this.onServerSelected});

  @override
  _ServerScreenState createState() => _ServerScreenState();
}

class _ServerScreenState extends State<ServerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<List<dynamic>> _allServersFuture;
  late Future<List<dynamic>> _freeServersFuture;
  late Future<List<dynamic>> _paidServersFuture;
  bool _isSubscribed = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _allServersFuture = _fetchServers();
    _freeServersFuture = _fetchFreeServers();
    _paidServersFuture = _fetchPaidServers();
    _checkSubscriptionStatus();
  }

  Future<List<dynamic>> _fetchServers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('https://api.lokivpn.com/api/servers'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load servers');
    }
  }

  Future<List<dynamic>> _fetchFreeServers() async {
    List<dynamic> servers = await _fetchServers();
    return servers.where((server) => server['ServerType'] == 'Free').toList();
  }

  Future<List<dynamic>> _fetchPaidServers() async {
    List<dynamic> servers = await _fetchServers();
    return servers.where((server) => server['ServerType'] == 'Paid').toList();
  }

  Future<void> _checkSubscriptionStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('https://api.lokivpn.com/api/users/profile'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      var user = jsonDecode(response.body);
      setState(() {
        _isSubscribed = user['SubscriptionTypeID'] != 1;
      });
    } else {
      throw Exception('Failed to fetch user profile');
    }
  }

  void _selectServer(String serverID) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.get(
      Uri.parse('https://api.lokivpn.com/api/servers/$serverID'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> serverDetails = jsonDecode(response.body);
      if (serverDetails['ServerType'] == 'Paid' && !_isSubscribed) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
        );
      } else {
        widget.onServerSelected(serverDetails);
        Navigator.pop(context); // Go back to the previous screen
      }
    } else {
      throw Exception('Failed to load server details');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Select A Country',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {
              // Add search functionality
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FilterButton(
                text: 'All',
                isSelected: _tabController.index == 0,
                onTap: () {
                  setState(() {
                    _tabController.index = 0;
                  });
                },
              ),
              FilterButton(
                text: 'Free',
                isSelected: _tabController.index == 1,
                onTap: () {
                  setState(() {
                    _tabController.index = 1;
                  });
                },
              ),
              FilterButton(
                text: 'Paid',
                isSelected: _tabController.index == 2,
                onTap: () {
                  setState(() {
                    _tabController.index = 2;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildServerList(_allServersFuture),
          _buildServerList(_freeServersFuture),
          _buildServerList(_paidServersFuture),
        ],
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(
            left: 10, right: 10, bottom: 10), // Adjust margins as needed
        decoration: BoxDecoration(
          color: Colors.blue, // Background color set to blue
          borderRadius: BorderRadius.circular(30.0), // Circular border radius
          boxShadow: const [
            BoxShadow(
              color: Colors.blue,
              spreadRadius: 2,
              blurRadius: 5,
              offset: Offset(0, 3), // changes position of shadow
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
              // Handle the tap event for each item
              switch (index) {
                case 0:
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const Homepage()),
                  );
                  break;
                case 1:
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
            currentIndex: 1,
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.grey,
            backgroundColor: Colors
                .transparent, // Set transparent background for BottomNavigationBar
          ),
        ),
      ),
    );
  }

  Widget _buildServerList(Future<List<dynamic>> serversFuture) {
    return FutureBuilder<List<dynamic>>(
      future: serversFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No servers available'));
        } else {
          List<dynamic> servers = snapshot.data!;
          return ListView.builder(
            itemCount: servers.length,
            itemBuilder: (context, index) {
              var server = servers[index];
              return ListTile(
                leading: Image.network(
                  server['CountryFlag'],
                  width: 40,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.flag),
                ),
                title: Text(server['CountryName']),
                trailing: const Icon(Icons.signal_wifi_4_bar, color: Colors.blue),
                onTap: () => _selectServer(server['ServerID'].toString()),
              );
            },
          );
        }
      },
    );
  }
}

class FilterButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final VoidCallback onTap;

  const FilterButton(
      {super.key, required this.text, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.teal,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
