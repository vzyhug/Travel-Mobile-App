import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/hotel_model.dart';
import '../services/api_service.dart';
import 'detail_explore_screen.dart';
import 'home_screen.dart';
import 'saved_trips_screen.dart';

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
    _loadHotelsFromApi();
  }

  // Hàm gọi API thực tế
  Future<void> _loadHotelsFromApi() async {
    final hotels = await ApiService.fetchHotels();
    if (mounted) {
      setState(() {
        _hotels = hotels;
        _isLoading = false;
      });
    }
  }

  Future<void> _launchMaps(String address) async {
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: tealColor))
          : _hotels.isEmpty
          ? const Center(child: Text("Không tải được dữ liệu khách sạn"))
          : Column(
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
                      const Text(
                        'Explore',
                        style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: List.generate(
                          _hotels.length,
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
                ),

                // Khu vực Carousel
                SizedBox(
                  height: 350,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _hotels.length,
                    onPageChanged: (int page) {
                      setState(() {
                        _currentPage = page;
                      });
                      _mapController.move(
                        LatLng(_hotels[page].lat, _hotels[page].lng),
                        15.0,
                      );
                    },
                    itemBuilder: (context, index) {
                      final hotel = _hotels[index];
                      return _buildCardItem(hotel);
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Khu vực Map
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: LatLng(_hotels[0].lat, _hotels[0].lng),
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
                            point: LatLng(_hotels[_currentPage].lat, _hotels[_currentPage].lng),
                            width: 50,
                            height: 50,
                            child: Icon(Icons.location_on, color: tealColor, size: 45),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Positioned(
                    bottom: 24,
                    left: 24,
                    child: ElevatedButton.icon(
                      onPressed: () => _launchMaps(_hotels[_currentPage].address),
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
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildCardItem(HotelModel hotel) {
    String imageUrl = hotel.imageUrls.isNotEmpty
        ? hotel.imageUrls[0]
        : 'https://images.unsplash.com/photo-1564501049412-61c2a3083791?q=80&w=800&auto=format&fit=crop';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailExploreScreen(hotel: hotel),
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
              child: Image.network(imageUrl, fit: BoxFit.cover),
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
                    hotel.name,
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
                          hotel.address,
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
    final icons = [
      Icons.home,
      Icons.location_on,
      Icons.chat_bubble,
      Icons.favorite,
      Icons.person,
    ];

    int currentSelectedIndex = 1;

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
          final selected = currentSelectedIndex == index;

          return GestureDetector(
            onTap: () {
              if (index == 0) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                );
              } else if (index == 3) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SavedTripsScreen()),
                );
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