import 'package:cloud_firestore/cloud_firestore.dart';

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

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id']?.toString() ?? '',
      hotelId: json['hotelId']?.toString() ?? '',
      type: json['type']?.toString() ?? 'Phòng tiêu chuẩn',
      capacity: _toInt(json['capacity']),
      price: _toDouble(json['price']),
      available: json['available'] ?? false,
    );
  }

  factory RoomModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return RoomModel(
      id: data['id']?.toString() ?? doc.id,
      hotelId: data['hotelId']?.toString() ?? '',
      type: data['type']?.toString() ?? 'Phòng tiêu chuẩn',
      capacity: _toInt(data['capacity']),
      price: _toDouble(data['price']),
      available: data['available'] ?? false,
    );
  }
}