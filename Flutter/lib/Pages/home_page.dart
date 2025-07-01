import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:zephlyr/main.dart';
import 'package:zephlyr/pages/chart_page.dart';
import 'package:zephlyr/pages/device_name_page.dart';
import 'package:zephlyr/pages/login_page.dart';
import 'package:zephlyr/pages/schedule_screen.dart';
import '../services/auth_service.dart';

class HomePage extends StatefulWidget {
  final User user;
  HomePage({required this.user});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final AuthService _authService = AuthService();
  final PageController _pageController = PageController();
  int _selectedIndex = 0;

  List<Map<String, dynamic>> devices = [];

  @override
  void initState() {
    super.initState();
    _fetchDevices();
  }

  void _fetchDevices() async {
    String uid = widget.user.uid;
    DatabaseReference userRef = FirebaseDatabase.instance.ref("users/$uid");

    // Ambil role user dari Firebase
    DataSnapshot snapshot = await userRef.get();
    if (!snapshot.exists || snapshot.value == null) return;

    Map<dynamic, dynamic>? userData = snapshot.value as Map<dynamic, dynamic>?;
    String userRole = userData?["role"] ?? "user";

    DatabaseReference devicesRef;
    if (userRole == "admin") {
      // Admin: Ambil semua devices dari semua user
      devicesRef = FirebaseDatabase.instance.ref("users");
    } else {
      // User biasa: Hanya ambil devices miliknya sendiri
      devicesRef = FirebaseDatabase.instance.ref("users/$uid/device");
    }

    devicesRef.onValue.listen((event) {
      if (!mounted) return;

      var data = event.snapshot.value;
      if (data == null || !(data is Map<dynamic, dynamic>)) return;

      List<Map<String, dynamic>> tempDevices = [];

      if (userRole == "admin") {
        // Admin bisa akses semua users -> Harus loop ke setiap user
        data.forEach((userId, userDevices) {
          if (userDevices is Map && userDevices.containsKey("device")) {
            userDevices["device"].forEach((deviceId, deviceData) {
              tempDevices.add(_parseDevice(deviceId, deviceData));
            });
          }
        });
      } else {
        // User biasa: Data langsung di "users/$uid/device"
        data.forEach((deviceId, deviceData) {
          tempDevices.add(_parseDevice(deviceId, deviceData));
        });
      }

      setState(() {
        devices = tempDevices;
      });
    });
  }

  // Helper function untuk parsing data perangkat
  Map<String, dynamic> _parseDevice(
    String deviceId,
    Map<dynamic, dynamic> data,
  ) {
    String deviceLocation = data["deviceLocation"] ?? "Unknown";
    String deviceType = data["deviceType"] ?? "Unknown";
    Map<dynamic, dynamic>? temperatureData = data["temperatureData"];

    String latestTemperature = "N/A";
    String latestHumidity = "N/A";

    if (temperatureData != null && temperatureData.isNotEmpty) {
      var latestTimestamp = temperatureData.keys.reduce(
        (a, b) => a.compareTo(b) > 0 ? a : b,
      );
      var latestData = temperatureData[latestTimestamp];

      latestTemperature = latestData["temperature"]?.toString() ?? "N/A";
      latestHumidity = latestData["humidity"]?.toString() ?? "N/A";
    }

    return {
      "id": deviceId,
      "name": deviceId,
      "location": deviceLocation,
      "type": deviceType,
      "temperature": latestTemperature,
      "humidity": latestHumidity,
    };
  }

  void _handleSignOut() async {
    // Hapus token FCM agar tidak ada notifikasi yang dikirim ke device lama
    await FirebaseMessaging.instance.deleteToken();

    // Lakukan sign-out
    await _authService.signOut();

    // Navigasi ke halaman login
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Update index saat tab dipilih
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: CircleAvatar(
          backgroundImage: NetworkImage(widget.user.photoURL ?? ""),
          radius: 20,
        ),
        actions: [
          IconButton(icon: Icon(Icons.logout), onPressed: _handleSignOut),
        ],
      ),
      body: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: IndexedStack(
          index:
              _selectedIndex, // Mengatur halaman yang aktif berdasarkan tab yang dipilih
          children: [
            _buildDeviceList(),
            DeviceNameScreen(
              onNext: () {
                _pageController.animateToPage(
                  1,
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            ),
            ScheduleDataSendingScreen(
              availableDevices: {
                for (var device in devices)
                  device["id"]: {"deviceLocation": device["location"]},
              },
              userId: widget.user.uid,
            ),

            _buildChart(), // Chart Page ditampilkan di tab Chart
          ],
        ),
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor, // Mengikuti tema
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2),
            ],
          ),
          child: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(
                icon: Icon(Icons.add),
                label: 'Add Device',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.schedule),
                label: 'Automation',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.show_chart),
                label: 'Chart',
              ),
            ],
            currentIndex: _selectedIndex,
            selectedItemColor:
                Theme.of(
                  context,
                ).scaffoldBackgroundColor, // Warna ikon aktif sesuai tema
            unselectedItemColor: Theme.of(context).textTheme.bodyLarge?.color
                ?.withOpacity(0.6), // Warna ikon tidak aktif
            backgroundColor:
                Theme.of(context)
                    .bottomNavigationBarTheme
                    .backgroundColor, // Warna latar belakang navbar mengikuti tema
            onTap: _onItemTapped,
            type: BottomNavigationBarType.fixed,
          ),
        ),
      ),
    );
  }

  Widget _buildChart() {
    return Center(
      child: ChartPage(user: widget.user), // Berikan parameter user
    );
  }

  Widget _buildDeviceList() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Dashboard",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.darkText,
            ),
          ),
          SizedBox(height: 10),
          Expanded(
            child:
                devices.isEmpty
                    ? Center(child: CircularProgressIndicator())
                    : ListView.builder(
                      itemCount: devices.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: EdgeInsets.only(bottom: 15),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.3),
                                blurRadius: 1,
                                offset: Offset(0, 1),
                              ),
                            ],
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).cardTheme.color ??
                                    Colors.white,
                                Theme.of(
                                      context,
                                    ).cardTheme.color?.withOpacity(0.8) ??
                                    Colors.grey,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            color: Colors.transparent,
                            elevation: 0,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  // Ikon Device
                                  Container(
                                    padding: EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.memory,
                                      color: AppColors.darkPrimary,
                                      size: 40,
                                    ),
                                  ),
                                  SizedBox(width: 15),

                                  // Informasi Device
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          devices[index]["name"],
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.darkText,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          "Lokasi: ${devices[index]["location"]}",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: AppColors.darkText,
                                          ),
                                        ),
                                        Text(
                                          "Tipe: ${devices[index]["type"]}",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: AppColors.darkText,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Informasi Suhu & Kelembapan
                                  Column(
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.thermostat,
                                            color:
                                                Theme.of(
                                                  context,
                                                ).textTheme.bodyLarge?.color,
                                          ),
                                          SizedBox(width: 5),
                                          Text(
                                            "${devices[index]["temperature"]}°C",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.darkText,
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 5),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.water_drop,
                                            color:
                                                Theme.of(
                                                  context,
                                                ).textTheme.bodyLarge?.color,
                                          ),
                                          SizedBox(width: 5),
                                          Text(
                                            "${devices[index]["humidity"]}%",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.darkText,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}
