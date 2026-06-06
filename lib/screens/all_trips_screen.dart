import 'package:flutter/material.dart';
import '../models/trip_model.dart';
import 'trip_detail_screen.dart';
import '../helper/local_storage_service.dart';

const Color primaryColor = Color(0xFF059AA6);

class AllTripsScreen extends StatefulWidget {
  final List<TripModel> allTrips;

  const AllTripsScreen({super.key, required this.allTrips});

  @override
  State<AllTripsScreen> createState() => _AllTripsScreenState();
}

class _AllTripsScreenState extends State<AllTripsScreen> {
  final LocalStorageService _localStorageService = LocalStorageService();
  Set<int> favoriteTripIds = {};

  double? filterMinRating;
  double? filterMaxPrice;
  int filterMaxDays = 14; 
  String selectedCategory = 'Tất cả';
  int _selectedRegionIndex = 0; // 0 = Tất cả, 1 = Bắc, 2 = Trung, 3 = Nam

  final List<String> categories = ['Tất cả', 'Hồ', 'Biển', 'Núi', 'Rừng'];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final loadedFavorites = await _localStorageService.getFavoriteTripIds();
    if (mounted) {
      setState(() {
        favoriteTripIds = loadedFavorites;
      });
    }
  }

  Future<void> toggleFavorite(int tripId) async {
    setState(() {
      if (favoriteTripIds.contains(tripId)) {
        favoriteTripIds.remove(tripId);
      } else {
        favoriteTripIds.add(tripId);
      }
    });
    await _localStorageService.saveFavoriteTripIds(favoriteTripIds);
  }

  Future<void> openTripDetail(TripModel trip) async {
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
      setState(() {
        if (result) favoriteTripIds.add(trip.id);
        else favoriteTripIds.remove(trip.id);
      });
      await _localStorageService.saveFavoriteTripIds(favoriteTripIds);
    }
  }

  int _extractDays(String durationStr) {
    final match = RegExp(r'(\d+)\s*ngày', caseSensitive: false).firstMatch(durationStr);
    if (match != null) {
      return int.tryParse(match.group(1) ?? '0') ?? 0;
    }
    return 0; // if cannot parse
  }

  String _getRegion(String location) {
    final lowerLoc = location.toLowerCase();
    
    final north = ['hà nội', 'ha noi', 'hà giang', 'cao bằng', 'bắc kạn', 'tuyên quang', 'lào cai', 'sapa', 'điện biên', 'lai châu', 'sơn la', 'yên bái', 'hòa bình', 'thái nguyên', 'lạng sơn', 'quảng ninh', 'hạ long', 'bắc giang', 'phú thọ', 'vĩnh phúc', 'bắc ninh', 'hải dương', 'hải phòng', 'hưng yên', 'thái bình', 'hà nam', 'nam định', 'ninh bình', 'tràng an'];
    for (var p in north) {
      if (lowerLoc.contains(p)) return 'Miền Bắc';
    }

    final central = ['thanh hóa', 'nghệ an', 'hà tĩnh', 'quảng bình', 'phong nha', 'quảng trị', 'thừa thiên huế', 'huế', 'đà nẵng', 'quảng nam', 'hội an', 'quảng ngãi', 'bình định', 'quy nhơn', 'phú yên', 'khánh hòa', 'nha trang', 'ninh thuận', 'bình thuận', 'phan thiết', 'mũi né', 'kon tum', 'gia lai', 'đắk lắk', 'buôn ma thuột', 'đắk nông', 'lâm đồng', 'đà lạt'];
    for (var p in central) {
      if (lowerLoc.contains(p)) return 'Miền Trung';
    }

    final south = ['bình phước', 'tây ninh', 'bình dương', 'đồng nai', 'bà rịa', 'vũng tàu', 'hồ chí minh', 'sài gòn', 'long an', 'tiền giang', 'bến tre', 'trà vinh', 'vĩnh long', 'đồng tháp', 'an giang', 'kiên giang', 'phú quốc', 'cần thơ', 'hậu giang', 'sóc trăng', 'bạc liêu', 'cà mau'];
    for (var p in south) {
      if (lowerLoc.contains(p)) return 'Miền Nam';
    }

    return 'Khác';
  }

  List<TripModel> get filteredTrips {
    return widget.allTrips.where((trip) {
      if (_selectedRegionIndex != 0) {
        final region = _getRegion(trip.location);
        if (_selectedRegionIndex == 1 && region != 'Miền Bắc') return false;
        if (_selectedRegionIndex == 2 && region != 'Miền Trung') return false;
        if (_selectedRegionIndex == 3 && region != 'Miền Nam') return false;
      }

      String filterCat = selectedCategory;
      if (selectedCategory == 'Hồ') filterCat = 'Lake';
      else if (selectedCategory == 'Biển') filterCat = 'Sea';
      else if (selectedCategory == 'Núi') filterCat = 'Mountain';
      else if (selectedCategory == 'Rừng') filterCat = 'Forest';

      final matchCategory = selectedCategory == 'Tất cả' || trip.category.toLowerCase() == filterCat.toLowerCase();
      if (!matchCategory) return false;

      if (filterMinRating != null && trip.rating < filterMinRating!) return false;
      if (filterMaxPrice != null && trip.price > filterMaxPrice!) return false;

      if (filterMaxDays < 14) {
        int days = _extractDays(trip.duration);
        if (days > filterMaxDays) return false;
      }

      return true;
    }).toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));
  }

  String _formatCurrency(num value) {
    final amount = value.toInt();
    final text = amount.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}.',
    );
    return '$text đ';
  }

  void _showFilterBottomSheet() {
    double tempRating = filterMinRating ?? 0;
    double tempPrice = filterMaxPrice ?? 50000000;
    int tempDays = filterMaxDays;
    String tempCat = selectedCategory;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Bộ lọc Tour chi tiết', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  
                  // Category
                  const Text('Danh mục:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((cat) {
                      final selected = tempCat == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: selected,
                        selectedColor: primaryColor,
                        labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87),
                        onSelected: (val) {
                          if (val) setModalState(() => tempCat = cat);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Rating
                  Text('Đánh giá tối thiểu: ${tempRating.toStringAsFixed(1)} sao', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  Slider(
                    value: tempRating,
                    min: 0,
                    max: 5,
                    divisions: 10,
                    activeColor: primaryColor,
                    onChanged: (val) => setModalState(() => tempRating = val),
                  ),
                  const SizedBox(height: 16),

                  // Duration
                  Text('Thời gian tối đa: ${tempDays == 14 ? '14+ ngày' : '$tempDays ngày'}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  Slider(
                    value: tempDays.toDouble(),
                    min: 1,
                    max: 14,
                    divisions: 13,
                    activeColor: primaryColor,
                    onChanged: (val) => setModalState(() => tempDays = val.toInt()),
                  ),
                  const SizedBox(height: 16),

                  // Price
                  Text('Giá tối đa: ${_formatCurrency(tempPrice)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                  Slider(
                    value: tempPrice,
                    min: 0,
                    max: 100000000,
                    divisions: 20,
                    activeColor: primaryColor,
                    onChanged: (val) => setModalState(() => tempPrice = val),
                  ),
                  const SizedBox(height: 32),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            setState(() {
                              filterMinRating = null;
                              filterMaxPrice = null;
                              filterMaxDays = 14;
                              selectedCategory = 'Tất cả';
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Xoá lọc', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            setState(() {
                              filterMinRating = tempRating;
                              filterMaxPrice = tempPrice;
                              filterMaxDays = tempDays;
                              selectedCategory = tempCat;
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Áp dụng', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }
        );
      }
    );
  }

  Widget _buildBottomFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(child: _buildRegionButton('Bắc', 1)),
            const SizedBox(width: 8),
            Expanded(child: _buildRegionButton('Trung', 2)),
            const SizedBox(width: 8),
            Expanded(child: _buildRegionButton('Nam', 3)),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _showFilterBottomSheet,
              child: Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.tune, color: primaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegionButton(String title, int index) {
    final isSelected = _selectedRegionIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_selectedRegionIndex == index) {
            _selectedRegionIndex = 0;
          } else {
            _selectedRegionIndex = index;
          }
        });
      },
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? primaryColor : Colors.transparent),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = filteredTrips;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Danh sách Tour', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      bottomNavigationBar: _buildBottomFilterBar(),
      body: list.isEmpty
          ? const Center(
              child: Text(
                'Không tìm thấy tour nào phù hợp.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(18),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 18),
              itemBuilder: (context, index) {
                final trip = list[index];
                final isFavorite = favoriteTripIds.contains(trip.id);

                return GestureDetector(
                  onTap: () => openTripDetail(trip),
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
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                              child: Image.network(
                                trip.imageUrl,
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 160,
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.image_not_supported, color: Colors.grey),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 12,
                              top: 12,
                              child: GestureDetector(
                                onTap: () => toggleFavorite(trip.id),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isFavorite ? Icons.favorite : Icons.favorite_border,
                                    color: isFavorite ? primaryColor : Colors.grey,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              left: 12,
                              bottom: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.star, color: Colors.amber, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      trip.rating.toString(),
                                      style: const TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                trip.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.location_on, color: Colors.grey.shade600, size: 16),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      trip.location,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.access_time_rounded, color: Colors.grey.shade600, size: 16),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      trip.duration,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: _formatCurrency(trip.price),
                                      style: const TextStyle(color: primaryColor, fontWeight: FontWeight.w800, fontSize: 16),
                                    ),
                                    const TextSpan(
                                      text: ' / chuyến',
                                      style: TextStyle(color: Colors.black87, fontSize: 13),
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
