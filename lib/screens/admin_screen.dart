import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:travel_application/screens/login_screen.dart';
import 'admin_users_screen.dart';
import 'admin_hotels_screen.dart';
import 'admin_trips_screen.dart';
import 'admin_bookings_screen.dart';
import 'admin_reviews_screen.dart';

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
  int _selectedIndex = 0;

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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f9fa),
      appBar: AppBar(
        backgroundColor: const Color(0xfff6f9fa),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black, size: 28),
          onPressed: () {},
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Chào mừng trở lại, Admin 👋', style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
            Text('Đây là tổng quan hoạt động của hệ thống hôm nay.', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: Colors.black, size: 28),
                onPressed: () {},
              ),
              Positioned(
                right: 8,
                top: 10,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Text('12', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
          GestureDetector(
            onTap: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: const CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=11'),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchBar(),
                  const SizedBox(height: 16),
                  _buildSummaryGrid(),
                  const SizedBox(height: 16),
                  _buildRevenueChart(),
                  const SizedBox(height: 16),
                  _buildRecentBookings(),
                  const SizedBox(height: 16),
                  _buildQuickActions(),
                ],
              ),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Tổng quan'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Đơn đặt phòng'),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle, color: Colors.blue, size: 40), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.apartment), label: 'Khách sạn'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Báo cáo'),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Tìm kiếm...',
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text('⌘K', style: TextStyle(color: Colors.grey.shade400, fontSize: 16)),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildSummaryGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.6,
      children: [
        _buildSummaryCard(
          title: 'Người dùng',
          value: '2,458',
          trend: '12.5%',
          trendUp: true,
          icon: Icons.person,
          iconColor: Colors.blue,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUsersScreen()));
          },
        ),
        _buildSummaryCard(
          title: 'Khách sạn',
          value: '340',
          trend: '8.2%',
          trendUp: true,
          icon: Icons.domain,
          iconColor: Colors.purple,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminHotelsScreen()));
          },
        ),
        _buildSummaryCard(
          title: 'Đơn đặt phòng',
          value: '1,236',
          trend: '18.7%',
          trendUp: true,
          icon: Icons.shopping_bag_outlined,
          iconColor: Colors.green,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminBookingsScreen()));
          },
        ),
        _buildSummaryCard(
          title: 'Doanh thu',
          value: '1.234.000.000 đ',
          trend: '22.4%',
          trendUp: true,
          icon: Icons.attach_money,
          iconColor: Colors.orange,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required String trend,
    required bool trendUp,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 8),
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
              ],
            ),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Icon(trendUp ? Icons.arrow_upward : Icons.arrow_downward, color: trendUp ? Colors.green : Colors.red, size: 14),
                Text(' $trend', style: TextStyle(color: trendUp ? Colors.green : Colors.red, fontSize: 12)),
                const Text(' so với tuần trước', style: TextStyle(color: Colors.grey, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               const Text('Thống kê doanh thu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Text('7 ngày qua', style: TextStyle(fontSize: 12)),
                    Icon(Icons.keyboard_arrow_down, size: 16),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(height: 8),
          const Text('Doanh thu (VND)', style: TextStyle(color: Colors.grey, fontSize: 12)),
          const Row(
            children: [
              Text('1.234.000.000 đ', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(width: 8),
              Icon(Icons.arrow_upward, color: Colors.green, size: 16),
              Text('22.4%', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        const days = ['20/05', '21/05', '22/05', '23/05', '24/05', '25/05', '26/05'];
                        if (value.toInt() >= 0 && value.toInt() < days.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(days[value.toInt()], style: const TextStyle(color: Colors.grey, fontSize: 10)),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 100,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) {
                        return Text('${value.toInt()}M', style: const TextStyle(color: Colors.grey, fontSize: 10));
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 400,
                lineBarsData: [
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 60),
                      FlSpot(1, 150),
                      FlSpot(2, 280),
                      FlSpot(3, 240),
                      FlSpot(4, 330),
                      FlSpot(5, 240),
                      FlSpot(6, 320),
                    ],
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentBookings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Đơn đặt phòng mới', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () {},
                child: const Text('Xem tất cả', style: TextStyle(color: Colors.blue)),
              )
            ],
          ),
          _buildBookingItem(
            imageUrl: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?ixlib=rb-4.0.3&auto=format&fit=crop&w=100&q=80',
            title: 'Khách sạn Paradise Đà Nẵng',
            subtitle: 'Nguyễn Văn A • 26/05 – 28/05/2024',
            price: '2.450.000 đ',
            status: 'Đã xác nhận',
            statusColor: Colors.green,
          ),
          const Divider(),
          _buildBookingItem(
            imageUrl: 'https://images.unsplash.com/photo-1520250497591-112f2f40a3f4?ixlib=rb-4.0.3&auto=format&fit=crop&w=100&q=80',
            title: 'Khách sạn Sea View Nha Trang',
            subtitle: 'Trần Thị B • 27/05 – 30/05/2024',
            price: '3.120.000 đ',
            status: 'Chờ xác nhận',
            statusColor: Colors.blue,
          ),
          const Divider(),
          _buildBookingItem(
            imageUrl: 'https://images.unsplash.com/photo-1540541338287-41700207dee6?ixlib=rb-4.0.3&auto=format&fit=crop&w=100&q=80',
            title: 'Tour Đà Lạt 3N2Đ',
            subtitle: 'Lê Văn C • 28/05 – 30/05/2024',
            price: '1.890.000 đ',
            status: 'Chờ thanh toán',
            statusColor: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildBookingItem({
    required String imageUrl,
    required String title,
    required String subtitle,
    required String price,
    required String status,
    required Color statusColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(price, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(status, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Thao tác nhanh', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _buildActionIcon(Icons.domain_add, 'Thêm khách sạn', Colors.blue, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminHotelsScreen()));
              }),
              const SizedBox(width: 16),
              _buildActionIcon(Icons.flight_takeoff, 'Thêm tour', Colors.purple, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminTripsScreen()));
              }),
              const SizedBox(width: 16),
              _buildActionIcon(Icons.receipt_long, 'Quản lý đơn', Colors.green, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminBookingsScreen()));
              }),
              const SizedBox(width: 16),
              _buildActionIcon(Icons.manage_accounts, 'Người dùng', Colors.orange, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUsersScreen()));
              }),
              const SizedBox(width: 16),
              _buildActionIcon(Icons.reviews_rounded, 'Duyệt đánh giá', Colors.redAccent, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminReviewsScreen()));
              }),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildActionIcon(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 70,
            child: Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
