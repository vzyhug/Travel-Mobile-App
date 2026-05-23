import 'package:flutter/material.dart';

import '../helper/local_storage_service.dart';
import '../helper/trip_service.dart';
import '../models/trip_model.dart';
import 'trip_detail_screen.dart';
import 'saved_trips_screen.dart';
import 'explore_screen.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import '../helper/navigation_helper.dart';

const Color primaryColor = Color(0xFF059AA6);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TripService _tripService = TripService();
  final LocalStorageService _localStorageService = LocalStorageService();
  final TextEditingController _searchController = TextEditingController();

  bool isLoading = true;
  String? errorMessage;

  List<TripModel> trips = [];
  Set<int> favoriteTripIds = {};

  String selectedCategory = 'All';
  int selectedBottomIndex = 0;
  bool showAllTopTrips = false;
  bool showAllGroupTrips = false;

  final List<String> categories = ['All', 'Lakes', 'Sea', 'Mountain', 'Forest'];

  @override
  void initState() {
    super.initState();
    loadHomeData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> loadHomeData() async {
    try {
      final loadedTrips = await _tripService.getTrips();
      final loadedFavorites = await _localStorageService.getFavoriteTripIds();

      if (!mounted) return;

      setState(() {
        trips = loadedTrips;
        favoriteTripIds = loadedFavorites;
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

  List<TripModel> get filteredTrips {
    final keyword = _searchController.text.trim().toLowerCase();

    return trips.where((trip) {
      final matchCategory = selectedCategory == 'All' || trip.category == selectedCategory;

      final matchSearch = trip.name.toLowerCase().contains(keyword) ||
          trip.location.toLowerCase().contains(keyword) ||
          trip.country.toLowerCase().contains(keyword) ||
          trip.category.toLowerCase().contains(keyword);

      return matchCategory && matchSearch;
    }).toList();
  }

  List<TripModel> get groupTrips {
    return trips.where((trip) => trip.category == 'Mountain').toList();
  }

  bool get hasActiveFilter {
    return selectedCategory != 'All' || _searchController.text.trim().isNotEmpty;
  }

  void clearFilters() {
    FocusScope.of(context).unfocus();
    setState(() {
      selectedCategory = 'All';
      _searchController.clear();
      showAllTopTrips = false;
    });
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
        builder: (_) {
          return TripDetailScreen(
            trip: trip,
            isFavorite: favoriteTripIds.contains(trip.id),
          );
        },
      ),
    );

    if (result != null) {
      setState(() {
        if (result) {
          favoriteTripIds.add(trip.id);
        } else {
          favoriteTripIds.remove(trip.id);
        }
      });

      await _localStorageService.saveFavoriteTripIds(favoriteTripIds);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: buildBody(),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget buildBody() {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: primaryColor),
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

    final topTrips = showAllTopTrips ? filteredTrips : filteredTrips.take(6).toList();

    return RefreshIndicator(
      color: primaryColor,
      onRefresh: loadHomeData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 90),
        children: [
          _buildHeader(),
          const SizedBox(height: 22),
          _buildSearchAndFilter(),
          const SizedBox(height: 20),
          _buildSectionTitle('Categories'),
          const SizedBox(height: 12),
          _buildCategories(),
          if (hasActiveFilter) ...[
            const SizedBox(height: 10),
            _buildClearFilterChip(),
          ],
          const SizedBox(height: 22),
          _buildSectionTitle(
            'Top Trips',
            showAllTopTrips ? 'Show less' : 'See All',
            () {
              setState(() {
                showAllTopTrips = !showAllTopTrips;
              });
            },
          ),
          const SizedBox(height: 12),
          _buildTopTrips(topTrips),
          const SizedBox(height: 22),
          _buildSectionTitle(
            'Group Trips',
            showAllGroupTrips ? 'Show less' : 'See All',
            () {
              setState(() {
                showAllGroupTrips = !showAllGroupTrips;
              });
            },
          ),
          const SizedBox(height: 12),
          _buildGroupTrips(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Location',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on, size: 18, color: Colors.black87),
                  SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'New York, USA',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                    color: Colors.amber,
                  ),
                ],
              ),
            ],
          ),
        ),
        Stack(
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.notifications, color: Colors.black87),
            ),
            Positioned(
              top: 8,
              right: 9,
              child: Container(
                height: 8,
                width: 8,
                decoration: const BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Search',
                border: InputBorder.none,
                prefixIcon: Icon(Icons.search),
                contentPadding: EdgeInsets.only(top: 12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: hasActiveFilter ? clearFilters : showFilterMessage,
          child: Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: hasActiveFilter ? Colors.redAccent : primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              hasActiveFilter ? Icons.close : Icons.tune,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  void showFilterMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Filter theo category và search đã hoạt động.'),
      ),
    );
  }

  Widget _buildClearFilterChip() {
    final label = selectedCategory == 'All'
        ? 'Đang tìm kiếm'
        : 'Đang lọc: $selectedCategory';

    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: clearFilters,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: primaryColor.withOpacity(0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.close, size: 16, color: primaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(
    String title, [
    String? actionText,
    VoidCallback? onActionTap,
  ]) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (actionText != null && onActionTap != null)
          GestureDetector(
            onTap: onActionTap,
            child: Text(
              actionText,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCategories() {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = selectedCategory == category;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedCategory = category;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: selected ? primaryColor : Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: selected ? primaryColor : Colors.grey.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _categoryIcon(category),
                    color: selected ? Colors.white : primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    category,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.black87,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'All':
        return Icons.apps;
      case 'Sea':
        return Icons.water;
      case 'Mountain':
        return Icons.terrain;
      case 'Forest':
        return Icons.forest;
      default:
        return Icons.pool;
    }
  }

  Widget _buildTopTrips(List<TripModel> items) {
    if (items.isEmpty) {
      return const SizedBox(
        height: 150,
        child: Center(
          child: Text(
            'No trips found',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final trip = items[index];
          final isFavorite = favoriteTripIds.contains(trip.id);

          return GestureDetector(
            onTap: () => openTripDetail(trip),
            child: Container(
              width: 140,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
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
                      _networkImage(
                        trip.imageUrl,
                        height: 88,
                        width: double.infinity,
                        radius: 14,
                      ),
                      Positioned(
                        right: 6,
                        bottom: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 13,
                              ),
                              Text(
                                trip.rating.toString(),
                                style: const TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    trip.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.grey.shade600,
                        size: 14,
                      ),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          trip.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Text(
                        '\$${trip.price}',
                        style: const TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text(
                        ' /Visit',
                        style: TextStyle(fontSize: 11),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => toggleFavorite(trip.id),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? primaryColor : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGroupTrips() {
    if (groupTrips.isEmpty) {
      return const Text(
        'No group trips available',
        style: TextStyle(color: Colors.grey),
      );
    }

    final items = showAllGroupTrips ? groupTrips : groupTrips.take(3).toList();

    return Column(
      children: items.map((trip) {
        return GestureDetector(
          onTap: () => openTripDetail(trip),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                _networkImage(
                  trip.imageUrl,
                  width: 120,
                  height: 100,
                  radius: 14,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 100,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trip.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          trip.location,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              color: Colors.grey.shade600,
                              size: 14,
                            ),
                            Text(
                              trip.country,
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            SizedBox(
                              width: 74,
                              height: 24,
                              child: Stack(
                                children: List.generate(3, (index) {
                                  return Positioned(
                                    left: index * 18,
                                    child: CircleAvatar(
                                      radius: 12,
                                      backgroundColor: Colors.white,
                                      child: CircleAvatar(
                                        radius: 10,
                                        backgroundColor: Colors.grey.shade300,
                                        child: const Icon(
                                          Icons.person,
                                          size: 13,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: 0.8,
                                  minHeight: 5,
                                  backgroundColor: Colors.grey.shade200,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              '80%',
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
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
          final selected = selectedBottomIndex == index;

          return GestureDetector(
            onTap: () {
              if (selected) return;

              // Cập nhật chỉ số tab được chọn
              setState(() {
                selectedBottomIndex = index;
              });

              // Điều hướng theo tab
              if (index == 0) {
                // Đang ở Home thì không làm gì
              } else if (index == 1) {
                navigateToTab(context, const ExploreScreen());
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
                  color: selected ? primaryColor : Colors.grey,
                  size: 27,
                ),
                const SizedBox(height: 4),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: selected ? primaryColor : Colors.transparent,
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
            child: const Icon(Icons.image_not_supported, color: Colors.grey),
          );
        },
      ),
    );
  }
}
