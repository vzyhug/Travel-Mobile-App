import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewModel {
  final String id;
  final String itemId;
  final String itemType;
  final String userEmail;
  final String userName;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final String status;

  ReviewModel({
    required this.id,
    required this.itemId,
    required this.itemType,
    required this.userEmail,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.status = 'pending',
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json, String id) {
    return ReviewModel(
      id: id,
      itemId: json['itemId'] ?? '',
      itemType: json['itemType'] ?? '',
      userEmail: json['userEmail'] ?? '',
      userName: json['userName'] ?? 'Người dùng',
      rating: json['rating'] ?? 5,
      comment: json['comment'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      status: json['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'itemType': itemType,
      'userEmail': userEmail,
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
    };
  }
}
