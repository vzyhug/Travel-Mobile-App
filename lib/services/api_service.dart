import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:travel_application/models/account_model.dart';
import '../models/hotel_model.dart';
import '../models/room_model.dart';

class ApiService {
  // Endpoint của Accounts
  static const String _accountsUrl = 'https://my-json-server.typicode.com/vzyhug/data-accounts';

  // Endpoint của Hotels
  static const String _hotelsUrl = 'https://my-json-server.typicode.com/vzyhug/data-travel-hotels';

  Future<List<Account>> fetchAccounts() async {
    try {
      final response = await http.get(Uri.parse('$_accountsUrl/accounts'));

      if (response.statusCode == 200) {
        List<dynamic> jsonList = json.decode(response.body);
        List<Account> accounts = jsonList
            .map((json) => Account.fromJson(json))
            .toList();
        return accounts;
      } else {
        throw Exception(
          'Failed to load accounts. Status Code: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error fetching accounts: $e');
    }
  }

  static Future<List<HotelModel>> fetchHotels() async {
    try {
      final response = await http.get(Uri.parse('$_hotelsUrl/hotels?v=2'));

      if (response.statusCode == 200) {
        final String decodedBody = utf8.decode(response.bodyBytes);
        List<dynamic> data = json.decode(decodedBody);
        return data.map((json) => HotelModel.fromJson(json)).toList();
      } else {
        throw Exception('Error server: ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching data from API Hotels: $e");
      return [];
    }
  }

  static Future<List<RoomModel>> fetchRooms() async {
    try {
      final response = await http.get(Uri.parse('$_hotelsUrl/rooms?v=2'));

      if (response.statusCode == 200) {
        final String decodedBody = utf8.decode(response.bodyBytes);
        List<dynamic> data = json.decode(decodedBody);
        return data.map((json) => RoomModel.fromJson(json)).toList();
      } else {
        throw Exception('Error server: ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching data from API Rooms: $e");
      return [];
    }
  }
}