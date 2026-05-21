import 'package:flutter/material.dart';

import '../helper/local_storage_service.dart';
import '../helper/trip_service.dart';
import '../models/trip_model.dart';
import 'trip_detail_screen.dart';
import 'payment_screen.dart';
//line 392
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

      if (!mounted) return;

      setState(() {
        allTrips = trips;
        favoriteTripIds = favorites;
        bookedTripIds = bookings.map((booking) => booking.tripId).toSet();
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

  List<TripModel> get savedTrips {
    return allTrips.where((trip) => favoriteTripIds.contains(trip.id)).toList();
  }

  List<TripModel> get eventTrips {
    return savedTrips.where((trip) => trip.type != 'Package').toList();
  }

  List<TripModel> get packageTrips {
    return savedTrips.where((trip) => trip.type == 'Package').toList();
  }

  List<TripModel> get bookedTrips {
    return allTrips.where((trip) => bookedTripIds.contains(trip.id)).toList();
  }

  Future<void> openDetail(TripModel trip) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TripDetailScreen(
          trip: trip,
          isFavorite: favoriteTripIds.contains(trip.id),
        ),
      ),
    );

    if (result != null) {
      await loadSavedTrips();
    }
  }

  Future<void> bookTrip(TripModel trip) async {
    if (bookedTripIds.contains(trip.id)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${trip.name} đã được booked rồi.')),
      );
      return;
    }

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentScreen(trip: trip),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      await loadSavedTrips();
    } else {
      await loadSavedTrips();
    }
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
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: savedPrimaryColor),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: savedPrimaryColor,
      onRefresh: loadSavedTrips,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 90),
        children: [
          _buildAppBar(),
          const SizedBox(height: 26),
          if (savedTrips.isEmpty && bookedTrips.isEmpty) _buildEmptyState(),
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
          if (bookedTrips.isNotEmpty) ...[
            _buildBookedHeader(),
            const SizedBox(height: 14),
            ...bookedTrips.map(_buildBookedTripCard),
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
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_back, size: 22),
            ),
          ),
          const Expanded(
            child: Text(
              'Saved Trips',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 38),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.62,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 72, color: Colors.grey.shade300),
          const SizedBox(height: 14),
          const Text(
            'No saved trips yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Bấm icon trái tim ở Home hoặc Detail để lưu chuyến đi vào đây.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, height: 1.35),
          ),
        ],
      ),
    );
  }

  Widget _buildBookedHeader() {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Booked Tours',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE6F7F8),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${bookedTrips.length} booked',
            style: const TextStyle(
              color: savedPrimaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBookedTripCard(TripModel trip) {
    return GestureDetector(
      onTap: () => openDetail(trip),
      child: Container(
        height: 116,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF6FBFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE0F2F3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            _networkImage(
              trip.imageUrl,
              width: 126,
              height: 98,
              radius: 14,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          trip.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const Icon(Icons.check_circle, color: savedPrimaryColor, size: 16),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 13, color: Colors.grey.shade600),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          trip.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    trip.type == 'Package' && trip.duration.isNotEmpty
                        ? '\$${trip.price} / ${trip.duration}'
                        : '\$${trip.price} /Visit',
                    style: const TextStyle(
                      color: savedPrimaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: savedPrimaryColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Booked',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSavedTripCard(TripModel trip) {
    final bool isBooked = bookedTripIds.contains(trip.id);

    return GestureDetector(
      onTap: () => openDetail(trip),
      child: Container(
        height: 116,
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.045),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            _networkImage(
              trip.imageUrl,
              width: 126,
              height: 98,
              radius: 14,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          trip.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const Icon(Icons.star, color: Colors.amber, size: 14),
                      const SizedBox(width: 2),
                      Text(
                        trip.rating.toString(),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 13, color: Colors.grey.shade600),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          trip.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    trip.type == 'Package' && trip.duration.isNotEmpty
                        ? '\$${trip.price} / ${trip.duration}'
                        : '\$${trip.price} /Visit',
                    style: const TextStyle(
                      color: savedPrimaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 24,
                    child: ElevatedButton(
                      onPressed: isBooked ? null : () => bookTrip(trip),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isBooked ? Colors.grey : savedPrimaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade400,
                        disabledForegroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        isBooked ? 'Booked' : 'Book Now',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
          final selected = index == 3;

          return GestureDetector(
            onTap: () async {
              if (index == 0) {
                Navigator.pop(context, true);
                return;
              }

              if (index == 3) {
                await loadSavedTrips();
                return;
              }
//Todo..
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Màn hình này chưa được triển khai trong phần Home/Detail/Saved Trips.'),
                ),
              );
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icons[index],
                  color: selected ? savedPrimaryColor : Colors.grey,
                  size: 27,
                ),
                const SizedBox(height: 4),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: selected ? savedPrimaryColor : Colors.transparent,
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

  Widget _networkImage(
    String url, {
    required double height,
    required double width,
    required double radius,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.network(
        url,
        height: height,
        width: width,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;

          return Container(
            height: height,
            width: width,
            color: Colors.grey.shade100,
            child: const Center(
              child: CircularProgressIndicator(
                color: savedPrimaryColor,
                strokeWidth: 2,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: height,
            width: width,
            color: Colors.grey.shade200,
            child: const Icon(Icons.image_not_supported, color: Colors.grey),
          );
        },
      ),
    );
  }
}
