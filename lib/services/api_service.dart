import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:travel_application/models/account_model.dart';
import '../models/hotel_model.dart';
import '../models/room_model.dart';

class ApiService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Account>> fetchAccounts() async {
    try {
      final snapshot = await _firestore.collection('accounts').get();
      return snapshot.docs.map((doc) => Account.fromFirestore(doc)).toList();
    } catch (e) {
      throw Exception('Error fetching accounts: $e');
    }
  }

  Future<bool> registerAccount(Account account) async {
    try {
      await _firestore.collection('accounts').add(account.toJson());
      return true;
    } catch (e) {
      print('Error calling firestore register: $e');
      return false;
    }
  }

  static Future<List<HotelModel>> fetchHotels() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('hotels').get();
      return snapshot.docs.map((doc) => HotelModel.fromFirestore(doc)).toList();
    } catch (e) {
      print("Error fetching data from API Hotels: $e");
      return [];
    }
  }

  static Future<List<RoomModel>> fetchRooms() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('rooms').get();
      return snapshot.docs.map((doc) => RoomModel.fromFirestore(doc)).toList();
    } catch (e) {
      print("Error fetching data from API Rooms: $e");
      return [];
    }
  }
}
