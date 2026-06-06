class WishlistModel {
  final String id;
  final String userEmail;
  final String itemId;
  final String itemType; // 'hotel' or 'trip'
  final DateTime addedAt;

  WishlistModel({
    required this.id,
    required this.userEmail,
    required this.itemId,
    required this.itemType,
    required this.addedAt,
  });

  factory WishlistModel.fromJson(Map<String, dynamic> json) {
    return WishlistModel(
      id: json['id'] ?? '',
      userEmail: json['userEmail'] ?? '',
      itemId: json['itemId'] ?? '',
      itemType: json['itemType'] ?? 'trip',
      addedAt: json['addedAt'] != null ? DateTime.parse(json['addedAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userEmail': userEmail,
      'itemId': itemId,
      'itemType': itemType,
      'addedAt': addedAt.toIso8601String(),
    };
  }
}
