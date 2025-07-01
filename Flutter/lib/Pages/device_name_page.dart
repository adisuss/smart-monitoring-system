import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:zephlyr/main.dart';
import 'package:zephlyr/pages/wifi_provisioning.dart';

class DeviceType {
  final String name;
  DeviceType(this.name);
}

class DeviceNameScreen extends StatefulWidget {
  final VoidCallback onNext;

  DeviceNameScreen({required this.onNext});

  @override
  _DeviceNameScreenState createState() => _DeviceNameScreenState();
}

class _DeviceNameScreenState extends State<DeviceNameScreen> {
  final TextEditingController _deviceNameController = TextEditingController();
  final TextEditingController _deviceLocationController =
      TextEditingController();

  String? _selectedDeviceType;
  final List<DeviceType> deviceTypes = [
    DeviceType('Sensor'),
    DeviceType('Controller'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Detail Perangkat',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 3,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Masukkan Informasi Perangkat",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              _buildCardForm(),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _onNextPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).cardTheme.color,
                    padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Lanjutkan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkText,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardForm() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      shadowColor: Colors.black26,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTextField(
              _deviceNameController,
              "Nama Perangkat",
              Icons.memory,
            ),
            SizedBox(height: 15),
            _buildDropdownField(),
            SizedBox(height: 15),
            _buildTextField(
              _deviceLocationController,
              "Lokasi Perangkat",
              Icons.location_on,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String hint,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Theme.of(context).primaryColor),
        hintText: hint,
        hintStyle: TextStyle(color: AppColors.darkText),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: AppColors.darkBackground,
      ),
    );
  }

  Widget _buildDropdownField() {
    return DropdownButtonFormField<String>(
      value: _selectedDeviceType,
      items:
          deviceTypes.map((DeviceType deviceType) {
            return DropdownMenuItem<String>(
              value: deviceType.name,
              child: Text(deviceType.name),
            );
          }).toList(),
      dropdownColor: AppColors.darkBackground,
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.sensors, color: Theme.of(context).primaryColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: AppColors.darkBackground,
      ),
      style: TextStyle(color: AppColors.darkText), // Warna teks dropdown
      hint: Text(
        'Pilih Tipe Perangkat',
        style: TextStyle(color: AppColors.darkText), // Warna hint text
      ),
      onChanged: (String? newValue) {
        setState(() {
          _selectedDeviceType = newValue;
        });
      },
    );
  }

  void _onNextPressed() async {
    if (_deviceNameController.text.isNotEmpty &&
        _selectedDeviceType != null &&
        _deviceLocationController.text.isNotEmpty) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception("User belum login.");

        final fcmToken = await FirebaseMessaging.instance.getToken();

        final deviceRef = FirebaseDatabase.instance.ref(
          'users/${user.uid}/device/${_deviceNameController.text}',
        );

        await deviceRef.set({
          'deviceType': _selectedDeviceType,
          'deviceLocation': _deviceLocationController.text,
          'schedule': {
            'daily': true,
            'hour': 23,
            'minute': 40,
            'high': 35,
            'low': 25,
            'fcmToken': fcmToken ?? '',
          },
        });

        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder:
                (context, animation, secondaryAnimation) =>
                    WifiProvisioningScreen(
                      deviceName: _deviceNameController.text,
                      deviceType: _selectedDeviceType!,
                      deviceLocation: _deviceLocationController.text,
                    ),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan data ke Firebase: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Harap lengkapi semua data')));
    }
  }
}
