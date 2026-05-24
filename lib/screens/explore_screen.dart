import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/hotel_model.dart';
import '../services/api_service.dart';
import 'detail_explore_screen.dart';
import 'home_screen.dart';
import 'chat_screen.dart';
import 'saved_trips_screen.dart';
import 'profile_screen.dart';
import '../helper/navigation_helper.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.9);
  final MapController _mapController = MapController();

  int _currentPage = 0;
  bool _isLoading = true;
  List<HotelModel> _hotels = [];
  final Color tealColor = const Color(0xFF139CAE);

  @override
  void initState() {
    super.initState();
    _loadHotels();
  }

  Future<void> _loadHotels() async {
    final hotels = await ApiService.fetchHotels();
    if (mounted) {
      setState(() {
        _hotels = hotels;
        _isLoading = false;
      });
    }
  }

  // ĐÃ SỬA LỖI NÚT START
  Future<void> _launchMaps(String address) async {
    final String encodedAddress = Uri.encodeComponent(address);
    // Đây là URL Scheme chuẩn của Google Maps
    final Uri mapUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedAddress');

    try {
      if (await canLaunchUrl(mapUrl)) {
        await launchUrl(mapUrl, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch maps');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở ứng dụng Bản đồ trên thiết bị này.')),
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: tealColor))
          : _hotels.isEmpty
          ? const Center(child: Text("Không có khách sạn nào"))
          : _buildMainContent(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Explore', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(_hotels.length, (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 6),
                        height: 6, width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(color: _currentPage == index ? tealColor : Colors.grey[300], borderRadius: BorderRadius.circular(3)),
                      )),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 350,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _hotels.length,
                  onPageChanged: (int page) {
                    setState(() => _currentPage = page);
                    _mapController.move(LatLng(_hotels[page].lat, _hotels[page].lng), 15.0);
                  },
                  itemBuilder: (context, index) => _buildCardItem(_hotels[index]),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(initialCenter: LatLng(_hotels[0].lat, _hotels[0].lng), initialZoom: 15.0),
                  children: [
                    // ĐÃ SỬA LỖI BẢN ĐỒ VÀNG ĐEN Ở ĐÂY
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.travel.app', // Cần khai báo tên app để không bị block
                    ),
                    MarkerLayer(markers: [
                      Marker(point: LatLng(_hotels[_currentPage].lat, _hotels[_currentPage].lng), width: 50, height: 50, child: Icon(Icons.location_on, color: tealColor, size: 45)),
                    ]),
                  ],
                ),
                Positioned(
                  bottom: 24, left: 24,
                  child: ElevatedButton.icon(
                    onPressed: () => _launchMaps(_hotels[_currentPage].address),
                    icon: const Icon(Icons.near_me, color: Colors.white),
                    label: const Text('Start', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(backgroundColor: tealColor, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), shape: const StadiumBorder()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardItem(HotelModel hotel) {
    // ĐÃ SỬA LỖI HÌNH ẢNH TRỐNG: Nếu link rỗng, dùng link ảnh mặc định
    String imageUrl = hotel.imageUrls.isNotEmpty && hotel.imageUrls[0].trim().isNotEmpty
        ? hotel.imageUrls[0]
        : 'https://images.unsplash.com/photo-1564501049412-61c2a3083791?q=80&w=800&auto=format&fit=crop';

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DetailExploreScreen(hotel: hotel))),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))]),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Có thêm errorBuilder để lỡ link ảnh bị chết (404) thì không bị sập app
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
                ),
              ),
              Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black54, Colors.transparent]))),
              Positioned(
                top: 24, left: 24, right: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(hotel.name, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold), maxLines: 1),
                    Row(children: [const Icon(Icons.location_on_outlined, color: Colors.white70, size: 16), Expanded(child: Text(hotel.address, style: const TextStyle(color: Colors.white70), maxLines: 1))]),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: tealColor,
      currentIndex: 1,
      onTap: (index) {
        if (index == 1) return;
        if (index == 0) navigateToTab(context, const HomeScreen());
        else if (index == 2) navigateToTab(context, const ChatScreen());
        else if (index == 3) navigateToTab(context, const SavedTripsScreen());
        else if (index == 4) navigateToTab(context, const ProfileScreen());
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.location_on), label: 'Explore'),
        BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded), label: 'Chat'),
        BottomNavigationBarItem(icon: Icon(Icons.favorite_rounded), label: 'Wishlist'),
        BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
      ],
    );
  }
}