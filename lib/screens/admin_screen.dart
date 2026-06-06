import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:travel_application/screens/login_screen.dart';
import 'admin_users_screen.dart';
import 'admin_trips_screen.dart';
import 'admin_hotels_screen.dart';
import 'admin_bookings_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int usersCount = 0;
  int tripsCount = 0;
  int hotelsCount = 0;
  int bookingsCount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final db = FirebaseFirestore.instance;
      final usersSnap = await db.collection('accounts').get();
      final tripsSnap = await db.collection('trips').get();
      final hotelsSnap = await db.collection('hotels').get();
      final bookingsSnap = await db.collection('bookings').get();

      setState(() {
        usersCount = usersSnap.docs.length;
        tripsCount = tripsSnap.docs.length;
        hotelsCount = hotelsSnap.docs.length;
        bookingsCount = bookingsSnap.docs.length;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f9fa),
      appBar: AppBar(
        title: const Text('Admin Dashboard', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF059AA6),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          )
        ],
      ),
      body: isLoading  
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text('Tổng quan hệ thống', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  _buildStatCard('Người dùng', usersCount, Icons.people, Colors.blue, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUsersScreen()));
                  }),
                  _buildStatCard('Chuyến đi', tripsCount, Icons.flight, Colors.orange, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminTripsScreen()));
                  }),
                  _buildStatCard('Khách sạn', hotelsCount, Icons.hotel, Colors.purple, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminHotelsScreen()));
                  }),
                  _buildStatCard('Đơn đặt', bookingsCount, Icons.receipt, Colors.green, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminBookingsScreen()));
                  }),
                ],
              ),
            ],
          ),
    );
  }

  Widget _buildStatCard(String title, int count, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
          ]
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 8),
            Text(count.toString(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
