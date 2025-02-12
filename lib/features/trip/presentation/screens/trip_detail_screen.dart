import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../domain/entities/trip.dart';
import 'dart:math' show min, max;

class TripDetailScreen extends StatefulWidget {
  final Trip trip;

  const TripDetailScreen({
    super.key,
    required this.trip,
  });

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _markers.addAll([
      Marker(
        markerId: const MarkerId('start'),
        position: LatLng(widget.trip.startLatitude, widget.trip.startLongitude),
        infoWindow: InfoWindow(title: widget.trip.startLocation),
      ),
      Marker(
        markerId: const MarkerId('end'),
        position: LatLng(widget.trip.endLatitude, widget.trip.endLongitude),
        infoWindow: InfoWindow(title: widget.trip.destination),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final startLocation = LatLng(
      widget.trip.startLatitude,
      widget.trip.startLongitude,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Details'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: startLocation,
                zoom: 12,
              ),
              markers: _markers,
              onMapCreated: (controller) {
                _mapController = controller;
                _fitBounds();
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'From: ${widget.trip.startLocation}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'To: ${widget.trip.destination}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Date: ${widget.trip.date.toString()}',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Fare: £${widget.trip.fare.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).primaryColor,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _fitBounds() {
    final bounds = LatLngBounds(
      southwest: LatLng(
        [widget.trip.startLatitude, widget.trip.endLatitude].reduce(min),
        [widget.trip.startLongitude, widget.trip.endLongitude].reduce(min),
      ),
      northeast: LatLng(
        [widget.trip.startLatitude, widget.trip.endLatitude].reduce(max),
        [widget.trip.startLongitude, widget.trip.endLongitude].reduce(max),
      ),
    );

    _mapController.animateCamera(
      CameraUpdate.newLatLngBounds(
        bounds,
        50.0,
      ),
    );
  }

  @override
  void dispose() {
    if (_mapController != null) {
      _mapController.dispose();
    }
    super.dispose();
  }
}
