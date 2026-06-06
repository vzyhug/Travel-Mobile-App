class BookingModel {
  final String bookingId;
  final String userEmail;
  final String tripId;
  final String tripName;
  final double price;
  final String location;
  final String imageUrl;
  final String status;
  final String type;
  final DateTime bookedAt;

  BookingModel({
    required this.bookingId,
    required this.userEmail,
    required this.tripId,
    required this.tripName,
    required this.price,
    required this.location,
    required this.imageUrl,
    required this.status,
    required this.type,
    required this.bookedAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      bookingId: json['bookingId'] ?? '',
      userEmail: json['userEmail'] ?? '',
      tripId: json['tripId'] ?? '',
      tripName: json['tripName'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      location: json['location'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      status: json['status'] ?? 'Chờ duyệt',
      type: json['type'] ?? 'trip',
      bookedAt: json['bookedAt'] != null ? DateTime.parse(json['bookedAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookingId': bookingId,
      'userEmail': userEmail,
      'tripId': tripId,
      'tripName': tripName,
      'price': price,
      'location': location,
      'imageUrl': imageUrl,
      'status': status,
      'type': type,
      'bookedAt': bookedAt.toIso8601String(),
    };
  }
}
