import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/local_booking_model.dart';

class LocalStorageService {
  static const String _favoriteKey = 'favorite_trip_ids';
  static const String _bookingKey = 'booked_trips';

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

    bookings.add(booking);

    final bookingStrings = bookings.map((booking) {
      return jsonEncode(booking.toJson());
    }).toList();

    await prefs.setStringList(_bookingKey, bookingStrings);
  }

  Future<bool> hasBookedTrip(int tripId) async {
    final bookings = await getBookings();
    return bookings.any((booking) => booking.tripId == tripId);
  }

  Future<void> clearBookings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_bookingKey);
  }

  Future<void> clearFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_favoriteKey);
  }
}
