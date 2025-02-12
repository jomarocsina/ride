class Trip {
  final String startLocation;
  final String destination;
  final double startLatitude;
  final double startLongitude;
  final double endLatitude;
  final double endLongitude;
  final DateTime date;
  final double fare;

  Trip({
    required this.startLocation,
    required this.destination,
    required this.startLatitude,
    required this.startLongitude,
    required this.endLatitude,
    required this.endLongitude,
    required this.date,
    required this.fare,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      startLocation: json['startLocation'] as String,
      destination: json['destination'] as String,
      startLatitude: (json['startLatitude'] as num).toDouble(),
      startLongitude: (json['startLongitude'] as num).toDouble(),
      endLatitude: (json['endLatitude'] as num).toDouble(),
      endLongitude: (json['endLongitude'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      fare: (json['fare'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startLocation': startLocation,
      'destination': destination,
      'startLatitude': startLatitude,
      'startLongitude': startLongitude,
      'endLatitude': endLatitude,
      'endLongitude': endLongitude,
      'date': date.toIso8601String(),
      'fare': fare,
    };
  }
}
