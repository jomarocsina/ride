import '../models/trip.dart';

class TripService {
  // In a real app, this would fetch data from an API
  Future<List<Trip>> getTrips() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Return sample data
    return [
      Trip(
        startLocation: 'London Bridge Station',
        destination: 'Heathrow Airport',
        startLatitude: 51.5079,
        startLongitude: -0.0877,
        endLatitude: 51.4700,
        endLongitude: -0.4543,
        date: DateTime.now().subtract(const Duration(days: 1)),
        fare: 45.50,
      ),
      Trip(
        startLocation: 'Canary Wharf',
        destination: 'Oxford Street',
        startLatitude: 51.5054,
        startLongitude: -0.0235,
        endLatitude: 51.5152,
        endLongitude: -0.1418,
        date: DateTime.now().subtract(const Duration(days: 2)),
        fare: 25.75,
      ),
      Trip(
        startLocation: 'King\'s Cross Station',
        destination: 'The O2 Arena',
        startLatitude: 51.5320,
        startLongitude: -0.1240,
        endLatitude: 51.5030,
        endLongitude: 0.0032,
        date: DateTime.now().subtract(const Duration(days: 3)),
        fare: 32.00,
      ),
    ];
  }
}
