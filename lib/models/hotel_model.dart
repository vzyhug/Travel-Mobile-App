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

  factory HotelModel.fromJson(Map<String, dynamic> json) {
    return HotelModel(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Đang cập nhật',
      address: json['address'] ?? 'Đang cập nhật',
      lat: (json['lat'] ?? 0.0).toDouble(),
      lng: (json['lng'] ?? 0.0).toDouble(),
      rating: (json['rating'] ?? 0.0).toDouble(),
      pricePerNight: (json['pricePerNight'] ?? 0.0).toDouble(),
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      amenities: List<String>.from(json['amenities'] ?? []),
      description: json['description'] ?? 'Không có mô tả',
    );
  }
}