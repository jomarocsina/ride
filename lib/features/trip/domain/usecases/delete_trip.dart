import '../entities/trip.dart';
import '../repositories/trip_repository.dart';

class DeleteTrip {
  final TripRepository repository;

  DeleteTrip(this.repository);

  Future<void> call(Trip trip) async {
    await repository.deleteTrip(trip);
  }
}
