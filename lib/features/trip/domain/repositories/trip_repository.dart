import '../entities/trip.dart';

abstract class TripRepository {
  Future<List<Trip>> getTrips();
}
