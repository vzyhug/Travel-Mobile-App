import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hotel_model.dart';
import '../services/api_service.dart';
import '../helper/local_storage_service.dart';
import 'detail_explore_screen.dart';

const Color primaryColor = Color(0xFF059AA6);

class AllHotelsScreen extends StatefulWidget {
  final List<HotelModel> allHotels;

  const AllHotelsScreen({super.key, required this.allHotels});

  @override
  State<AllHotelsScreen> createState() => _AllHotelsScreenState();
}

class _AllHotelsScreenState extends State<AllHotelsScreen> {
  double? filterMaxPrice;
  double? filterMinRating;
  int? filterMinCapacity;
  bool isReferenceMode = false;

  Map<String, int> hotelMaxCapacityMap = {};
  Set<String> bookedLocations = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // 1. Tải danh sách phòng để lấy capacity lớn nhất của từng khách sạn
      final rooms = await ApiService.fetchRooms();
      for (var room in rooms) {
        final currentMax = hotelMaxCapacityMap[room.hotelId] ?? 0;
        if (room.capacity > currentMax) {
          hotelMaxCapacityMap[room.hotelId] = room.capacity;
        }
      }

      // 2. Tải danh sách các tour đã đặt để lấy location cho tính năng "Tham khảo"
      final email = await LocalStorageService().getUserEmail();
      if (email != null) {
        final snapshot = await FirebaseFirestore.instance
            .collection('bookings')
            .where('userEmail', isEqualTo: email)
            .where('type', isEqualTo: 'trip')
            .get();
        final locations = snapshot.docs
            .map((doc) => doc.data()['location']?.toString() ?? '')
            .toSet();
        bookedLocations = locations;
      }
    } catch (e) {
      debugPrint('Lỗi tải dữ liệu lọc khách sạn: $e');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  List<HotelModel> get filteredHotels {
    return widget.allHotels.where((hotel) {
      if (filterMaxPrice != null && hotel.pricePerNight > filterMaxPrice!)
        return false;
      if (filterMinRating != null && hotel.rating < filterMinRating!)
        return false;

      if (filterMinCapacity != null) {
        final maxCap = hotelMaxCapacityMap[hotel.id] ?? 0;
        if (maxCap < filterMinCapacity!) return false;
      }

      if (isReferenceMode) {
        if (bookedLocations.isEmpty) return false;
        bool matches = false;
        final addrLower = hotel.address.toLowerCase();

        for (var loc in bookedLocations) {
          final locLower = loc.toLowerCase();
          final parts = locLower.split(',');
          for (var part in parts) {
            final p = part.trim();
            if (p.isNotEmpty && addrLower.contains(p)) {
              matches = true;
              break;
            }
          }
          if (matches) break;
        }
        if (!matches) return false;
      }

      return true;
    }).toList();
  }

  String _formatCurrency(num value) {
    final amount = value.toInt();
    final text = amount.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    return '$text đ';
  }

  void _showFilterSheet() {
    double tempPrice = filterMaxPrice ?? 5000000;
    double tempRating = filterMinRating ?? 0;
    int tempCapacity = filterMinCapacity ?? 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lọc Khách Sạn',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Mức giá tối đa: ${_formatCurrency(tempPrice)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Slider(
                    value: tempPrice,
                    min: 500000,
                    max: 10000000,
                    divisions: 19,
                    activeColor: primaryColor,
                    onChanged: (val) => setSheetState(() => tempPrice = val),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Đánh giá tối thiểu: ${tempRating.toStringAsFixed(1)} sao',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Slider(
                    value: tempRating,
                    min: 0,
                    max: 5,
                    divisions: 10,
                    activeColor: Colors.amber,
                    onChanged: (val) => setSheetState(() => tempRating = val),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'Số người tối đa (theo phòng): $tempCapacity người',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Slider(
                    value: tempCapacity.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    activeColor: primaryColor,
                    onChanged: (val) =>
                        setSheetState(() => tempCapacity = val.toInt()),
                  ),

                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              filterMaxPrice = null;
                              filterMinRating = null;
                              filterMinCapacity = null;
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Xóa lọc'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () {
                            setState(() {
                              filterMaxPrice = tempPrice;
                              filterMinRating = tempRating;
                              filterMinCapacity = tempCapacity;
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Áp dụng'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBottomFilterBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
          children: [
            Expanded(
              flex: 4,
              child: OutlinedButton.icon(
                onPressed: _showFilterSheet,
                icon: const Icon(Icons.filter_list, size: 20),
                label: const Text(
                  'Lọc nâng cao',
                  style: TextStyle(fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryColor,
                  side: const BorderSide(color: primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 5,
              child: ElevatedButton.icon(
                onPressed: bookedLocations.isEmpty
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Bạn chưa đặt tour nào để tham khảo.',
                            ),
                          ),
                        );
                      }
                    : () {
                        setState(() {
                          isReferenceMode = !isReferenceMode;
                        });
                      },
                icon: const Icon(Icons.recommend, size: 20),
                label: Text(
                  isReferenceMode ? 'Bỏ tham khảo' : 'Tham khảo',
                  style: const TextStyle(fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isReferenceMode
                      ? Colors.orange
                      : primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayHotels = filteredHotels;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Danh sách Khách sạn',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      bottomNavigationBar: _buildBottomFilterBar(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : displayHotels.isEmpty
          ? const Center(
              child: Text(
                'Không tìm thấy khách sạn nào phù hợp.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(18),
              itemCount: displayHotels.length,
              separatorBuilder: (_, __) => const SizedBox(height: 18),
              itemBuilder: (context, index) {
                final hotel = displayHotels[index];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DetailExploreScreen(hotel: hotel),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(18),
                          ),
                          child: Image.network(
                            hotel.imageUrls.isNotEmpty
                                ? hotel.imageUrls.first
                                : '',
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 160,
                              color: Colors.grey.shade200,
                              child: const Icon(
                                Icons.image_not_supported,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hotel.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: Colors.grey.shade600,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      hotel.address,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    hotel.rating.toString(),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: _formatCurrency(
                                        hotel.pricePerNight,
                                      ),
                                      style: const TextStyle(
                                        color: primaryColor,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const TextSpan(
                                      text: ' / đêm',
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
