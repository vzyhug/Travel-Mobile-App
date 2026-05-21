class TripModel {
  final int id;
  final String name;
  final String category;
  final String type;
  final String duration;
  final String location;
  final String country;
  final String imageUrl;
  final double rating;
  final int price;
  final String description;
  final List<String> gallery;

  const TripModel({
    required this.id,
    required this.name,
    required this.category,
    required this.type,
    required this.duration,
    required this.location,
    required this.country,
    required this.imageUrl,
    required this.rating,
    required this.price,
    required this.description,
    required this.gallery,
  });

  factory TripModel.fromJson(Map<String, dynamic> json) {
    final location = (json['location'] ?? '').toString();
    final locationParts = location.split(',').map((item) => item.trim()).where((item) => item.isNotEmpty).toList();

    return TripModel(
      id: _toInt(json['id']),
      name: (json['name'] ?? json['title'] ?? '').toString(),
      category: (json['category'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      duration: (json['duration'] ?? '').toString(),
      location: location,
      country: (json['country'] ?? (locationParts.isNotEmpty ? locationParts.last : '')).toString(),
      imageUrl: (json['imageUrl'] ?? json['image'] ?? '').toString(),
      rating: _toDouble(json['rating']),
      price: _toInt(json['price']),
      description: (json['description'] ?? '').toString(),
      gallery: List<String>.from(json['gallery'] ?? []),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'type': type,
      'duration': duration,
      'location': location,
      'country': country,
      'imageUrl': imageUrl,
      'rating': rating,
      'price': price,
      'description': description,
      'gallery': gallery,
    };
  }
}
