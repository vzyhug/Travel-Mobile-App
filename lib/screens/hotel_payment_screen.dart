import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../config/payment_config.dart';
import '../helper/local_storage_service.dart';
import '../models/local_booking_model.dart';
import '../models/hotel_model.dart';
import '../models/room_model.dart';

const Color paymentPrimaryColor = Color(0xFF059AA6);
const Color paymentBackgroundColor = Color(0xFFF6FBFC);
const Color paymentTextColor = Color(0xFF202124);

class HotelPaymentScreen extends StatefulWidget {
  final HotelModel hotel;
  final RoomModel room;

  const HotelPaymentScreen({
    super.key,
    required this.hotel,
    required this.room,
  });

  @override
  State<HotelPaymentScreen> createState() => _HotelPaymentScreenState();
}

class _HotelPaymentScreenState extends State<HotelPaymentScreen> {
  final LocalStorageService _localStorageService = LocalStorageService();

  bool isConfirming = false;
  bool hasBooked = false;
  int numberOfGuests = 1;
  int numberOfNights = 1;
  final TextEditingController nameController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _checkBookedStatus();
  }

  Future<void> _checkBookedStatus() async {
    // Sử dụng hàm hasBookedHotel chuyên dụng mà chúng ta đã viết ở bước trước
    final booked = await _localStorageService.hasBookedHotel(widget.hotel.id);
    if (!mounted) return;
    setState(() {
      hasBooked = booked;
    });
  }

  Future<void> _confirmBooking() async {
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên đại diện đặt phòng.')),
      );
      return;
    }

    if (hasBooked || isConfirming) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Khách sạn này đã được booked rồi.')),
      );
      return;
    }

    setState(() {
      isConfirming = true;
    });

    final bookingId = DateTime.now().millisecondsSinceEpoch.toString();
    // Tạo hóa đơn lưu vào LocalStorage
    final booking = LocalBookingModel(
      bookingId: bookingId,
      tripId: widget.hotel.id,
      // Ghép tên khách sạn và tên phòng để hiển thị cho rõ ràng
      tripName: '${widget.hotel.name} (${widget.room.type})',
      price: widget.room.price * numberOfNights,
      location: widget.hotel.address,
      imageUrl: widget.hotel.imageUrls.isNotEmpty ? widget.hotel.imageUrls[0] : 'https://images.unsplash.com/photo-1564501049412-61c2a3083791?q=80',
      bookedAt: DateTime.now(),
    );

    await _localStorageService.addBooking(booking);

    try {
      final email = await _localStorageService.getUserEmail();
      await FirebaseFirestore.instance.collection('bookings').doc(bookingId).set({
        'bookingId': bookingId,
        'userEmail': email ?? 'unknown',
        'tripId': widget.hotel.id,
        'tripName': '${widget.hotel.name} (${widget.room.type})',
        'price': widget.room.price * numberOfNights,
        'location': widget.hotel.address,
        'imageUrl': booking.imageUrl,
        'bookedAt': DateTime.now().toIso8601String(),
        'status': 'Chờ duyệt',
        'type': 'hotel',
        'guestCount': numberOfGuests,
        'nightCount': numberOfNights,
        'customerName': nameController.text.trim(),
      });
    } catch (e) {
      debugPrint('Lỗi lưu Firestore: $e');
    }

    if (!mounted) return;

    setState(() {
      isConfirming = false;
      hasBooked = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã hoàn tất đặt phòng tại ${widget.hotel.name}.')),
    );

    // Trả về trang trước đó
    Navigator.pop(context, true);
  }

  String _formatCurrency(num value) {
    final amount = value.toInt();
    final text = amount.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (match) => '${match[1]}.',
    );
    return '$textđ';
  }

  String _removeVietnameseAccent(String input) {
    const vietnamese = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ'
        'ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ';
    const latin = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd'
        'AAAAAAAAAAAAAAAAAEEEEEEEEEEEIIIIIOOOOOOOOOOOOOOOOOUUUUUUUUUUUYYYYYD';

    var result = input;
    for (var i = 0; i < vietnamese.length; i++) {
      result = result.replaceAll(vietnamese[i], latin[i]);
    }
    return result;
  }

  String _buildTransferContent() {
    // Đổi cú pháp mã chuyển khoản sang cho Hotel
    final content = 'BOOK HOTEL ${widget.hotel.id} ${widget.room.id}';
    final noAccent = _removeVietnameseAccent(content).toUpperCase();
    final cleaned = noAccent.replaceAll(RegExp(r'[^A-Z0-9 ]'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned.length > 35 ? cleaned.substring(0, 35).trim() : cleaned;
  }

  String _buildQrUrl() {
    final amount = (widget.room.price * numberOfNights).toInt();
    final addInfo = Uri.encodeComponent(_buildTransferContent());
    final accountName = Uri.encodeComponent(PaymentConfig.accountName);

    return 'https://img.vietqr.io/image/'
        '${PaymentConfig.bankId}-${PaymentConfig.accountNo}-compact2.png'
        '?amount=$amount'
        '&addInfo=$addInfo'
        '&accountName=$accountName';
  }

  ImageProvider _getHotelImage() {
    final image = widget.hotel.imageUrls.isNotEmpty ? widget.hotel.imageUrls[0].trim() : '';
    if (image.startsWith('http://') || image.startsWith('https://')) {
      return NetworkImage(image);
    }
    return const NetworkImage('https://images.unsplash.com/photo-1564501049412-61c2a3083791?q=80');
  }

  Widget _buildGuestCounter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Số lượng người',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'Giới hạn: ${widget.room.capacity} người/phòng',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (numberOfGuests > 1) {
                    setState(() {
                      numberOfGuests--;
                    });
                  }
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: numberOfGuests > 1 ? paymentPrimaryColor.withOpacity(0.1) : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.remove, size: 18, color: numberOfGuests > 1 ? paymentPrimaryColor : Colors.grey),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                numberOfGuests.toString(),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () {
                  if (numberOfGuests < widget.room.capacity) {
                    setState(() {
                      numberOfGuests++;
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Vượt quá giới hạn. Phòng này tối đa ${widget.room.capacity} người.')),
                    );
                  }
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: numberOfGuests < widget.room.capacity ? paymentPrimaryColor.withOpacity(0.1) : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.add, size: 18, color: numberOfGuests < widget.room.capacity ? paymentPrimaryColor : Colors.grey),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNightsCounter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Số lượng đêm',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (numberOfNights > 1) {
                    setState(() {
                      numberOfNights--;
                    });
                  }
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: numberOfNights > 1 ? paymentPrimaryColor.withOpacity(0.1) : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.remove, size: 18, color: numberOfNights > 1 ? paymentPrimaryColor : Colors.grey),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                numberOfNights.toString(),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () {
                  setState(() {
                    numberOfNights++;
                  });
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: paymentPrimaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add, size: 18, color: paymentPrimaryColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNameInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: nameController,
        decoration: const InputDecoration(
          border: InputBorder.none,
          labelText: 'Tên đại diện đặt',
          labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          icon: Icon(Icons.person, color: paymentPrimaryColor),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final qrUrl = _buildQrUrl();
    final transferContent = _buildTransferContent();
    final totalPrice = widget.room.price * numberOfNights;
    final amountText = _formatCurrency(totalPrice);

    return Scaffold(
      backgroundColor: paymentBackgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  Container(
                    height: 250,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: _getHotelImage(),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Container(
                    height: 250,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.25),
                          Colors.black.withOpacity(0.65),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: 14,
                    left: 14,
                    child: _CircleButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 22,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.18),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white.withOpacity(0.35)),
                          ),
                          child: Text(
                            'Đặt phòng: ${widget.room.type}', // Hiển thị tên loại phòng
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.hotel.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 27,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded, color: Colors.white70, size: 18),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.hotel.address,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildNameInput(),
                  const SizedBox(height: 16),
                  _buildGuestCounter(),
                  const SizedBox(height: 16),
                  _buildNightsCounter(),
                  const SizedBox(height: 16),
                  _PriceCard(amountText: amountText),
                  const SizedBox(height: 16),
                  _QrCard(qrUrl: qrUrl),
                  const SizedBox(height: 16),
                  _BankInfoCard(
                    amountText: amountText,
                    transferContent: transferContent,
                    onCopyContent: () => _copyToClipboard(context, transferContent, 'Đã copy nội dung chuyển khoản'),
                    onCopyAccount: () => _copyToClipboard(context, PaymentConfig.accountNo, 'Đã copy số tài khoản'),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 52,
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _copyToClipboard(context, transferContent, 'Đã copy nội dung chuyển khoản'),
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text(
                        'Copy nội dung chuyển khoản',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: paymentPrimaryColor,
                        side: const BorderSide(color: paymentPrimaryColor, width: 1.4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 54,
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: hasBooked || isConfirming ? null : _confirmBooking,
                      icon: isConfirming
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                          : Icon(hasBooked ? Icons.check_circle_rounded : Icons.verified_rounded),
                      label: Text(
                        hasBooked ? 'Khách sạn này đã được Book' : 'Tôi đã thanh toán / Hoàn tất booking',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: hasBooked ? Colors.grey : paymentPrimaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade400,
                        disabledForegroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sau khi chuyển khoản xong, bấm nút hoàn tất để đơn đặt phòng xuất hiện trong mục Booked Tours.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      height: 1.4,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(icon, size: 19, color: Colors.black87),
      ),
    );
  }
}

class _PriceCard extends StatelessWidget {
  final String amountText;

  const _PriceCard({required this.amountText});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: paymentPrimaryColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: paymentPrimaryColor.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.payments_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tổng thanh toán',
                  style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 4),
                Text(
                  'Giá theo loại phòng bạn chọn',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            amountText,
            style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _QrCard extends StatelessWidget {
  final String qrUrl;

  const _QrCard({required this.qrUrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Quét QR để thanh toán',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: paymentTextColor),
          ),
          const SizedBox(height: 6),
          Text(
            'Mở app ngân hàng và quét mã bên dưới',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: paymentBackgroundColor,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Image.network(
              qrUrl,
              width: 245,
              height: 245,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const SizedBox(
                  width: 245,
                  height: 245,
                  child: Center(child: CircularProgressIndicator()),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox(
                  width: 245,
                  height: 245,
                  child: Center(
                    child: Text(
                      'Không tải được mã QR\nVui lòng kiểm tra internet',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BankInfoCard extends StatelessWidget {
  final String amountText;
  final String transferContent;
  final VoidCallback onCopyContent;
  final VoidCallback onCopyAccount;

  const _BankInfoCard({
    required this.amountText,
    required this.transferContent,
    required this.onCopyContent,
    required this.onCopyAccount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin chuyển khoản',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          _InfoRow(title: 'Ngân hàng', value: PaymentConfig.bankId.toUpperCase()),
          _InfoRow(title: 'Số tài khoản', value: PaymentConfig.accountNo, onCopy: onCopyAccount),
          _InfoRow(title: 'Chủ tài khoản', value: PaymentConfig.accountName),
          _InfoRow(title: 'Số tiền', value: amountText, isHighlight: true),
          _InfoRow(title: 'Nội dung', value: transferContent, onCopy: onCopyContent),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String title;
  final String value;
  final bool isHighlight;
  final VoidCallback? onCopy;

  const _InfoRow({
    required this.title,
    required this.value,
    this.isHighlight = false,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: isHighlight ? const Color(0xFFE6F7F8) : const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlight ? paymentPrimaryColor : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isHighlight ? paymentPrimaryColor : paymentTextColor,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          if (onCopy != null) ...[
            const SizedBox(width: 8),
            InkWell(
              onTap: onCopy,
              borderRadius: BorderRadius.circular(20),
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.copy_rounded, size: 18, color: paymentPrimaryColor),
              ),
            ),
          ],
        ],
      ),
    );
  }
}