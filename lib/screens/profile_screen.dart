import 'package:flutter/material.dart';
import 'package:travel_application/screens/login_screen.dart';
import '../helper/local_storage_service.dart';
import '../helper/navigation_helper.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'explore_screen.dart';
import 'saved_trips_screen.dart';
import 'chat_screen.dart';
import 'pending_bookings_screen.dart';

const Color tealColor = Color(0xFF059AA6);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final int selectedBottomIndex = 4;
  final LocalStorageService _localStorageService = LocalStorageService();
  
  int savedCount = 0;
  int bookedCount = 0;
  bool isLoadingStats = true;
  String userName = 'Pham Dang Huan';
  String userEmail = 'huan@gmail.com';

  @override
  void initState() {
    super.initState();
    loadProfileStats();
  }

  Future<void> loadProfileStats() async {
    try {
      final favorites = await _localStorageService.getFavoriteTripIds();
      final bookings = await _localStorageService.getBookings();
      final name = await _localStorageService.getUserName();
      final email = await _localStorageService.getUserEmail();
      
      if (!mounted) return;

      setState(() {
        savedCount = favorites.length;
        bookedCount = bookings.length;
        if (name != null && name.isNotEmpty) {
          userName = name;
        }
        if (email != null && email.isNotEmpty) {
          userEmail = email;
        }
        isLoadingStats = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoadingStats = false;
      });
    }
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Đăng xuất', style: TextStyle(fontWeight: FontWeight.bold)),
          content: const Text('Bạn có muốn đăng xuất khỏi TravelApp không?'),
          actions: [
            TextButton(
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text('Đăng xuất', style: TextStyle(color: tealColor, fontWeight: FontWeight.bold)),
              onPressed: () async {
                final navigator = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                
                navigator.pop(); // Dismiss dialog immediately
                
                await _localStorageService.clearUserSession();
                await AuthService().signOut();

                messenger.showSnackBar(
                  const SnackBar(content: Text('Đã đăng xuất thành công.')),
                );
                
                // Clear the back stack and direct straight to LoginScreen
                if (mounted) {
                  navigator.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showAboutDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 5,
                width: 45,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 18),
              const CircleAvatar(
                backgroundColor: tealColor,
                radius: 28,
                child: Icon(Icons.travel_explore, color: Colors.white, size: 30),
              ),
              const SizedBox(height: 12),
              const Text(
                'Travel Mobile App v1.0.0',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Text(
                'Được phát triển với Flutter & Material 3. Hỗ trợ đặt tour, xem bản đồ du lịch, tư vấn qua AI Chatbot và quét mã thanh toán VietQR chuyển khoản cực kỳ nhanh chóng.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.45),
              ),
              const SizedBox(height: 22),
              Text(
                '© 2026. All rights reserved.',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f9fa),
      body: CustomScrollView(
        slivers: [
          _buildSliverHeader(),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildStatsCard(),
                const SizedBox(height: 20),
                _buildSectionTitle('Du lịch của tôi'),
                const SizedBox(height: 8),
                _buildMenuCard([
                  _buildMenuItem(
                    icon: Icons.bookmark_added_rounded,
                    title: 'Tour đã đặt',
                    subtitle: 'Danh sách tour đã hoàn tất chuyển khoản',
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SavedTripsScreen()),
                      );
                      loadProfileStats();
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.favorite_rounded,
                    title: 'Danh sách yêu thích',
                    subtitle: 'Các địa điểm bạn đã thả tim',
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SavedTripsScreen()),
                      );
                      loadProfileStats();
                    },
                  ),
                  _buildMenuItem(
                    icon: Icons.pending_actions_rounded,
                    title: 'Đang chờ duyệt',
                    subtitle: 'Đơn đặt tour đang chờ admin xác nhận',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PendingBookingsScreen()),
                      );
                    },
                  ),
                ]),
                const SizedBox(height: 20),
                _buildSectionTitle('Hệ thống & Cài đặt'),
                const SizedBox(height: 8),
                _buildMenuCard([
                  _buildMenuItem(
                    icon: Icons.info_outline_rounded,
                    title: 'Về TravelApp',
                    subtitle: 'Thông tin phiên bản ứng dụng',
                    onTap: _showAboutDialog,
                  ),
                ]),
                const SizedBox(height: 24),
                SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _handleLogout,
                    icon: const Icon(Icons.logout_rounded, color: Colors.white),
                    label: const Text(
                      'ĐĂNG XUẤT TÀI KHOẢN',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 1),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ]),
            ),
          )
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return 'U';
    List<String> parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'U';
  }

  Widget _buildSliverHeader() {
    return SliverAppBar(
      expandedHeight: 210.0,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: tealColor,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [Color(0xFF0F8696), Color(0xFF1CB0C3)],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 36,
                    backgroundColor: tealColor,
                    child: Text(
                      _getInitials(userName),
                      style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  userEmail,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem(
            value: isLoadingStats ? '...' : bookedCount.toString(),
            label: 'Đã Đặt Tour',
            icon: Icons.directions_bus_rounded,
            color: tealColor,
          ),
          Container(height: 40, width: 1.2, color: Colors.grey.shade200),
          _buildStatItem(
            value: isLoadingStats ? '...' : savedCount.toString(),
            label: 'Yêu Thích',
            icon: Icons.favorite,
            color: Colors.redAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({required String value, required String label, required IconData icon, required Color color}) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.025),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(children: items),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? tealColor).withOpacity(0.08),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor ?? tealColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildBottomNav() {
    final icons = [
      Icons.home,
      Icons.location_on,
      Icons.chat_bubble,
      Icons.favorite,
      Icons.person,
    ];

    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(icons.length, (index) {
          final selected = selectedBottomIndex == index;

          return GestureDetector(
            onTap: () {
              if (selected) return;

              if (index == 0) {
                navigateToTab(context, const HomeScreen());
              } else if (index == 1) {
                navigateToTab(context, const ExploreScreen());
              } else if (index == 2) {
                navigateToTab(context, const ChatScreen());
              } else if (index == 3) {
                navigateToTab(context, const SavedTripsScreen());
              }
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icons[index],
                  color: selected ? tealColor : Colors.grey,
                  size: 27,
                ),
                const SizedBox(height: 4),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: selected ? tealColor : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}
