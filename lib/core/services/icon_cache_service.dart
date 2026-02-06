import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../utils/map_utils.dart';

/// Singleton service for caching map marker icons
/// Prevents expensive icon generation on every screen load
class IconCacheService {
  static final IconCacheService _instance = IconCacheService._internal();
  factory IconCacheService() => _instance;
  IconCacheService._internal();

  // Cached icons
  BitmapDescriptor? _busIcon;
  BitmapDescriptor? _pickupIcon;
  BitmapDescriptor? _dropoffIcon;
  BitmapDescriptor? _completedIcon;
  BitmapDescriptor? _destinationIcon;

  bool _isInitialized = false;
  bool _isInitializing = false;

  /// Check if icons are loaded
  bool get isReady => _isInitialized;

  /// Get all icons (null if not loaded)
  ({
    BitmapDescriptor? bus,
    BitmapDescriptor? pickup,
    BitmapDescriptor? dropoff,
    BitmapDescriptor? completed,
    BitmapDescriptor? destination,
  }) get icons => (
    bus: _busIcon,
    pickup: _pickupIcon,
    dropoff: _dropoffIcon,
    completed: _completedIcon,
    destination: _destinationIcon,
  );

  /// Initialize icons asynchronously
  /// Safe to call multiple times - will only initialize once
  Future<void> initialize() async {
    if (_isInitialized || _isInitializing) return;
    
    _isInitializing = true;
    
    try {
      // Load all icons in parallel
      final results = await Future.wait([
        MapUtils.getResponsiveAssetIcon(
          'assets/images/bus_marker.png',
          baseSize: 50,
        ),
        MapUtils.createCustomMarker(Icons.home, Colors.orange, baseSize: 45),
        MapUtils.createCustomMarker(Icons.school, Colors.red, baseSize: 45),
        MapUtils.createCustomMarker(Icons.check_circle, Colors.green, baseSize: 45),
        MapUtils.createCustomMarker(Icons.flag, Colors.purple, baseSize: 45),
      ]);

      _busIcon = results[0];
      _pickupIcon = results[1];
      _dropoffIcon = results[2];
      _completedIcon = results[3];
      _destinationIcon = results[4];

      _isInitialized = true;
    } catch (e) {
      _isInitialized = false;
    } finally {
      _isInitializing = false;
    }
  }

  void clear() {
    _busIcon = null;
    _pickupIcon = null;
    _dropoffIcon = null;
    _completedIcon = null;
    _destinationIcon = null;
    _isInitialized = false;
  }

  /// Preload icons early in app lifecycle
  /// Call this in main() or app initialization
  static Future<void> preload() async {
    await IconCacheService().initialize();
  }
}
