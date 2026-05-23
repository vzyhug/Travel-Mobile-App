class RoomModel {
  final String id;
  final String hotelId;
  final String type;
  final int capacity;
  final double price;
  final bool available;

  RoomModel({
    required this.id,
    required this.hotelId,
    required this.type,
    required this.capacity,
    required this.price,
    required this.available,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'] ?? '',
      hotelId: json['hotelId'] ?? '',
      type: json['type'] ?? 'Phòng tiêu chuẩn',
      capacity: json['capacity'] ?? 2,
      price: (json['price'] ?? 0).toDouble(),
      available: json['available'] ?? false,
    );
  }
}