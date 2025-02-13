import '../entities/trip.dart';
import '../repositories/trip_repository.dart';

class AddTrip {
  final TripRepository repository;

  AddTrip(this.repository);

  Future<void> call(Trip trip) async {
    await repository.addTrip(trip);
  }
}
