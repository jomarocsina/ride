import 'dart:math' show min, max;
import 'dart:convert' show json;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:http/http.dart' as http;
import '../../data/datasources/directions_service.dart';
import '../../domain/entities/trip.dart';
import '../providers/trip_provider.dart';

class AddTripScreen extends ConsumerStatefulWidget {
  const AddTripScreen({super.key});

  @override
  ConsumerState<AddTripScreen> createState() => _AddTripScreenState();
}

class _AddTripScreenState extends ConsumerState<AddTripScreen> {
  final _formKey = GlobalKey<FormState>();
  late GoogleMapController _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final _directionsService = DirectionsService();
  bool _isLoadingRoute = false;
  bool _selectingLocation = false;
  bool _isSelectingStart = true;
  final _startLocationController = TextEditingController();
  final _destinationController = TextEditingController();
  final _fareController = TextEditingController();
  double? _distanceInMeters;

  String? _startLocation;
  String? _destination;
  LatLng? _startLatLng;
  LatLng? _endLatLng;

  static const _initialCameraPosition = CameraPosition(
    target: LatLng(51.5074, -0.1278), // London
    zoom: 12,
  );

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _updateMarkers() {
    setState(() {
      _markers.clear();
      if (_startLatLng != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('start'),
            position: _startLatLng!,
            infoWindow: InfoWindow(title: _startLocation ?? 'Start'),
          ),
        );
      }
      if (_endLatLng != null) {
        _markers.add(
          Marker(
            markerId: const MarkerId('end'),
            position: _endLatLng!,
            infoWindow: InfoWindow(title: _destination ?? 'Destination'),
          ),
        );
      }
    });

    if (_startLatLng != null && _endLatLng != null) {
      _fitBounds();
      _loadRoute();
    }
  }

  void _fitBounds() {
    if (_startLatLng == null || _endLatLng == null) return;

    final bounds = LatLngBounds(
      southwest: LatLng(
        [_startLatLng!.latitude, _endLatLng!.latitude].reduce(min),
        [_startLatLng!.longitude, _endLatLng!.longitude].reduce(min),
      ),
      northeast: LatLng(
        [_startLatLng!.latitude, _endLatLng!.latitude].reduce(max),
        [_startLatLng!.longitude, _endLatLng!.longitude].reduce(max),
      ),
    );

    _mapController.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 50.0),
    );
  }

  Future<void> _loadRoute() async {
    if (_startLatLng == null || _endLatLng == null) return;

    setState(() {
      _isLoadingRoute = true;
      _polylines.clear();
    });

    try {
      final points = await _directionsService.getDirections(
        _startLatLng!,
        _endLatLng!,
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

      // Calculate fare based on distance
      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/distancematrix/json'
          '?origins=${_startLatLng!.latitude},${_startLatLng!.longitude}'
          '&destinations=${_endLatLng!.latitude},${_endLatLng!.longitude}'
          '&key=AIzaSyAlm9aA_rmQ2Wz5TEh9AtBY_5E3M3w5lkY',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final distance = data['rows'][0]['elements'][0]['distance']['value'];
          _distanceInMeters = distance.toDouble();
          _calculateFare();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error loading route'),
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

  void _calculateFare() {
    if (_distanceInMeters == null) return;

    // Base fare £2.50
    double fare = 2.50;

    // Add £1.50 per kilometer
    fare += (_distanceInMeters! / 1000) * 1.50;

    // Round to nearest 50p
    fare = (fare * 2).round() / 2;

    setState(() {
      _fareController.text = fare.toStringAsFixed(2);
    });
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (_startLocation == null ||
          _destination == null ||
          _startLatLng == null ||
          _endLatLng == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select both locations')),
        );
        return;
      }

      final trip = _TripForm(
        startLocation: _startLocation!,
        destination: _destination!,
        startLatitude: _startLatLng!.latitude,
        startLongitude: _startLatLng!.longitude,
        endLatitude: _endLatLng!.latitude,
        endLongitude: _endLatLng!.longitude,
        date: DateTime.now(),
        fare: double.parse(_fareController.text),
      );

      try {
        final addTrip = ref.read(addTripProvider);
        await addTrip(trip);
        ref.invalidate(tripsProvider);
        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error adding trip: $e')),
          );
        }
      }
    }
  }

  void _handleMapTap(LatLng position) async {
    if (!_selectingLocation) return;

    try {
      // Get address from coordinates using reverse geocoding
      final response = await http.get(
        Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json'
          '?latlng=${position.latitude},${position.longitude}'
          '&key=AIzaSyAlm9aA_rmQ2Wz5TEh9AtBY_5E3M3w5lkY',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final address = data['results'][0]['formatted_address'];
          setState(() {
            if (_isSelectingStart) {
              _startLocation = address;
              _startLatLng = position;
              _startLocationController.text = address;
            } else {
              _destination = address;
              _endLatLng = position;
              _destinationController.text = address;
            }
            _selectingLocation = false;
            _updateMarkers();
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error getting address from location'),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _fareController.dispose();
    _startLocationController.dispose();
    _destinationController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Full screen map
          GoogleMap(
            initialCameraPosition: _initialCameraPosition,
            onMapCreated: _onMapCreated,
            markers: _markers,
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onTap: _handleMapTap,
          ),

          // Location selection mode indicator
          if (_selectingLocation)
            Positioned(
              top: 120,
              left: 16,
              right: 16,
              child: Card(
                color: Theme.of(context).colorScheme.primary,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        _isSelectingStart ? Icons.trip_origin : Icons.place,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _isSelectingStart
                              ? 'Tap on the map to set start location'
                              : 'Tap on the map to set destination',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        color: Colors.white,
                        onPressed: () {
                          setState(() {
                            _selectingLocation = false;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Loading indicator
          if (_isLoadingRoute)
            const Positioned(
              top: 120,
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

          // Floating back button and title
          Positioned(
            top: 60,
            left: 16,
            right: 16,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'Add New Trip',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.surface,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),

          // Bottom sheet with form
          DraggableScrollableSheet(
            initialChildSize: 0.4,
            minChildSize: 0.2,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Start location search
                        GooglePlaceAutoCompleteTextField(
                          textEditingController: _startLocationController,
                          googleAPIKey:
                              "AIzaSyAlm9aA_rmQ2Wz5TEh9AtBY_5E3M3w5lkY",
                          inputDecoration: InputDecoration(
                            labelText: 'Start Location',
                            prefixIcon: const Icon(Icons.location_on_outlined),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.map),
                              onPressed: () {
                                setState(() {
                                  _selectingLocation = true;
                                  _isSelectingStart = true;
                                });
                              },
                              tooltip: 'Pick on map',
                            ),
                          ),
                          debounceTime: 800,
                          countries: const ["uk"],
                          isLatLngRequired: true,
                          getPlaceDetailWithLatLng: (Prediction prediction) {
                            setState(() {
                              _startLocation = prediction.description;
                              _startLatLng = LatLng(
                                double.parse(prediction.lat!),
                                double.parse(prediction.lng!),
                              );
                              _startLocationController.text =
                                  prediction.description ?? '';
                              _updateMarkers();
                            });
                          },
                          itemClick: (Prediction prediction) {
                            // Handle item click if needed
                          },
                        ),
                        const SizedBox(height: 16),

                        // Destination search
                        GooglePlaceAutoCompleteTextField(
                          textEditingController: _destinationController,
                          googleAPIKey:
                              "AIzaSyAlm9aA_rmQ2Wz5TEh9AtBY_5E3M3w5lkY",
                          inputDecoration: InputDecoration(
                            labelText: 'Destination',
                            prefixIcon: const Icon(Icons.location_on),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.map),
                              onPressed: () {
                                setState(() {
                                  _selectingLocation = true;
                                  _isSelectingStart = false;
                                });
                              },
                              tooltip: 'Pick on map',
                            ),
                          ),
                          debounceTime: 800,
                          countries: const ["uk"],
                          isLatLngRequired: true,
                          getPlaceDetailWithLatLng: (Prediction prediction) {
                            setState(() {
                              _destination = prediction.description;
                              _endLatLng = LatLng(
                                double.parse(prediction.lat!),
                                double.parse(prediction.lng!),
                              );
                              _destinationController.text =
                                  prediction.description ?? '';
                              _updateMarkers();
                            });
                          },
                          itemClick: (Prediction prediction) {
                            // Handle item click if needed
                          },
                        ),
                        const SizedBox(height: 16),

                        // Fare display
                        TextFormField(
                          controller: _fareController,
                          decoration: const InputDecoration(
                            labelText: 'Fare',
                            prefixIcon: Icon(Icons.attach_money),
                            prefixText: '£',
                          ),
                          enabled: false,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Submit button
                        ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(16),
                          ),
                          child: const Text('Add Trip'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _TripForm implements Trip {
  @override
  final String startLocation;
  @override
  final String destination;
  @override
  final double startLatitude;
  @override
  final double startLongitude;
  @override
  final double endLatitude;
  @override
  final double endLongitude;
  @override
  final DateTime date;
  @override
  final double fare;

  _TripForm({
    required this.startLocation,
    required this.destination,
    required this.startLatitude,
    required this.startLongitude,
    required this.endLatitude,
    required this.endLongitude,
    required this.date,
    required this.fare,
  });
}
