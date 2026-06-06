import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:travel_application/screens/login_screen.dart';
import 'admin_users_screen.dart';
import 'admin_hotels_screen.dart';
import 'admin_trips_screen.dart';
import 'admin_bookings_screen.dart';
import 'package:intl/intl.dart';
import 'admin_reviews_screen.dart';
import 'dart:math' as math;
import '../services/ai_assistant_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

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

  List<QueryDocumentSnapshot> _allBookings = [];
  String _revenueFilter = 'Tuần';
  final List<String> _filterOptions = ['Tuần', 'Tháng', 'Quý', '6 tháng', 'Năm'];

  double totalRevenue = 0;
  double chartRevenue = 0;
  List<Map<String, dynamic>> recentBookings = [];
  List<double> dailyRevenue = List.filled(7, 0);

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

      _allBookings = bookingsSnap.docs;

      double revenue = 0;
      List<Map<String, dynamic>> recent = [];

      var sortedDocs = _allBookings.toList()
        ..sort((a, b) {
          var aData = a.data() as Map<String, dynamic>;
          var bData = b.data() as Map<String, dynamic>;
          var aTime = aData['timestamp'] as Timestamp?;
          var bTime = bData['timestamp'] as Timestamp?;
          if (aTime != null && bTime != null) return bTime.compareTo(aTime);
          return 0;
        });

      for (var doc in sortedDocs) {
        var data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;

        if (recent.length < 5) {
          recent.add(data);
        }

        if (data['status'] == 'Đã duyệt') {
          double price = 0;
          if (data['price'] is num) {
            price = (data['price'] as num).toDouble();
          } else if (data['price'] is String) {
            price = double.tryParse(data['price'].toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
          }
          revenue += price;
        }
      }

      setState(() {
        usersCount = usersSnap.docs.length;
        tripsCount = tripsSnap.docs.length;
        hotelsCount = hotelsSnap.docs.length;
        bookingsCount = _allBookings.length;
        totalRevenue = revenue;
        recentBookings = recent;
        isLoading = false;
      });

      _processRevenue();
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _processRevenue() {
    final now = DateTime.now();
    double currentChartRevenue = 0;

    int numBins = 7;
    int daysPerBin = 1;
    if (_revenueFilter == 'Tuần') { numBins = 7; daysPerBin = 1; }
    else if (_revenueFilter == 'Tháng') { numBins = 30; daysPerBin = 1; }
    else if (_revenueFilter == 'Quý') { numBins = 12; daysPerBin = 7; }
    else if (_revenueFilter == '6 tháng') { numBins = 6; daysPerBin = 30; }
    else if (_revenueFilter == 'Năm') { numBins = 12; daysPerBin = 30; }

    List<double> rev = List.filled(numBins, 0);
    int maxDays = numBins * daysPerBin;

    for (var doc in _allBookings) {
      var data = doc.data() as Map<String, dynamic>;
      if (data['status'] == 'Đã duyệt') {
        double price = 0;
        if (data['price'] is num) {
          price = (data['price'] as num).toDouble();
        } else if (data['price'] is String) {
          price = double.tryParse(data['price'].toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;
        }

        var timestamp = data['timestamp'] as Timestamp?;
        if (timestamp != null) {
          final date = timestamp.toDate();
          final difference = now.difference(date).inDays;
          if (difference >= 0 && difference < maxDays) {
            int binIndex = difference ~/ daysPerBin;
            if (binIndex >= 0 && binIndex < numBins) {
              rev[(numBins - 1) - binIndex] += price;
              currentChartRevenue += price;
            }
          }
        } else {
           rev[numBins - 1] += price; 
           currentChartRevenue += price;
        }
      }
    }

    setState(() {
      chartRevenue = currentChartRevenue;
      dailyRevenue = rev;
    });
  }

  String _formatCurrency(num amount) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    return formatter.format(amount);
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminBookingsScreen())).then((_) => _loadStats());
    } else if (index == 2) {
      _showAIModal();
    } else if (index == 3) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminHotelsScreen())).then((_) => _loadStats());
    } else if (index == 4) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminTripsScreen())).then((_) => _loadStats());
    } else {
      setState(() { _selectedIndex = index; });
    }
  }

  void _runAITripAnalysis() async {
    Navigator.pop(context);
    _showAILoadingDialog('Đang phân tích Tour tiềm năng...');
    final aiService = AiAssistantService();
    final result = await aiService.analyzePotentialTrips(_allBookings.map((e) {
      var data = e.data() as Map<String, dynamic>;
      data['id'] = e.id;
      return data;
    }).toList());
    Navigator.pop(context); // close loading
    _showAIResultDialog('Phân tích Tour tiềm năng', result);
  }

  void _runAIHotelAnalysis() async {
    Navigator.pop(context);
    _showAILoadingDialog('Đang phân tích Khách sạn tiềm năng...');
    final aiService = AiAssistantService();
    final result = await aiService.analyzePotentialHotels(_allBookings.map((e) {
      var data = e.data() as Map<String, dynamic>;
      data['id'] = e.id;
      return data;
    }).toList());
    Navigator.pop(context); // close loading
    _showAIResultDialog('Phân tích Khách sạn tiềm năng', result);
  }

  void _runAIReviewAnalysis() async {
    Navigator.pop(context);
    _showAILoadingDialog('Đang kiểm duyệt và xử lý tự động...');
    final aiService = AiAssistantService();
    final evaluations = await aiService.analyzeAllPendingReviews();
    
    if (evaluations == null) {
      Navigator.pop(context);
      _showAIResultDialog('Lỗi', 'Có lỗi xảy ra khi phân tích bằng AI.');
      return;
    } 
    if (evaluations.isEmpty) {
      Navigator.pop(context);
      _showAIResultDialog('Tự động kiểm duyệt', 'Không có review nào đang chờ xử lý.');
      return;
    }

    int approved = 0;
    int rejected = 0;
    StringBuffer report = StringBuffer();

    for (var eval in evaluations) {
      final isPositive = eval['sentiment'] == 'Positive' || eval['sentiment'] == 'Neutral';
      if (isPositive) {
        await FirebaseFirestore.instance.collection('reviews').doc(eval['id']).update({'status': 'approved'});
        approved++;
        report.writeln('✅ **Duyệt:** ${eval['userName']} - "${eval['comment']}"');
        report.writeln('*(Lý do: ${eval['reason']})*\n');
      } else {
        await FirebaseFirestore.instance.collection('reviews').doc(eval['id']).update({'status': 'rejected'});
        rejected++;
        report.writeln('🚫 **Từ chối:** ${eval['userName']} - "${eval['comment']}"');
        report.writeln('*(Lý do: ${eval['reason']})*\n');
      }
    }

    Navigator.pop(context); // close loading

    String summary = '### Báo cáo Tự động xử lý\n\n'
        '**Tổng cộng:** ${evaluations.length} đánh giá\n'
        '- **Đã duyệt:** $approved\n'
        '- **Đã từ chối:** $rejected\n\n'
        '---\n\n' + report.toString();

    _showAIResultDialog('Kết quả xử lý tự động', summary);
  }

  void _showAILoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 20),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  void _showAIResultDialog(String title, String markdownData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: MarkdownBody(data: markdownData),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showAIModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'AI Assistant',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      child: Icon(Icons.tour, color: Colors.white, size: 20),
                    ),
                    title: const Text('Phân tích Tour tiềm năng'),
                    subtitle: const Text('Dựa vào lịch sử đặt Tour để gợi ý'),
                    onTap: _runAITripAnalysis,
                  ),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.purpleAccent,
                      child: Icon(Icons.hotel, color: Colors.white, size: 20),
                    ),
                    title: const Text('Phân tích Khách sạn tiềm năng'),
                    subtitle: const Text('Dựa vào lịch sử đặt Hotel để gợi ý'),
                    onTap: _runAIHotelAnalysis,
                  ),
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.redAccent,
                      child: Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                    ),
                    title: const Text('Tự động Kiểm duyệt Review'),
                    subtitle: const Text('AI tự động duyệt hoặc từ chối đánh giá'),
                    onTap: _runAIReviewAnalysis,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          }
        );
      },
    );
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
            Text(
              'Chào mừng trở lại, Admin 👋',
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Đây là tổng quan hoạt động của hệ thống hôm nay.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.black,
                  size: 28,
                ),
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
                  child: const Text(
                    '12',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
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
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Tổng quan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Đơn đặt phòng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.smart_toy, color: Colors.blue, size: 36),
            label: 'AI',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.apartment),
            label: 'Khách sạn',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.tour),
            label: 'Chuyến đi',
          ),
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
            child: Text(
              '⌘K',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 16),
            ),
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
          value: NumberFormat.decimalPattern('vi_VN').format(usersCount),
          trend: '12.5%',
          trendUp: true,
          icon: Icons.person,
          iconColor: Colors.blue,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
            );
          },
        ),
        _buildSummaryCard(
          title: 'Khách sạn',
          value: NumberFormat.decimalPattern('vi_VN').format(hotelsCount),
          trend: '8.2%',
          trendUp: true,
          icon: Icons.domain,
          iconColor: Colors.purple,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminHotelsScreen()),
            );
          },
        ),
        _buildSummaryCard(
          title: 'Đơn đặt phòng',
          value: NumberFormat.decimalPattern('vi_VN').format(bookingsCount),
          trend: '18.7%',
          trendUp: true,
          icon: Icons.shopping_bag_outlined,
          iconColor: Colors.green,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AdminBookingsScreen()),
            );
          },
        ),
        _buildSummaryCard(
          title: 'Doanh thu',
          value: _formatCurrency(totalRevenue),
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
                Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Icon(
                  trendUp ? Icons.arrow_upward : Icons.arrow_downward,
                  color: trendUp ? Colors.green : Colors.red,
                  size: 14,
                ),
                Text(
                  ' $trend',
                  style: TextStyle(
                    color: trendUp ? Colors.green : Colors.red,
                    fontSize: 12,
                  ),
                ),
                const Text(
                  ' so với tuần trước',
                  style: TextStyle(color: Colors.grey, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart() {
    double maxRevenue = dailyRevenue.isNotEmpty
        ? dailyRevenue.reduce(math.max)
        : 0;
    if (maxRevenue == 0) maxRevenue = 1000000;
    double interval = maxRevenue / 4;
    if (interval == 0) interval = 1000000;

    int numBins = dailyRevenue.length;
    int daysPerBin = 1;
    if (_revenueFilter == 'Tuần') daysPerBin = 1;
    else if (_revenueFilter == 'Tháng') daysPerBin = 1;
    else if (_revenueFilter == 'Quý') daysPerBin = 7;
    else if (_revenueFilter == '6 tháng') daysPerBin = 30;
    else if (_revenueFilter == 'Năm') daysPerBin = 30;

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
              const Text(
                'Thống kê doanh thu',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _revenueFilter,
                    icon: const Icon(Icons.keyboard_arrow_down, size: 16),
                    style: const TextStyle(fontSize: 12, color: Colors.black),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() { _revenueFilter = newValue; });
                        _processRevenue();
                      }
                    },
                    items: _filterOptions.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Doanh thu (VND)',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          Row(
            children: [
              Text(
                _formatCurrency(chartRevenue),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index < 0 || index >= numBins) return const Text('');
                        
                        if (numBins > 12 && index % 5 != 0 && index != numBins - 1) return const Text('');

                        String label = '';
                        int daysAgo = (numBins - 1 - index) * daysPerBin;
                        DateTime d = DateTime.now().subtract(Duration(days: daysAgo));
                        
                        if (_revenueFilter == 'Tuần' || _revenueFilter == 'Tháng') {
                           label = DateFormat('dd/MM').format(d);
                        } else if (_revenueFilter == 'Quý') {
                           label = 'T${d.month}';
                        } else if (_revenueFilter == '6 tháng' || _revenueFilter == 'Năm') {
                           label = 'T${d.month}/${d.year.toString().substring(2)}';
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: interval,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${(value / 1000000).toStringAsFixed(0)}M',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (numBins - 1).toDouble(),
                minY: 0,
                maxY: maxRevenue * 1.2,
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(
                      numBins,
                      (index) => FlSpot(index.toDouble(), dailyRevenue[index]),
                    ),
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
              const Text(
                'Đơn đặt phòng mới',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminBookingsScreen(),
                    ),
                  );
                },
                child: const Text(
                  'Xem tất cả',
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
          ...recentBookings.map((booking) {
            String status = booking['status'] ?? 'Chờ duyệt';
            Color statusColor = status == 'Đã duyệt'
                ? Colors.green
                : (status == 'Đã hủy' ? Colors.red : Colors.orange);
            double price = 0;
            if (booking['price'] is num) {
              price = (booking['price'] as num).toDouble();
            } else if (booking['price'] is String) {
              price =
                  double.tryParse(
                    booking['price'].toString().replaceAll(
                      RegExp(r'[^0-9.]'),
                      '',
                    ),
                  ) ??
                  0;
            }

            return Column(
              children: [
                _buildBookingItem(
                  imageUrl: booking['type'] == 'hotel'
                      ? 'https://images.unsplash.com/photo-1566073771259-6a8506099945?w=100&q=80'
                      : 'https://images.unsplash.com/photo-1540541338287-41700207dee6?w=100&q=80',
                  title:
                      booking['hotelName'] ??
                      booking['tripName'] ??
                      'Đơn đặt mới',
                  subtitle:
                      '${booking['customerName'] ?? booking['userEmail'] ?? 'Không rõ'} • ${booking['guestCount'] ?? 1} người',
                  price: _formatCurrency(price),
                  status: status,
                  statusColor: statusColor,
                ),
                const Divider(),
              ],
            );
          }).toList(),
          if (recentBookings.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Chưa có đơn đặt nào',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
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
            child: Image.network(
              imageUrl,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
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
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
        const Text(
          'Thao tác nhanh',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              _buildActionIcon(
                Icons.domain_add,
                'Thêm khách sạn',
                Colors.blue,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminHotelsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              _buildActionIcon(
                Icons.flight_takeoff,
                'Thêm tour',
                Colors.purple,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminTripsScreen()),
                  );
                },
              ),
              const SizedBox(width: 16),
              _buildActionIcon(
                Icons.receipt_long,
                'Quản lý đơn',
                Colors.green,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminBookingsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              _buildActionIcon(
                Icons.manage_accounts,
                'Người dùng',
                Colors.orange,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
                  );
                },
              ),
              const SizedBox(width: 16),
              _buildActionIcon(
                Icons.reviews_rounded,
                'Duyệt đánh giá',
                Colors.redAccent,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AdminReviewsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionIcon(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
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
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
