import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/repositories/trip_repository_impl.dart';
import '../../domain/entities/trip.dart';
import '../../domain/repositories/trip_repository.dart';
import '../../domain/usecases/get_trips.dart';

part 'trip_provider.g.dart';

@riverpod
TripRepository tripRepository(TripRepositoryRef ref) {
  return TripRepositoryImpl();
}

@riverpod
GetTrips getTrips(GetTripsRef ref) {
  final repository = ref.watch(tripRepositoryProvider);
  return GetTrips(repository);
}

@riverpod
Future<List<Trip>> trips(TripsRef ref) async {
  final getTrips = ref.watch(getTripsProvider);
  return getTrips();
}
