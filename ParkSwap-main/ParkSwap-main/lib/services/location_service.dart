import 'package:location/location.dart';

class LocationService {
  final Location _location = Location();

  Future<String> getUserLocation() async {
    final hasPermission = await _location.hasPermission();
    if (hasPermission == PermissionStatus.denied) {
      await _location.requestPermission();
    }

    final loc = await _location.getLocation();
    return 'Latitud: ${loc.latitude}, Longitud: ${loc.longitude}';
  }
}
