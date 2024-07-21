import 'package:flutter/material.dart';

import 'api_service.dart';

class RecentlyConnectedScreen extends StatefulWidget {
  const RecentlyConnectedScreen({super.key});

  @override
  _RecentlyConnectedScreenState createState() =>
      _RecentlyConnectedScreenState();
}

class _RecentlyConnectedScreenState extends State<RecentlyConnectedScreen> {
  late Future<List<dynamic>> _recentlyConnectedServersFuture;

  @override
  void initState() {
    super.initState();
    _recentlyConnectedServersFuture =
        ApiService().getRecentlyConnectedServers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Recently Connected Servers',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search location',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _recentlyConnectedServersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No recently connected servers'));
                } else {
                  return ListView(
                    children: snapshot.data!.map((server) {
                      return ListTile(
                        leading: Image.network(
                          server['CountryFlag'],
                          width: 40,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(Icons.flag),
                        ),
                        title: Text(server['serverName']),
                        subtitle:
                            Text('Connected on: ${server['connectionTime']}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Data Used',
                                style: TextStyle(fontSize: 12)),
                            Text('${server['dataUsed']} MB',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                }
              },
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
                  Navigator.pop(context);
                  break;
                case 1:
                  Navigator.pop(context);
                  break;
                case 2:
                  break;
                case 3:
                  Navigator.pop(context);
                  break;
              }
            },
            currentIndex: 2,
            selectedItemColor: Colors.blue,
            unselectedItemColor: Colors.grey,
            backgroundColor: Colors.transparent,
          ),
        ),
      ),
    );
  }
}
