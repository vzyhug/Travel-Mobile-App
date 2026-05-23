import 'package:flutter/material.dart';
import '../models/hotel_model.dart';
import 'home_screen.dart';
import 'saved_trips_screen.dart';
import '../helper/local_storage_service.dart';
import 'room_selection_screen.dart';

class DetailExploreScreen extends StatefulWidget {
  final HotelModel hotel;

  const DetailExploreScreen({super.key, required this.hotel});

  @override
  State<DetailExploreScreen> createState() => _DetailExploreScreenState();
}

class _DetailExploreScreenState extends State<DetailExploreScreen> {
  final Color tealColor = const Color(0xFF139CAE);
  bool isFavorite = false;
  final LocalStorageService _localStorageService = LocalStorageService();

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    final status = await _localStorageService.isFavoriteHotel(widget.hotel.id);
    if (mounted) {
      setState(() {
        isFavorite = status;
      });
    }
  }

  Future<void> toggleFavorite() async {
    setState(() {
      isFavorite = !isFavorite;
    });
    await _localStorageService.toggleFavoriteHotel(widget.hotel.id);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isFavorite ? 'Đã thêm vào Wishlist' : 'Đã xóa khỏi Wishlist'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void goToRoomSelection() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoomSelectionScreen(hotel: widget.hotel),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String bgImageUrl = widget.hotel.imageUrls.isNotEmpty
        ? widget.hotel.imageUrls[0]
        : 'https://images.unsplash.com/photo-1564501049412-61c2a3083791?q=80&w=800&auto=format&fit=crop';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: Stack(
              children: [
                Image.network(
                  bgImageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.4),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.4],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.topLeft,
                child: CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.8),
                  radius: 22,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 30, 24, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  widget.hotel.name,
                                  style: const TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 22),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.hotel.rating.toString(),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.grey.shade600, size: 20),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  widget.hotel.address,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          if (widget.hotel.amenities.isNotEmpty) ...[
                            const Text(
                              "Tiện ích",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: widget.hotel.amenities.map((amenity) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: tealColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    amenity,
                                    style: TextStyle(color: tealColor, fontWeight: FontWeight.w600),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 24),
                          ],
                          const Text(
                            "Mô tả",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.hotel.description,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Colors.black54,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            offset: const Offset(0, -5),
                            blurRadius: 10,
                          )
                        ]
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: tealColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                              onPressed: goToRoomSelection,
                              child: Text(
                                'Book Now | ${widget.hotel.pricePerNight.toInt()}đ',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: toggleFavorite,
                          child: Container(
                            height: 54,
                            width: 54,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFavorite ? Icons.favorite : Icons.favorite_border,
                              color: isFavorite ? Colors.redAccent : Colors.grey,
                              size: 28,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      // Bổ sung thanh Bottom Nav cho UI 6
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // Thanh điều hướng mới đồng bộ với HomeScreen
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
                // Về Home (Xóa toàn bộ các trang đang đè lên nhau)
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (route) => false,
                );
              } else if (index == 1) {
                // Nếu đang ở Detail mà bấm lại nút Explore thì quay lùi ra UI 5
                Navigator.pop(context);
              } else if (index == 3) {
                // Sang Wishlist
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