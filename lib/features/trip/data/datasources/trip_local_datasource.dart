import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/trip_model.dart';

class TripLocalDataSource {
  final SharedPreferences _prefs;
  static const String _key = 'cached_trips';

  TripLocalDataSource(this._prefs);

  Future<void> cacheTrips(List<TripModel> trips) async {
    final jsonList = trips.map((trip) => trip.toJson()).toList();
    await _prefs.setString(_key, jsonEncode(jsonList));
  }

  Future<List<TripModel>?> getCachedTrips() async {
    final jsonString = _prefs.getString(_key);
    if (jsonString == null) return null;

    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((json) => TripModel.fromJson(json)).toList();
  }

  Future<void> clearCache() async {
    await _prefs.remove(_key);
  }
}
