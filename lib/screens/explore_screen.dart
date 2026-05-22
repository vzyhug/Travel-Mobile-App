import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;

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

  final Color tealColor = const Color(0xFF139CAE);

  // Danh sách sẽ chứa 3 địa điểm ngẫu nhiên
  List<Map<String, dynamic>> randomHotels = [];
  List<Map<String, dynamic>> allHotels = [];
  bool _isLoadingHotels = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _fetchAndLoadHotels();
  }

  Future<void> _fetchAndLoadHotels() async {
    try {
      final response = await http.get(Uri.parse('https://my-json-server.typicode.com/vzyhug/data-travel-hotels/hotels'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<Map<String, dynamic>> hotels = data.map((e) => Map<String, dynamic>.from(e)).toList();
        if (mounted) {
          setState(() {
            allHotels = hotels;
            if (allHotels.isNotEmpty) {
              final random = Random();
              List<Map<String, dynamic>> shuffled = List.from(allHotels);
              shuffled.shuffle(random);
              randomHotels = shuffled.take(3).toList();
            }
            _isLoadingHotels = false;
          });
        }
      } else {
        throw Exception('Server returned status: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = e.toString();
          _isLoadingHotels = false;
        });
      }
    }
  }

  Future<void> _launchMaps(String address, double lat, double lng) async {
    final query = Uri.encodeComponent(address);
    final Uri mapUrl = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');

    if (await canLaunchUrl(mapUrl)) {
      await launchUrl(mapUrl, mode: LaunchMode.externalApplication);
    } else {
      debugPrint("Không thể mở bản đồ cho địa chỉ này.");
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
    if (_isLoadingHotels) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: Center(
          child: CircularProgressIndicator(color: tealColor),
        ),
      );
    }

    if (_errorMsg != null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Lỗi tải dữ liệu khách sạn: $_errorMsg',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoadingHotels = true;
                      _errorMsg = null;
                    });
                    _fetchAndLoadHotels();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: tealColor),
                  child: const Text('Thử lại', style: TextStyle(color: Colors.white)),
                )
              ],
            ),
          ),
        ),
      );
    }

    if (randomHotels.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        body: const Center(
          child: Text('Không có dữ liệu khách sạn'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Explore',
                            style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: List.generate(
                              randomHotels.length,
                                  (index) => AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.only(right: 6),
                                height: 6,
                                width: _currentPage == index ? 24 : 8,
                                decoration: BoxDecoration(
                                  color: _currentPage == index ? tealColor : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      //Icon(Icons.notifications_none, size: 28, color: Colors.grey[800]),
                    ],
                  ),
                ),

                // 2. Khu vực Carousel(PageView)
                SizedBox(
                  height: 350,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: randomHotels.length,
                    onPageChanged: (int page) {
                      setState(() {
                        _currentPage = page;
                      });
                      // Đồng bộ Map: Di chuyển bản đồ khi vuốt thẻ
                      _mapController.move(
                        LatLng(randomHotels[page]['lat'], randomHotels[page]['lng']),
                        15.0,
                      );
                    },
                    itemBuilder: (context, index) {
                      var hotel = randomHotels[index];
                      // Xử lý logic ảnh (có thể rỗng trong db.json)
                      String imageUrl = (hotel['imageUrls'] != null && hotel['imageUrls'].isNotEmpty)
                          ? hotel['imageUrls'][0]
                          : 'https://images.unsplash.com/photo-1564501049412-61c2a3083791?q=80&w=800&auto=format&fit=crop'; // Ảnh mặc định
                      return _buildCardItem(hotel, hotel['address'], imageUrl);
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // 3. Khu vực Map (Bên dưới)
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: LatLng(randomHotels[0]['lat'], randomHotels[0]['lng']),
                      initialZoom: 15.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.your_app.app',
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(randomHotels[_currentPage]['lat'], randomHotels[_currentPage]['lng']),
                            width: 50,
                            height: 50,
                            child: Icon(Icons.location_on, color: tealColor, size: 45),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // 4. Nút Start(Mở Google Maps)
                  Positioned(
                    bottom: 24,
                    left: 24,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Gọi hàm mở URL Launcher
                        _launchMaps(
                            randomHotels[_currentPage]['address'],
                            randomHotels[_currentPage]['lat'],
                            randomHotels[_currentPage]['lng']
                        );
                      },
                      icon: const Icon(Icons.near_me, color: Colors.white, size: 20),
                      label: const Text(
                        'Start',
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tealColor,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      // Giữ nguyên BottomNavigationBar từ UI trước
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildCardItem(Map<String, dynamic> hotelData, String address, String imgUrl) {
    return GestureDetector(
      onTap: () {
        // Khi người dùng bấm vào thẻ, lệnh này sẽ mở DetailScreen và truyền dữ liệu sang
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailExploreScreen(destinationData: hotelData),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10.0),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 5))
            ]
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.network(imgUrl, fit: BoxFit.cover),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                  stops: const [0.0, 0.5],
                ),
              ),
            ),
            Positioned(
              top: 24,
              left: 24,
              right: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    // 2. Lấy tên từ biến hotelData
                    hotelData['name'],
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: Colors.white70, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          address,
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: tealColor,
      unselectedItemColor: Colors.grey[400],
      showSelectedLabels: false,
      showUnselectedLabels: false,
      currentIndex: 1,
      onTap: (index) {
        if (index == 1) return;
        if (index == 0) {
          navigateToTab(context, const HomeScreen());
        } else if (index == 2) {
          navigateToTab(context, const ChatScreen());
        } else if (index == 3) {
          navigateToTab(context, const SavedTripsScreen());
        } else if (index == 4) {
          navigateToTab(context, const ProfileScreen());
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_filled, size: 28), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.location_on, size: 28), label: 'Explore'),
        BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_rounded, size: 26), label: 'Chat'),
        BottomNavigationBarItem(icon: Icon(Icons.favorite_rounded, size: 28), label: 'Wishlist'),
        BottomNavigationBarItem(icon: Icon(Icons.person_rounded, size: 28), label: 'Profile'),
      ],
    );
  }
}