import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/trip_local_datasource.dart';
import '../../data/repositories/trip_repository_impl.dart';
import '../../domain/entities/trip.dart';
import '../../domain/repositories/trip_repository.dart';
import '../../domain/usecases/add_trip.dart';
import '../../domain/usecases/get_trips.dart';
import '../../domain/usecases/delete_trip.dart';

part 'trip_provider.g.dart';

@riverpod
Future<SharedPreferences> sharedPreferences(SharedPreferencesRef ref) {
  return SharedPreferences.getInstance();
}

@riverpod
TripLocalDataSource tripLocalDataSource(TripLocalDataSourceRef ref) {
  final prefs = ref.watch(sharedPreferencesProvider).value;
  if (prefs == null) throw Exception('SharedPreferences not initialized');
  return TripLocalDataSource(prefs);
}

@riverpod
TripRepository tripRepository(TripRepositoryRef ref) {
  final localDataSource = ref.watch(tripLocalDataSourceProvider);
  return TripRepositoryImpl(localDataSource);
}

@riverpod
GetTrips getTrips(GetTripsRef ref) {
  final repository = ref.watch(tripRepositoryProvider);
  return GetTrips(repository);
}

@riverpod
AddTrip addTrip(AddTripRef ref) {
  final repository = ref.watch(tripRepositoryProvider);
  return AddTrip(repository);
}

@riverpod
DeleteTrip deleteTrip(DeleteTripRef ref) {
  final repository = ref.watch(tripRepositoryProvider);
  return DeleteTrip(repository);
}

@riverpod
Future<List<Trip>> trips(TripsRef ref) async {
  final getTrips = ref.watch(getTripsProvider);
  return getTrips();
}
