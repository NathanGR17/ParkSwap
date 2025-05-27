// Importacions
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:parkswap/models/reservation_model.dart';

// PoiMarker amb carrerId afegit
class PoiMarker extends Marker {
  final String title;
  final String description;
  final String imageUrl;
  final Color markerColor;
  final IconData iconData;
  final int plazasLibres;
  final String carrerId; // Afegit

  PoiMarker({
    required LatLng position,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.markerColor = Colors.blue,
    this.iconData = Icons.place,
    required this.plazasLibres,
    required this.carrerId, // Afegit
  }) : super(
    point: position,
    width: 20,
    height: 20,
    child: Icon(
      iconData,
      size: 20,
      color: markerColor,
    ),
  );
}

class ParkingMarker extends Marker {
  final DateTime markedTime;
  final Color markerColor;

  ParkingMarker({
    required LatLng position,
    required this.markedTime,
    this.markerColor = Colors.red,
  }) : super(
    point: position,
    width: 40,
    height: 40,
    child: Icon(
      Icons.directions_car,
      size: 20,
      color: markerColor,
    ),
  );
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with WidgetsBindingObserver{
  final mapController = MapController();
  final popupController = PopupController();
  final List<PoiMarker> poiMarkers = [];
  final PopupController poiPopupController = PopupController();
  final List<ParkingMarker> markers = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Observa el cicle de vida
    _checkLocationPermission();
    _fetchParkingDataFromSupabase();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // L'app torna a primer pla, refresca les dades!
      _fetchParkingDataFromSupabase();
    }
  }

  Future<void> _checkLocationPermission() async {
    final status = await Permission.location.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permís de localització denegat')),
      );
    }
  }

  Future<void> _fetchParkingDataFromSupabase() async {
    try {
      final response = await Supabase.instance.client
          .from('places_disponibles_per_carrer')
          .select();

      final data = response as List;

      setState(() {
        poiMarkers.clear();
        for (var item in data) {
          poiMarkers.add(PoiMarker(
            position: LatLng(
              double.parse(item['latitud'].toString()),
              double.parse(item['longitud'].toString()),
            ),
            title: item['nom'],
            description: '${item['places_disponibles']} places disponibles',
            imageUrl: item['image_url'] ?? 'https://example.com/sagrada.jpg',
            markerColor: (item['places_disponibles'] ?? 0) == 0
                ? Colors.red
                : (item['places_disponibles'] <= 5
                ? Colors.yellow
                : Colors.green),
            iconData: Icons.circle,
            plazasLibres: item['places_disponibles'],
            carrerId: item['id'], // Nou
          ));
        }
      });
    } catch (e) {
      debugPrint('Error carregant dades: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al carregar aparcaments')),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      final currentLocation = LatLng(position.latitude, position.longitude);
      mapController.move(currentLocation, 17);
      final shouldAdd = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Afegir marcador'),
          content: const Text('Vols marcar la teva ubicació actual?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Afegir'),
            ),
          ],
        ),
      );

      if (shouldAdd == true) _addMarkerAt(currentLocation);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error amb la ubicació: $e')),
      );
    }
  }

  void _addMarkerAt(LatLng position) {
    setState(() {
      markers.add(ParkingMarker(
        position: position,
        markedTime: DateTime.now(),
        markerColor: Colors.red,
      ));
    });
  }

  void _iniciarTemporizadorReserva(PoiMarker marker) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reserva activa'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('La teva plaça està reservada per:'),
              const SizedBox(height: 10),
              TweenAnimationBuilder(
                duration: const Duration(minutes: 10),
                tween: Tween(begin: 10.0, end: 0.0),
                builder: (context, value, _) {
                  final minutes = value.toInt();
                  return Text(
                    '$minutes minuts restants',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                popupController.hideAllPopups();
                poiPopupController.hideAllPopups();
              },
              child: const Text('Tancar'),
            ),
          ],
        );
      },
    );
  }

  void _reservarPlaza(BuildContext context, PoiMarker marker) async {
    if (marker.plazasLibres <= 0) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Reserva'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Ubicació: ${marker.title}'),
            const SizedBox(height: 10),
            const Text('Tarifa: 5€/hora'),
            const Text('Tens 10 minuts per arribar'),
            const SizedBox(height: 10),
            const Text('Confirmes la reserva?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final now = DateTime.now();
      final end = now.add(const Duration(hours: 2));
      try {
        final response = await Supabase.instance.client.from('reserves').insert({
          'id_usuari': 'a0fb52ec-6500-4655-9e4e-c31e0a4d2dc0',
          'id_vehicle': '849fea74-bf41-4b64-9057-40ce470de896',
          'hora_inici': now.toIso8601String(),
          'hora_final': end.toIso8601String(),
          'id_carrer': marker.carrerId,
        }).select();

        // Si arriba aquí, la reserva s'ha creat bé
        await Future.delayed(const Duration(milliseconds: 300)); // Opcional: petit delay per assegurar actualització
        await _fetchParkingDataFromSupabase();
        _iniciarTemporizadorReserva(marker);
      } catch (e) {
        // Això només s'executa si hi ha un error real a la inserció
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al fer la reserva: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar direcció...',
                suffixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) async {
                final coords = await _searchAddress(value);
                if (coords != null) {
                  mapController.move(coords, 17);
                  _addMarkerAt(coords);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Direcció no trobada')),
                  );
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.my_location),
              label: const Text('Marcar la meva ubicació actual'),
              onPressed: _getCurrentLocation,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: const LatLng(41.403957, 2.193989),
                initialZoom: 15,
                onTap: (_, latlng) {
                  _addMarkerAt(latlng);
                  popupController.hideAllPopups();
                  poiPopupController.hideAllPopups();
                },
                onLongPress: (_, __) {
                  popupController.hideAllPopups();
                  poiPopupController.hideAllPopups();
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                ),
                PopupMarkerLayer(
                  options: PopupMarkerLayerOptions(
                    markers: poiMarkers,
                    popupController: poiPopupController,
                    popupDisplayOptions: PopupDisplayOptions(
                      builder: (context, marker) {
                        if (marker is PoiMarker) {
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(marker.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  Text(marker.description),
                                  const SizedBox(height: 12),
                                  if (marker.plazasLibres > 0)
                                    ElevatedButton(
                                      onPressed: () => _reservarPlaza(context, marker),
                                      child: const Text('Reservar plaça'),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
                MarkerLayer(markers: markers),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<LatLng?> _searchAddress(String address) async {
    final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$address&format=json&limit=1');
    final response = await http.get(url, headers: {'User-Agent': 'Flutter Parking App'});
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data.isNotEmpty) {
        final lat = double.parse(data[0]['lat']);
        final lon = double.parse(data[0]['lon']);
        return LatLng(lat, lon);
      }
    }
    return null;
  }
}
