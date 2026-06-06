import 'package:cloud_firestore/cloud_firestore.dart';

class Account {
  final int id;
  final String name;
  final String email;
  final String password;
  final String role;
  final bool isLocked;

  Account({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    this.role = 'user',
    this.isLocked = false,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      password: json['password']?.toString() ?? '',
      role: json['role']?.toString() ?? 'user',
      isLocked: json['isLocked'] == true,
    );
  }

  factory Account.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Account(
      id: int.tryParse(data['id']?.toString() ?? '') ?? 0,
      name: data['name']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      password: data['password']?.toString() ?? '',
      role: data['role']?.toString() ?? 'user',
      isLocked: data['isLocked'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      'isLocked': isLocked,
    };
  }
}
