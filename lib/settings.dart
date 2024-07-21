import 'package:amp_vpn/profile.dart';
import 'package:amp_vpn/country_selection_screen.dart';
import 'package:amp_vpn/homepage.dart';
import 'package:amp_vpn/recently_connected_screen.dart';
import 'package:flutter/material.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<Settings> {
  bool unsafeWifiDetection = true;
  bool notifications = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const Homepage()),
            );
          },
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          _buildListTile(Icons.person, 'My Profile', () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) =>  ProfileScreen()),
            );
          }),
          _buildListTile(Icons.location_on, 'Location (Nodes)', null),
          _buildListTile(Icons.settings, 'DNS Settings', null),
          _buildSwitchTile(Icons.wifi_off, 'Unsafe Wifi Detection', unsafeWifiDetection, (bool value) {
            setState(() {
              unsafeWifiDetection = value;
            });
          }),
          _buildSwitchTile(Icons.notifications, 'Notification', notifications, (bool value) {
            setState(() {
              notifications = value;
            });
          }),
          _buildListTile(Icons.policy, 'Privacy Policy', null),
          _buildListTile(Icons.description, 'Terms of Service', null),
          _buildListTile(Icons.info, 'About App', null),
        ],
      ),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 10, right: 10, bottom: 10), // Adjust margins as needed
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
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => ServerScreen(onServerSelected: (serverDetails) {
                      // handle server selection
                    })),
                  );
                  break;
                case 2:
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const RecentlyConnectedScreen()),
                  );
                  break;
                case 3:
                // Already on Settings screen
                  break;
              }
            },
            currentIndex: 3,
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.grey,
            backgroundColor: Colors.transparent, // Set transparent background for BottomNavigationBar
          ),
        ),
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title, VoidCallback? onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(IconData icon, String title, bool value, ValueChanged<bool> onChanged) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
