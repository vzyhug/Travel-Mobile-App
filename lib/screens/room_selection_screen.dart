import 'package:flutter/material.dart';
import '../models/hotel_model.dart';
import '../models/room_model.dart';
import '../services/api_service.dart';

import 'hotel_payment_screen.dart';

const Color primaryColor = Color(0xFF059AA6);

class RoomSelectionScreen extends StatefulWidget {
  final HotelModel hotel;

  const RoomSelectionScreen({super.key, required this.hotel});

  @override
  State<RoomSelectionScreen> createState() => _RoomSelectionScreenState();
}

class _RoomSelectionScreenState extends State<RoomSelectionScreen> {
  bool isLoading = true;
  List<RoomModel> hotelRooms = [];

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    try {
      // Gọi API lấy tất cả các phòng
      final allRooms = await ApiService.fetchRooms();

      // Lọc ra các phòng có hotelId trùng với id của khách sạn hiện tại
      final filteredRooms = allRooms.where((room) => room.hotelId == widget.hotel.id).toList();

      if (mounted) {
        setState(() {
          hotelRooms = filteredRooms;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải danh sách phòng: $e')),
        );
      }
    }
  }

  void _selectRoom(RoomModel room) {
    if (!room.available) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HotelPaymentScreen(hotel: widget.hotel, room: room),
      ),
    ).then((result) {
      if (result == true && mounted) {
        Navigator.pop(context);
      }
    });
  }

  String _formatCurrency(num value) {
    final amount = value.toInt();
    final text = amount.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]}.',
    );
    return '$textđ';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FBFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            const Text(
              'Chọn loại phòng',
              style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w800),
            ),
            Text(
              widget.hotel.name,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : hotelRooms.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
        padding: const EdgeInsets.all(18),
        itemCount: hotelRooms.length,
        itemBuilder: (context, index) {
          return _buildRoomCard(hotelRooms[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.meeting_room_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Chưa có dữ liệu phòng\ncho khách sạn này.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomCard(RoomModel room) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    room.type,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: room.available ? const Color(0xFFE6F7F8) : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    room.available ? 'Còn phòng' : 'Hết phòng',
                    style: TextStyle(
                      color: room.available ? primaryColor : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.person_rounded, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  'Sức chứa: ${room.capacity} người lớn',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Divider(height: 1, thickness: 1),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Giá mỗi đêm',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatCurrency(room.price),
                      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: primaryColor),
                    ),
                  ],
                ),
                SizedBox(
                  height: 42,
                  width: 100,
                  child: ElevatedButton(
                    onPressed: room.available ? () => _selectRoom(room) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Chọn', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

