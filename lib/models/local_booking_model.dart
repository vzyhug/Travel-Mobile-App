class LocalBookingModel {
  final String bookingId;
  final String tripId;
  final String tripName;
  final double price;
  final String location;
  final String imageUrl;
  final DateTime bookedAt;

  LocalBookingModel({
    required this.bookingId,
    required dynamic tripId,
    required this.tripName,
    required this.price,
    required this.location,
    required this.imageUrl,
    required this.bookedAt,
  }) : tripId = tripId.toString();

  factory LocalBookingModel.fromJson(Map<String, dynamic> json) {
    return LocalBookingModel(
      bookingId: json['bookingId'] ?? '',
      tripId: json['tripId'] ?? '',
      tripName: json['tripName'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      location: json['location'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      bookedAt: json['bookedAt'] != null
          ? DateTime.parse(json['bookedAt'])
          : DateTime.now(),
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