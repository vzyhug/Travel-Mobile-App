class LocalBookingModel {
  final String bookingId;
  final int tripId;
  final String tripName;
  final int price;
  final String location;
  final String imageUrl;
  final DateTime bookedAt;

  const LocalBookingModel({
    required this.bookingId,
    required this.tripId,
    required this.tripName,
    required this.price,
    required this.location,
    required this.imageUrl,
    required this.bookedAt,
  });

  factory LocalBookingModel.fromJson(Map<String, dynamic> json) {
    return LocalBookingModel(
      bookingId: json['bookingId'] ?? '',
      tripId: json['tripId'] ?? 0,
      tripName: json['tripName'] ?? '',
      price: json['price'] ?? 0,
      location: json['location'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      bookedAt: DateTime.tryParse(json['bookedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'tripId': tripId,
      'tripName': tripName,
      'price': price,
      'location': location,
      'imageUrl': imageUrl,
      'bookedAt': bookedAt.toIso8601String(),
    };
  }
}
