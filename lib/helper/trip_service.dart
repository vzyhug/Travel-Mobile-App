import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/trip_model.dart';

class TripService {
  static const String _url = 'https://my-json-server.typicode.com/vzyhug/data-travel-trips/trips';

  Future<List<TripModel>> getTrips() async {
    try {
      final response = await http.get(Uri.parse(_url));
      
      if (response.statusCode == 200) {
        final List<dynamic> tripsJson = jsonDecode(response.body);
        return tripsJson.map((item) {
          return TripModel.fromJson(Map<String, dynamic>.from(item));
        }).toList();
      } else {
        throw Exception('Server returned status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Không thể đọc dữ liệu trips từ API: $e');
    }
  }
}
