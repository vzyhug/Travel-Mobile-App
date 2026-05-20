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
    return TripModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      type: json['type'] ?? '',
      duration: json['duration'] ?? '',
      location: json['location'] ?? '',
      country: json['country'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      rating: (json['rating'] ?? 0).toDouble(),
      price: json['price'] ?? 0,
      description: json['description'] ?? '',
      gallery: List<String>.from(json['gallery'] ?? []),
    );
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
