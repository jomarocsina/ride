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
    if (_random.nextInt(3) == 0) {
      throw Exception(
          '[Mock] Failed to load trips - This is a simulated API failure');
    }

    final cachedTrips = await _localDataSource.getCachedTrips();
    if (cachedTrips != null) {
      _trips = cachedTrips;
      return cachedTrips;
    }

    await Future.delayed(const Duration(seconds: 1));

    _trips = [];
    await _localDataSource.cacheTrips(_trips);
    return _trips;
  }

  @override
  Future<void> addTrip(Trip trip) async {
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

    _trips.insert(0, tripModel);

    await _localDataSource.cacheTrips(_trips);
  }

  @override
  Future<void> deleteTrip(Trip trip) async {
    _trips.removeWhere(
      (t) =>
          t.startLatitude == trip.startLatitude &&
          t.startLongitude == trip.startLongitude &&
          t.endLatitude == trip.endLatitude &&
          t.endLongitude == trip.endLongitude &&
          t.date == trip.date,
    );

    await _localDataSource.cacheTrips(_trips);
  }
}
