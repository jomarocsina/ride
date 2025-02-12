import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/entities/trip.dart';

part 'trip_model.freezed.dart';
part 'trip_model.g.dart';

@freezed
class TripModel with _$TripModel implements Trip {
  const factory TripModel({
    required String startLocation,
    required String destination,
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
    required DateTime date,
    required double fare,
  }) = _TripModel;

  factory TripModel.fromJson(Map<String, dynamic> json) =>
      _$TripModelFromJson(json);

  factory TripModel.fromTrip(Trip trip) => TripModel(
        startLocation: trip.startLocation,
        destination: trip.destination,
        startLatitude: trip.startLatitude,
        startLongitude: trip.startLongitude,
        endLatitude: trip.endLatitude,
        endLongitude: trip.endLongitude,
        date: trip.date,
        fare: trip.fare,
      );
}
