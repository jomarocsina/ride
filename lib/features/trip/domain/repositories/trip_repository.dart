import '../entities/trip.dart';

abstract class TripRepository {
  Future<List<Trip>> getTrips();
  Future<void> addTrip(Trip trip);
  Future<void> deleteTrip(Trip trip);
}
