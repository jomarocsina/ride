import '../../domain/entities/trip.dart';
import '../../domain/repositories/trip_repository.dart';
import '../datasources/trip_local_datasource.dart';
import '../models/trip_model.dart';
import 'dart:math' show Random;

class TripRepositoryImpl implements TripRepository {
  final TripLocalDataSource _localDataSource;
  final _random = Random();
  List<TripModel> _trips = [];

  TripRepositoryImpl(this._localDataSource);

  @override
  Future<List<Trip>> getTrips() async {
    // Simulate API failure (1 in 3 chance)
    if (_random.nextInt(3) == 0) {
      throw Exception(
          '[Mock] Failed to load trips - This is a simulated API failure');
    }

    // Try to get cached data first
    final cachedTrips = await _localDataSource.getCachedTrips();
    if (cachedTrips != null) {
      _trips = cachedTrips;
      return cachedTrips;
    }

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Initialize empty list if no cached data
    _trips = [];
    await _localDataSource.cacheTrips(_trips);
    return _trips;
  }

  @override
  Future<void> addTrip(Trip trip) async {
    // Convert Trip to TripModel if it's not already
    final tripModel = trip is TripModel
        ? trip
        : TripModel(
            startLocation: trip.startLocation,
            destination: trip.destination,
            startLatitude: trip.startLatitude,
            startLongitude: trip.startLongitude,
            endLatitude: trip.endLatitude,
            endLongitude: trip.endLongitude,
            date: trip.date,
            fare: trip.fare,
          );

    // Add to local list
    _trips.insert(0, tripModel);

    // Update cache
    await _localDataSource.cacheTrips(_trips);
  }

  @override
  Future<void> deleteTrip(Trip trip) async {
    // Remove from local list
    _trips.removeWhere(
      (t) =>
          t.startLatitude == trip.startLatitude &&
          t.startLongitude == trip.startLongitude &&
          t.endLatitude == trip.endLatitude &&
          t.endLongitude == trip.endLongitude &&
          t.date == trip.date,
    );

    // Update cache
    await _localDataSource.cacheTrips(_trips);
  }
}
