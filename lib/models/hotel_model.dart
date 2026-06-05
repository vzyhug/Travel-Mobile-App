import 'package:cloud_firestore/cloud_firestore.dart';

class HotelModel {
  final String id;
  final String name;
  final String address;
  final double lat;
  final double lng;
  final double rating;
  final double pricePerNight;
  final List<String> imageUrls;
  final List<String> amenities;
  final String description;

  HotelModel({
    required this.id,
    required this.name,
    required this.address,
    required this.lat,
    required this.lng,
    required this.rating,
    required this.pricePerNight,
    required this.imageUrls,
    required this.amenities,
    required this.description,
  });

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  factory HotelModel.fromJson(Map<String, dynamic> json) {
    return HotelModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Đang cập nhật',
      address: json['address']?.toString() ?? 'Đang cập nhật',
      lat: _toDouble(json['lat']),
      lng: _toDouble(json['lng']),
      rating: _toDouble(json['rating']),
      pricePerNight: _toDouble(json['pricePerNight']),
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      amenities: List<String>.from(json['amenities'] ?? []),
      description: json['description']?.toString() ?? 'Không có mô tả',
    );
  }

  factory HotelModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return HotelModel(
      id: data['id']?.toString() ?? doc.id,
      name: data['name']?.toString() ?? 'Đang cập nhật',
      address: data['address']?.toString() ?? 'Đang cập nhật',
      lat: _toDouble(data['lat']),
      lng: _toDouble(data['lng']),
      rating: _toDouble(data['rating']),
      pricePerNight: _toDouble(data['pricePerNight']),
      imageUrls: List<String>.from(data['imageUrls'] ?? []),
      amenities: List<String>.from(data['amenities'] ?? []),
      description: data['description']?.toString() ?? 'Không có mô tả',
    );
  }
}