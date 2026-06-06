import 'package:flutter/material.dart';
import '../models/hotel_model.dart';
import 'home_screen.dart';
import 'saved_trips_screen.dart';
import '../helper/local_storage_service.dart';
import '../widgets/review_section.dart';
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

  String _formatCurrency(num value) {
    final amount = value.toInt();
    final text = amount.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    return '$text đ';
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
                bgImageUrl.trim().startsWith('http://') || bgImageUrl.trim().startsWith('https://')
                    ? Image.network(
                        bgImageUrl.trim(),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.hotel, size: 80, color: Colors.grey),
                        ),
                      )
                    : Image.asset(
                        bgImageUrl.trim().isEmpty ? 'assets/images/default_hotel.png' : bgImageUrl.trim(),
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.hotel, size: 80, color: Colors.grey),
                        ),
                      ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black.withOpacity(0.4), Colors.transparent],
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
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.60,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(widget.hotel.name, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold))),
                              Row(children: [const Icon(Icons.star, color: Colors.amber), Text(widget.hotel.rating.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))]),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(children: [Icon(Icons.location_on, color: Colors.grey.shade600, size: 20), const SizedBox(width: 6), Expanded(child: Text(widget.hotel.address, style: TextStyle(color: Colors.grey.shade600, fontSize: 15)))]),
                          const SizedBox(height: 24),
                          const Text("Tiện ích", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Wrap(spacing: 10, runSpacing: 10, children: widget.hotel.amenities.map((a) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: tealColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Text(a, style: TextStyle(color: tealColor, fontWeight: FontWeight.w600)))).toList()),
                          const SizedBox(height: 24),
                          const Text("Mô tả", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(widget.hotel.description, style: const TextStyle(fontSize: 15, color: Colors.black54, height: 1.6)),
                          const SizedBox(height: 24),
                          ReviewSection(itemId: widget.hotel.id, itemType: 'hotel'),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: tealColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                              onPressed: goToRoomSelection,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text('Đặt ngay | ${_formatCurrency(widget.hotel.pricePerNight)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: toggleFavorite,
                          child: Container(
                            height: 54, width: 54, decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), shape: BoxShape.circle),
                            child: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: isFavorite ? Colors.redAccent : Colors.grey, size: 28),
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
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 72,
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 14, offset: const Offset(0, -4))]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(onPressed: () => Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (r) => false), icon: const Icon(Icons.home, color: Colors.grey)),
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.location_on, color: Color(0xFF139CAE))),
          IconButton(onPressed: () {}, icon: const Icon(Icons.chat_bubble, color: Colors.grey)),
          IconButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedTripsScreen())), icon: const Icon(Icons.favorite, color: Colors.grey)),
          const Icon(Icons.person, color: Colors.grey),
        ],
      ),
    );
  }
}