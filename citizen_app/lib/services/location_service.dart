import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  // Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Check location permissions
  Future<LocationPermission> checkLocationPermission() async {
    return await Geolocator.checkPermission();
  }

  // Request location permissions
  Future<LocationPermission> requestLocationPermission() async {
    return await Geolocator.requestPermission();
  }

  // Get current position
  Future<Position> getCurrentPosition() async {
    // Check if location services are enabled
    bool serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationServiceDisabledException('Location services are disabled');
    }

    // Check permissions
    LocationPermission permission = await checkLocationPermission();
    if (permission == LocationPermission.denied) {
      permission = await requestLocationPermission();
      if (permission == LocationPermission.denied) {
        throw LocationPermissionDeniedException('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationPermissionDeniedForeverException(
        'Location permissions are permanently denied. Please enable them in app settings.'
      );
    }

    // Get current position
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 10),
    );
  }

  // Get last known position
  Future<Position?> getLastKnownPosition() async {
    return await Geolocator.getLastKnownPosition();
  }

  // Calculate distance between two points
  double calculateDistance({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  // Get address from coordinates
  Future<String> getAddressFromCoordinates({
    required double latitude,
    required double longitude,
  }) async {
    try {
      // This would typically use a geocoding service
      // For now, return coordinates as string
      return '$latitude, $longitude';
    } catch (e) {
      return 'Location: $latitude, $longitude';
    }
  }

  // Watch position changes
  Stream<Position> watchPosition() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // meters
      ),
    );
  }

  // Check if location is within a specific radius
  bool isWithinRadius({
    required double centerLatitude,
    required double centerLongitude,
    required double targetLatitude,
    required double targetLongitude,
    required double radiusInMeters,
  }) {
    final distance = calculateDistance(
      startLatitude: centerLatitude,
      startLongitude: centerLongitude,
      endLatitude: targetLatitude,
      endLongitude: targetLongitude,
    );
    return distance <= radiusInMeters;
  }

  // Get location accuracy description
  String getAccuracyDescription(double accuracy) {
    if (accuracy <= 5) {
      return 'Excellent';
    } else if (accuracy <= 10) {
      return 'Good';
    } else if (accuracy <= 20) {
      return 'Fair';
    } else {
      return 'Poor';
    }
  }

  // Format coordinates for display
  String formatCoordinates(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }

  // Check if coordinates are valid
  bool isValidCoordinates(double latitude, double longitude) {
    return latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180;
  }

  // Get approximate city/area from coordinates (simplified)
  Future<String> getApproximateLocation({
    required double latitude,
    required double longitude,
  }) async {
    // This is a simplified version
    // In a real app, you'd use a geocoding service like Google Geocoding API
    
    if (latitude >= 40.7 && latitude <= 40.8 && longitude >= -74.0 && longitude <= -73.9) {
      return 'New York City, NY';
    } else if (latitude >= 37.7 && latitude <= 37.8 && longitude >= -122.5 && longitude <= -122.4) {
      return 'San Francisco, CA';
    } else if (latitude >= 34.0 && latitude <= 34.1 && longitude >= -118.3 && longitude <= -118.2) {
      return 'Los Angeles, CA';
    } else {
      return 'Unknown Location';
    }
  }

  // Request location permission with explanation
  Future<bool> requestLocationPermissionWithExplanation() async {
    // Check current permission status
    var status = await Permission.location.status;
    
    if (status.isGranted) {
      return true;
    }
    
    if (status.isDenied) {
      // Request permission
      status = await Permission.location.request();
      return status.isGranted;
    }
    
    if (status.isPermanentlyDenied) {
      // Open app settings
      await openAppSettings();
      return false;
    }
    
    return false;
  }

  // Get location settings for different use cases
  LocationSettings getLocationSettings({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10,
  }) {
    return LocationSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilter,
    );
  }
}

// Custom exceptions
class LocationServiceDisabledException implements Exception {
  final String message;
  LocationServiceDisabledException(this.message);
  
  @override
  String toString() => 'LocationServiceDisabledException: $message';
}

class LocationPermissionDeniedException implements Exception {
  final String message;
  LocationPermissionDeniedException(this.message);
  
  @override
  String toString() => 'LocationPermissionDeniedException: $message';
}

class LocationPermissionDeniedForeverException implements Exception {
  final String message;
  LocationPermissionDeniedForeverException(this.message);
  
  @override
  String toString() => 'LocationPermissionDeniedForeverException: $message';
}
