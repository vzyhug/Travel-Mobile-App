import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/trip_model.dart';

class TripService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<TripModel>> getTrips() async {
    try {
      final snapshot = await _firestore.collection('trips').get();
      return snapshot.docs.map((doc) {
        return TripModel.fromFirestore(doc);
      }).toList();
    } catch (e) {
      throw Exception('Không thể đọc dữ liệu trips từ API: $e');
    }
  }
}

