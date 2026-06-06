import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
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

  String _formatCurrency(num value) {
    final amount = value.toInt();
    final text = amount.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    return '$text đ';
  }

  // ĐÃ SỬA LỖI NÚT START
  Future<void> _launchMaps(String address) async {
    final String encodedAddress = Uri.encodeComponent(address);
    // Đây là URL Scheme chuẩn của Google Maps
    final Uri mapUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$encodedAddress',
    );

    try {
      if (await canLaunchUrl(mapUrl)) {
        await launchUrl(mapUrl, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch maps');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không thể mở ứng dụng Bản đồ trên thiết bị này.'),
          ),
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
        Expanded(
          flex: 5,
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
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.travel.app',
                  ),
                  MarkerLayer(
                    markers: _hotels.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final h = entry.value;
                      final isActive = idx == _currentPage;

                      return Marker(
                        point: LatLng(h.lat, h.lng),
                        width: isActive ? 60 : 40,
                        height: isActive ? 60 : 40,
                        child: GestureDetector(
                          onTap: () {
                            _pageController.animateToPage(
                              idx,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            decoration: BoxDecoration(
                              color: isActive ? tealColor : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isActive ? Colors.white : tealColor,
                                width: isActive ? 3 : 2,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: isActive
                                ? const Icon(
                                    Icons.hotel,
                                    color: Colors.white,
                                    size: 28,
                                  )
                                : LiquidRatingIcon(
                                    rating: h.rating,
                                    icon: Icons.hotel,
                                    activeColor: tealColor,
                                    inactiveColor: Colors.grey.shade300,
                                    size: 20,
                                  ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              Positioned(
                bottom: 24,
                left: 24,
                child: ElevatedButton.icon(
                  onPressed: () => _launchMaps(_hotels[_currentPage].address),
                  icon: const Icon(Icons.near_me, color: Colors.white),
                  label: const Text(
                    'Bắt đầu',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tealColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: const StadiumBorder(),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 6,
          child: SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tìm điểm dừng chân lý tưởng',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Text(
                        'Khám phá',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: List.generate(_hotels.length, (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 6),
                            height: 6, width: _currentPage == index ? 24 : 8,
                            decoration: BoxDecoration(color: _currentPage == index ? tealColor : Colors.grey[300], borderRadius: BorderRadius.circular(3)),
                          )),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _hotels.length,
                    onPageChanged: (int page) {
                      setState(() => _currentPage = page);
                      _mapController.move(
                        LatLng(_hotels[page].lat, _hotels[page].lng),
                        15.0,
                      );
                    },
                    itemBuilder: (context, index) =>
                        _buildCardItem(_hotels[index]),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardItem(HotelModel hotel) {
    String imageUrl =
        hotel.imageUrls.isNotEmpty && hotel.imageUrls[0].trim().isNotEmpty
        ? hotel.imageUrls[0]
        : 'https://images.unsplash.com/photo-1564501049412-61c2a3083791?q=80&w=800&auto=format&fit=crop';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailExploreScreen(hotel: hotel)),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: tealColor.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey.shade300,
                  child: const Icon(
                    Icons.image_not_supported,
                    size: 50,
                    color: Colors.grey,
                  ),
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        hotel.rating.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.0),
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hotel.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                color: Colors.white70,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  hotel.address,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: _formatCurrency(hotel.pricePerNight),
                                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                        ),
                                        const TextSpan(
                                          text: ' / đêm',
                                          style: TextStyle(color: Colors.white70, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF139CAE),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  Widget _buildBottomNav() {
    int selectedBottomIndex = 1;
    final List<IconData> icons = [
      Icons.home_filled,
      Icons.location_on,
      Icons.chat_bubble_rounded,
      Icons.favorite_rounded,
      Icons.person_rounded,
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
                // Đang ở Explore thì không làm gì
              } else if (index == 2) {
                navigateToTab(context, const ChatScreen());
              } else if (index == 3) {
                navigateToTab(context, const SavedTripsScreen());
              } else if (index == 4) {
                navigateToTab(context, const ProfileScreen());
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

class WaveClipper extends CustomClipper<Path> {
  final double fillPercent;
  final double animationValue;

  WaveClipper({required this.fillPercent, required this.animationValue});

  @override
  Path getClip(Size size) {
    Path path = Path();
    if (fillPercent <= 0.0) return path;
    if (fillPercent >= 1.0) {
      path.addRect(Rect.fromLTWH(0, 0, size.width, size.height));
      return path;
    }

    double waveHeight = size.height * 0.15; // Chiều cao của gợn sóng
    double waterLevel = size.height * (1 - fillPercent); // Mức nước

    path.moveTo(0, size.height);
    path.lineTo(0, waterLevel);

    for (double i = 0; i <= size.width; i++) {
      double y = waterLevel + math.sin((i / size.width * 2 * math.pi) + (animationValue * 2 * math.pi)) * waveHeight;
      path.lineTo(i, y);
    }

    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(WaveClipper oldClipper) {
    return oldClipper.fillPercent != fillPercent || oldClipper.animationValue != animationValue;
  }
}

class LiquidRatingIcon extends StatefulWidget {
  final double rating;
  final IconData icon;
  final Color activeColor;
  final Color inactiveColor;
  final double size;

  const LiquidRatingIcon({
    super.key,
    required this.rating,
    required this.icon,
    required this.activeColor,
    required this.inactiveColor,
    this.size = 20,
  });

  @override
  State<LiquidRatingIcon> createState() => _LiquidRatingIconState();
}

class _LiquidRatingIconState extends State<LiquidRatingIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double fillPercent = (widget.rating / 5.0).clamp(0.0, 1.0);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            Icon(widget.icon, color: widget.inactiveColor, size: widget.size),
            ClipPath(
              clipper: WaveClipper(fillPercent: fillPercent, animationValue: _controller.value),
              child: Icon(widget.icon, color: widget.activeColor, size: widget.size),
            ),
          ],
        );
      },
    );
  }
}
