import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../data/datasources/directions_service.dart';
import '../../domain/entities/trip.dart';
import '../providers/trip_provider.dart';
import 'dart:math' show min, max;

class TripDetailScreen extends ConsumerStatefulWidget {
  final Trip trip;

  const TripDetailScreen({
    super.key,
    required this.trip,
  });

  @override
  ConsumerState<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends ConsumerState<TripDetailScreen> {
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final _directionsService = DirectionsService();
  bool _isLoadingRoute = false;

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
    _loadRoute();
  }

  Future<void> _loadRoute() async {
    setState(() {
      _isLoadingRoute = true;
    });

    try {
      final points = await _directionsService.getDirections(
        LatLng(widget.trip.startLatitude, widget.trip.startLongitude),
        LatLng(widget.trip.endLatitude, widget.trip.endLongitude),
      );

      setState(() {
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: points,
            color: Theme.of(context).primaryColor,
            width: 4,
          ),
        );
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading route: $e'),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: _loadRoute,
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingRoute = false;
        });
      }
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteConfirmation(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: startLocation,
                    zoom: 12,
                  ),
                  markers: _markers,
                  polylines: _polylines,
                  onMapCreated: (controller) {
                    _mapController = controller;
                    _fitBounds();
                  },
                ),
                if (_isLoadingRoute)
                  const Positioned(
                    top: 16,
                    right: 16,
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text('Loading route...'),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
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
                  'Date: ${_formatDate(widget.trip.date)}',
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Trip'),
        content: const Text('Are you sure you want to delete this trip?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final deleteTrip = ref.read(deleteTripProvider);
        await deleteTrip(widget.trip);
        ref.invalidate(tripsProvider);
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting trip: $e')),
          );
        }
      }
    }
  }
}
