import 'package:flutter/material.dart';

import '../helper/local_storage_service.dart';
import '../helper/trip_service.dart';
import '../models/trip_model.dart';
import '../models/hotel_model.dart';
import '../services/api_service.dart';

import 'trip_detail_screen.dart';
import 'payment_screen.dart';
import 'detail_explore_screen.dart';
import 'home_screen.dart';
import 'explore_screen.dart';

const Color savedPrimaryColor = Color(0xFF059AA6);

class SavedTripsScreen extends StatefulWidget {
  const SavedTripsScreen({super.key});

  @override
  State<SavedTripsScreen> createState() => _SavedTripsScreenState();
}

class _SavedTripsScreenState extends State<SavedTripsScreen> {
  final TripService _tripService = TripService();
  final LocalStorageService _localStorageService = LocalStorageService();

  bool isLoading = true;
  String? errorMessage;

  List<TripModel> allTrips = [];
  Set<int> favoriteTripIds = {};
  Set<int> bookedTripIds = {};

  List<HotelModel> allHotels = [];
  Set<String> favoriteHotelIds = {};

  @override
  void initState() {
    super.initState();
    loadSavedTrips();
  }

  Future<void> loadSavedTrips() async {
    try {
      final trips = await _tripService.getTrips();
      final favorites = await _localStorageService.getFavoriteTripIds();
      final bookings = await _localStorageService.getBookings();

      final hotels = await ApiService.fetchHotels();
      final favHotels = await _localStorageService.getFavoriteHotelIds();

      if (!mounted) return;

      setState(() {
        allTrips = trips;
        favoriteTripIds = favorites;
        bookedTripIds = bookings.map((b) => int.tryParse(b.tripId) ?? 0).toSet();

        allHotels = hotels;
        favoriteHotelIds = favHotels;

        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  List<TripModel> get eventTrips => allTrips.where((t) => favoriteTripIds.contains(t.id) && t.type != 'Package').toList();
  List<TripModel> get packageTrips => allTrips.where((t) => favoriteTripIds.contains(t.id) && t.type == 'Package').toList();
  List<TripModel> get bookedTrips => allTrips.where((t) => bookedTripIds.contains(t.id)).toList();

  List<HotelModel> get savedHotels => allHotels.where((h) => favoriteHotelIds.contains(h.id)).toList();

  Future<void> openTripDetail(TripModel trip) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => TripDetailScreen(trip: trip, isFavorite: true)));
    loadSavedTrips();
  }

  Future<void> openHotelDetail(HotelModel hotel) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => DetailExploreScreen(hotel: hotel)));
    loadSavedTrips();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(child: buildBody()),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget buildBody() {
    if (isLoading) return const Center(child: CircularProgressIndicator(color: savedPrimaryColor));
    if (errorMessage != null) return Center(child: Text(errorMessage!, style: const TextStyle(color: Colors.red)));

    bool hasAnySaved = eventTrips.isNotEmpty || packageTrips.isNotEmpty || savedHotels.isNotEmpty || bookedTrips.isNotEmpty;

    return RefreshIndicator(
      color: savedPrimaryColor,
      onRefresh: loadSavedTrips,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 90),
        children: [
          _buildAppBar(),
          const SizedBox(height: 26),
          if (!hasAnySaved) _buildEmptyState(),

          if (savedHotels.isNotEmpty) ...[
            _buildSectionTitle('Saved Hotels'),
            const SizedBox(height: 14),
            ...savedHotels.map(_buildSavedHotelCard),
            const SizedBox(height: 22),
          ],

          if (eventTrips.isNotEmpty) ...[
            _buildSectionTitle('Saved Events'),
            const SizedBox(height: 14),
            ...eventTrips.map(_buildSavedTripCard),
            const SizedBox(height: 22),
          ],
          if (packageTrips.isNotEmpty) ...[
            _buildSectionTitle('Saved Packages'),
            const SizedBox(height: 14),
            ...packageTrips.map(_buildSavedTripCard),
            const SizedBox(height: 22),
          ],
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SizedBox(
      height: 42,
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(width: 38, height: 38, decoration: BoxDecoration(color: Colors.grey.shade50, shape: BoxShape.circle), child: const Icon(Icons.arrow_back, size: 22)),
          ),
          const Expanded(child: Text('Saved Trips', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
          const SizedBox(width: 38),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800));

  Widget _buildEmptyState() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.62,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 14),
          const Text('No saved trips yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildSavedHotelCard(HotelModel hotel) {
    String img = hotel.imageUrls.isNotEmpty ? hotel.imageUrls[0] : 'https://images.unsplash.com/photo-1564501049412-61c2a3083791?q=80';
    return GestureDetector(
      onTap: () => openHotelDetail(hotel),
      child: Container(
        height: 116, margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.045), blurRadius: 18, offset: const Offset(0, 8))]),
        child: Row(
          children: [
            _networkImage(img, width: 126, height: 98, radius: 14),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(hotel.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 5),
                  Text(hotel.address, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                  const SizedBox(height: 6),
                  Text('${hotel.pricePerNight.toInt()}đ / Night', style: const TextStyle(color: savedPrimaryColor, fontSize: 12, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedTripCard(TripModel trip) {
    return GestureDetector(
      onTap: () => openTripDetail(trip),
      child: Container(
        height: 116, margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.045), blurRadius: 18, offset: const Offset(0, 8))]),
        child: Row(
          children: [
            _networkImage(trip.imageUrl, width: 126, height: 98, radius: 14),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(trip.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 5),
                  Text(trip.location, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                  const SizedBox(height: 6),
                  Text('\$${trip.price} /Visit', style: const TextStyle(color: savedPrimaryColor, fontSize: 12, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    final icons = [Icons.home, Icons.location_on, Icons.chat_bubble, Icons.favorite, Icons.person];
    return Container(
      height: 72,
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 14, offset: const Offset(0, -4))]),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(icons.length, (index) {
          final selected = index == 3;
          return GestureDetector(
            onTap: () {
              if (index == 0) {
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (route) => false);
              } else if (index == 1) {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ExploreScreen()));
              } else if (index == 3) {
                loadSavedTrips();
              }
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icons[index], color: selected ? savedPrimaryColor : Colors.grey, size: 27),
                const SizedBox(height: 4),
                Container(width: 6, height: 6, decoration: BoxDecoration(color: selected ? savedPrimaryColor : Colors.transparent, shape: BoxShape.circle)),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _networkImage(String url, {required double height, required double width, required double radius}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(url, height: height, width: width, fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(height: height, width: width, color: Colors.grey.shade200, child: const Icon(Icons.image_not_supported, color: Colors.grey)),
      ),
    );
  }
}