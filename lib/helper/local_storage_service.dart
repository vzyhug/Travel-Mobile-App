import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/local_booking_model.dart';

class LocalStorageService {
  static const String _favoriteKey = 'favorite_trip_ids';
  static const String _bookingKey = 'booked_trips';

  static const String _favoriteHotelKey = 'favorite_hotel_ids';

  Future<Set<int>> getFavoriteTripIds() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> ids = prefs.getStringList(_favoriteKey) ?? [];
    return ids.map((id) => int.tryParse(id) ?? 0).where((id) => id > 0).toSet();
  }

  Future<void> saveFavoriteTripIds(Set<int> favoriteIds) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = favoriteIds.map((id) => id.toString()).toList();
    await prefs.setStringList(_favoriteKey, ids);
  }

  Future<void> toggleFavorite(int tripId) async {
    final favorites = await getFavoriteTripIds();
    if (favorites.contains(tripId)) {
      favorites.remove(tripId);
    } else {
      favorites.add(tripId);
    }
    await saveFavoriteTripIds(favorites);
  }

  Future<bool> isFavorite(int tripId) async {
    final favorites = await getFavoriteTripIds();
    return favorites.contains(tripId);
  }

  Future<Set<String>> getFavoriteHotelIds() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> ids = prefs.getStringList(_favoriteHotelKey) ?? [];
    return ids.toSet();
  }

  Future<void> saveFavoriteHotelIds(Set<String> favoriteIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_favoriteHotelKey, favoriteIds.toList());
  }

  Future<void> toggleFavoriteHotel(String hotelId) async {
    final favorites = await getFavoriteHotelIds();
    if (favorites.contains(hotelId)) {
      favorites.remove(hotelId);
    } else {
      favorites.add(hotelId);
    }
    await saveFavoriteHotelIds(favorites);
  }

  Future<bool> isFavoriteHotel(String hotelId) async {
    final favorites = await getFavoriteHotelIds();
    return favorites.contains(hotelId);
  }

  Future<List<LocalBookingModel>> getBookings() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> bookingStrings = prefs.getStringList(_bookingKey) ?? [];
    return bookingStrings.map((item) {
      final Map<String, dynamic> json = jsonDecode(item);
      return LocalBookingModel.fromJson(json);
    }).toList();
  }

  Future<void> addBooking(LocalBookingModel booking) async {
    final prefs = await SharedPreferences.getInstance();
    final bookings = await getBookings();
    final alreadyBooked = bookings.any((item) => item.tripId == booking.tripId);
    if (!alreadyBooked) {
      bookings.add(booking);
    }
    final bookingStrings = bookings.map((booking) => jsonEncode(booking.toJson())).toList();
    await prefs.setStringList(_bookingKey, bookingStrings);
  }

  Future<bool> hasBookedTrip(int tripId) async {
    final bookings = await getBookings();
    return bookings.any((booking) => booking.tripId == tripId.toString());
  }

  Future<bool> hasBookedHotel(String hotelId) async {
    final bookings = await getBookings();
    return bookings.any((booking) => booking.tripId == hotelId);
  }

  Future<void> clearBookings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_bookingKey);
  }

  Future<void> clearFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_favoriteKey);
    await prefs.remove(_favoriteHotelKey);
  }

  static const String _userEmailKey = 'logged_in_user_email';
  static const String _userNameKey = 'logged_in_user_name';

  Future<void> saveUserSession({required String email, required String name}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userEmailKey, email);
    await prefs.setString(_userNameKey, name);
  }

  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  Future<void> clearUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userEmailKey);
    await prefs.remove(_userNameKey);
  }
}