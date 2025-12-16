import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<Position>? _positionStreamSubscription;

  /// Starts tracking location and uploading to Firestore.
  /// [distanceFilter] ensures updates only happen when device moves significantly (meters).
  Future<void> startTracking(String parentUid, String childId) async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Check Service
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Service disabled, cannot track.
      // In a real app, you might ask user to enable it.
      print('Location services are disabled.');
      return;
    }

    // 2. Check Permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Location permissions are permanently denied');
      return;
    }

    // 3. Start Stream
    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 50, // Update every 50 meters to save battery
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            _uploadLocation(parentUid, childId, position);
          },
        );
  }

  /// Stops tracking.
  void stopTracking() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  /// Uploads a single location point.
  Future<void> _uploadLocation(
    String parentUid,
    String childId,
    Position position,
  ) async {
    try {
      // Update the 'current' location on the Child document for quick access
      await _firestore
          .collection('users')
          .doc(parentUid)
          .collection('children')
          .doc(childId)
          .update({
            'currentLocation': {
              'latitude': position.latitude,
              'longitude': position.longitude,
              'timestamp': FieldValue.serverTimestamp(),
              'speed': position.speed,
              'accuracy': position.accuracy,
            },
          });

      // Optional: Add to history collection if you want a path trail later
      // For MVP, just current location is often enough.
    } catch (e) {
      print('Error uploading location: $e');
    }
  }

  /// Get current position manually (one-time)
  Future<Position?> getCurrentLocation() async {
    try {
      return await Geolocator.getCurrentPosition();
    } catch (e) {
      return null;
    }
  }
}
