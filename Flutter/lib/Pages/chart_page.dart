import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChartPage extends StatefulWidget {
  final User user;
  ChartPage({required this.user});

  @override
  _ChartPageState createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  Map<String, List<FlSpot>> temperatureData = {};
  Map<String, List<FlSpot>> humidityData = {};

  @override
  void initState() {
    super.initState();
    _fetchChartData();
  }

  void _fetchChartData() async {
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

      Map<String, List<FlSpot>> tempData = {};
      Map<String, List<FlSpot>> humData = {};

      DateTime today = DateTime.now();
      DateTime startOfDay = DateTime(today.year, today.month, today.day);

      if (userRole == "admin") {
        // Admin harus looping ke setiap user
        data.forEach((userId, userDevices) {
          if (userDevices is Map && userDevices.containsKey("device")) {
            userDevices["device"].forEach((deviceId, deviceData) {
              _parseChartData(
                deviceId,
                deviceData,
                tempData,
                humData,
                startOfDay,
              );
            });
          }
        });
      } else {
        // User biasa langsung baca "users/$uid/device"
        data.forEach((deviceId, deviceData) {
          _parseChartData(deviceId, deviceData, tempData, humData, startOfDay);
        });
      }

      setState(() {
        temperatureData = tempData;
        humidityData = humData;
      });
    });
  }

  // Helper function untuk parsing data perangkat ke chart
  void _parseChartData(
    String deviceId,
    Map<dynamic, dynamic> data,
    Map<String, List<FlSpot>> tempData,
    Map<String, List<FlSpot>> humData,
    DateTime startOfDay,
  ) {
    if (data["temperatureData"] == null) return;

    Map<dynamic, dynamic> tempRecords = data["temperatureData"];
    List<MapEntry<dynamic, dynamic>> sortedTempRecords =
        tempRecords.entries.toList()..sort(
          (a, b) => DateTime.parse(b.key).compareTo(DateTime.parse(a.key)),
        );

    List<FlSpot> tempSpots = [];
    List<FlSpot> humSpots = [];

    int count = 0;
    for (var entry in sortedTempRecords) {
      try {
        String timestamp = entry.key as String;
        Map<dynamic, dynamic> readings = entry.value;

        DateTime recordTime = DateTime.parse(timestamp);

        if (recordTime.isAfter(startOfDay)) {
          double temp = (readings["temperature"] ?? 0).toDouble();
          double hum = (readings["humidity"] ?? 0).toDouble();

          tempSpots.add(
            FlSpot(recordTime.millisecondsSinceEpoch.toDouble(), temp),
          );
          humSpots.add(
            FlSpot(recordTime.millisecondsSinceEpoch.toDouble(), hum),
          );

          count++;
          if (count >= 20) break;
        }
      } catch (e) {
        print("Error parsing timestamp or readings: $e");
      }
    }

    tempData[deviceId] = tempSpots;
    humData[deviceId] = humSpots;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Grafik Perangkat',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 3,
      ),
      body: SingleChildScrollView(
        child: Column(
          children:
              temperatureData.keys.map((deviceId) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Device: $deviceId",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 10),
                          _buildChart(
                            temperatureData[deviceId]!,
                            humidityData[deviceId]!,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  Widget _buildChart(List<FlSpot> tempData, List<FlSpot> humData) {
    return SizedBox(
      height: 300,
      child: Column(
        children: [
          Expanded(
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 100,
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (value, meta) {
                        DateTime recordTime =
                            DateTime.fromMillisecondsSinceEpoch(value.toInt());

                        String timeLabel =
                            "${recordTime.hour}:${recordTime.minute.toString().padLeft(2, '0')}";
                        return Text(
                          timeLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: tempData,
                    isCurved: false,
                    gradient: LinearGradient(
                      colors: [Colors.orange, Colors.red],
                    ),
                    barWidth: 2, // Perbesar barWidth untuk efek lebih jelas
                    isStrokeCapRound: true,
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.orange.withOpacity(0.5),
                          Colors.red.withOpacity(0.2),
                        ],
                      ),
                    ),
                    dotData: FlDotData(
                      show: false,
                    ), // Hilangkan titik untuk tampilan lebih bersih
                  ),

                  LineChartBarData(
                    spots: humData,
                    isCurved: false,
                    gradient: LinearGradient(
                      colors: [Colors.green, Colors.blue],
                    ),
                    barWidth: 2, // Perbesar barWidth untuk efek lebih jelas
                    isStrokeCapRound: true,
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.green.withOpacity(0.5),
                          Colors.blue.withOpacity(0.2),
                        ],
                      ),
                    ),
                    dotData: FlDotData(
                      show: false,
                    ), // Hilangkan titik untuk tampilan lebih bersih
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend("Temperature", Colors.orange, Icons.thermostat),
              SizedBox(width: 10),
              _buildLegend("Humidity", Colors.green, Icons.water_drop),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, Color color, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 14)),
      ],
    );
  }
}
