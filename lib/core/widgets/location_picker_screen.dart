import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'app_button.dart';
import 'app_text_field.dart';
import '../theme/app_theme.dart';

class LocationPickerScreen extends StatefulWidget {
  final LatLng? initialPosition;
  
  const LocationPickerScreen({
    super.key,
    this.initialPosition,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  late LatLng _currentPosition;
  String _currentAddress = 'Move map to select location';
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  // Riyadh default
  static const LatLng _defaultPosition = LatLng(24.7136, 46.6753);

  @override
  void initState() {
    super.initState();
    _currentPosition = widget.initialPosition ?? _defaultPosition;
    if (widget.initialPosition != null) {
      _getAddressFromLatLng(widget.initialPosition!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    setState(() => _isLoading = true);
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        setState(() {
          _currentAddress = [
            place.street,
            place.subLocality,
            place.locality,
            place.country
          ].where((e) => e != null && e.isNotEmpty).join(', ');
        });
      }
    } catch (e) {
      setState(() => _currentAddress = 'Could not fetch address');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchAddress(String query) async {
    if (query.isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final loc = locations.first;
        final target = LatLng(loc.latitude, loc.longitude);
        
        final GoogleMapController controller = await _controller.future;
        controller.animateCamera(CameraUpdate.newCameraPosition(
          CameraPosition(target: target, zoom: 16),
        ));
        
        // Address will be updated by onCameraIdle
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Address not found')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onCameraIdle() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _getAddressFromLatLng(_currentPosition);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 15,
            ),
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
            onCameraMove: (CameraPosition position) {
              _currentPosition = position.target;
            },
            onCameraIdle: _onCameraIdle,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          
          // Center Marker
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40), // Adjust for pin tip
              child: Icon(
                Icons.location_on,
                size: 50,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          
          // Top Search Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search address...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: () => _searchAddress(_searchController.text),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, 
                      vertical: 14,
                    ),
                  ),
                  onSubmitted: _searchAddress,
                ),
              ),
            ),
          ),
          
          // Bottom Sheet
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 20,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Selected Location',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currentAddress,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 24),
                  AppButton(
                    text: 'Confirm Location',
                    isLoading: _isLoading,
                    onPressed: () {
                      Navigator.pop(context, {
                        'address': _currentAddress,
                        'lat': _currentPosition.latitude,
                        'lng': _currentPosition.longitude,
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    text: 'Cancel',
                    variant: AppButtonVariant.text,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ),
          
          // Back Button
          Positioned(
            top: 50, // Below SafeArea
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
