import 'package:flutter/material.dart';
import '../helper/local_storage_service.dart';
import '../models/local_booking_model.dart';
import '../models/trip_model.dart';

const Color primaryColor = Color(0xFF059AA6);

class TripDetailScreen extends StatefulWidget {
  final TripModel trip;
  final bool isFavorite;

  const TripDetailScreen({
    super.key,
    required this.trip,
    required this.isFavorite,
  });

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  final LocalStorageService _localStorageService = LocalStorageService();

  late bool isFavorite;
  bool isBooking = false;
  bool hasBooked = false;
  int selectedImageIndex = 0;

  @override
  void initState() {
    super.initState();
    isFavorite = widget.isFavorite;
    checkBookedStatus();
  }

  Future<void> checkBookedStatus() async {
    final booked = await _localStorageService.hasBookedTrip(widget.trip.id);

    if (!mounted) return;

    setState(() {
      hasBooked = booked;
    });
  }

  Future<void> toggleFavorite() async {
    setState(() {
      isFavorite = !isFavorite;
    });

    await _localStorageService.toggleFavorite(widget.trip.id);
  }

  Future<void> bookingTrip() async {
    if (hasBooked) {
      showAlreadyBookedMessage();
      return;
    }

    setState(() {
      isBooking = true;
    });

    final booking = LocalBookingModel(
      bookingId: DateTime.now().millisecondsSinceEpoch.toString(),
      tripId: widget.trip.id,
      tripName: widget.trip.name,
      price: widget.trip.price,
      location: widget.trip.location,
      imageUrl: widget.trip.imageUrl,
      bookedAt: DateTime.now(),
    );

    await _localStorageService.addBooking(booking);

    if (!mounted) return;

    setState(() {
      isBooking = false;
      hasBooked = true;
    });

    showBookingSuccess();
  }

  void showAlreadyBookedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bạn đã booking trip này rồi.'),
      ),
    );
  }

  void showBookingSuccess() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle,
                color: primaryColor,
                size: 58,
              ),
              const SizedBox(height: 12),
              const Text(
                'Booking Successful',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You booked ${widget.trip.name} for \$${widget.trip.price}.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Done',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void goBack() {
    Navigator.pop(context, isFavorite);
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, isFavorite);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
            children: [
              _buildAppBar(),
              const SizedBox(height: 18),
              _buildImageSection(trip),
              const SizedBox(height: 22),
              _buildTitleSection(trip),
              const SizedBox(height: 14),
              _buildLocation(trip),
              const SizedBox(height: 22),
              _buildDescription(trip),
              const SizedBox(height: 28),
              _buildBookingButton(trip),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Row(
      children: [
        GestureDetector(
          onTap: goBack,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back),
          ),
        ),
        Expanded(
          child: Text(
            widget.trip.name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(width: 40),
      ],
    );
  }

  Widget _buildImageSection(TripModel trip) {
    final gallery = trip.gallery.isNotEmpty ? trip.gallery : [trip.imageUrl];
    final thumbnails = gallery.length > 4 ? gallery.take(4).toList() : gallery;

    return Stack(
      children: [
        _networkImage(
          gallery[selectedImageIndex],
          width: double.infinity,
          height: 320,
          radius: 20,
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 18,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(thumbnails.length, (index) {
              final selected = selectedImageIndex == index;
              final isLastMoreItem = index == 3 && gallery.length > 4;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedImageIndex = index;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected ? Colors.white : Colors.white70,
                      width: selected ? 3 : 2,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _networkImage(
                        thumbnails[index],
                        width: 48,
                        height: 48,
                        radius: 10,
                      ),
                      if (isLastMoreItem)
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.45),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              '+ ${gallery.length - 3}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleSection(TripModel trip) {
    return Row(
      children: [
        Expanded(
          child: Text(
            trip.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const Icon(Icons.star, color: Colors.amber, size: 25),
        const SizedBox(width: 4),
        Text(
          trip.rating.toString(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildLocation(TripModel trip) {
    return Row(
      children: [
        Icon(Icons.location_on, color: Colors.grey.shade600, size: 22),
        const SizedBox(width: 4),
        Text(
          trip.location,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(TripModel trip) {
    return Text(
      'What is ${trip.name} known for?\n${trip.description}',
      style: TextStyle(
        color: Colors.grey.shade700,
        fontSize: 15,
        height: 1.35,
      ),
    );
  }

  Widget _buildBookingButton(TripModel trip) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: hasBooked ? Colors.grey : primaryColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              onPressed: isBooking ? null : bookingTrip,
              child: isBooking
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      hasBooked
                          ? 'Booked | \$${trip.price}'
                          : 'Booking Now | \$${trip.price}',
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
              color: isFavorite ? primaryColor : Colors.grey,
              size: 30,
            ),
          ),
        ),
      ],
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
                color: primaryColor,
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
            child: const Icon(
              Icons.image_not_supported,
              color: Colors.grey,
            ),
          );
        },
      ),
    );
  }
}
