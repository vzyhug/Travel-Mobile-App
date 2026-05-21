import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/trip_model.dart';

class TripService {
  Future<List<TripModel>> getTrips() async {
    try {
      final String jsonString = await rootBundle.loadString('assets/data/db.json');
      final dynamic jsonData = jsonDecode(jsonString);

      final List<dynamic> tripsJson = jsonData is List
          ? jsonData
          : List<dynamic>.from(jsonData['trips'] ?? []);

      return tripsJson.map((item) {
        return TripModel.fromJson(Map<String, dynamic>.from(item));
      }).toList();
    } catch (e) {
      throw Exception('Không thể đọc dữ liệu trips từ db.json: $e');
    }
  }
}
