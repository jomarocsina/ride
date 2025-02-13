import 'package:shared_preferences/shared_preferences.dart';
import 'trip_local_datasource.dart';
import '../models/trip_model.dart';

class TripLocalDataSourceImpl implements TripLocalDataSource {
  final SharedPreferences sharedPreferences;

  TripLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<List<TripModel>> getTrips() async {
    return [];
  }

  @override
  Future<void> saveTrip(TripModel trip) async {}

  @override
  Future<void> deleteTrip(TripModel trip) async {}

  @override
  Future<List<TripModel>?> getCachedTrips() async {
    return null;
  }

  @override
  Future<void> cacheTrips(List<TripModel> trips) async {}

  @override
  Future<void> clearCache() async {}
}
