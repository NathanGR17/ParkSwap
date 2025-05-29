import '../pages/chat_page.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:parkswap/models/reservation_model.dart';


class PoiMarker extends Marker {
  final String title;
  final String description;
  final String imageUrl;
  final Color markerColor;
  final IconData iconData;
  final int plazasLibres; // Nuevo campo para plazas libres

  PoiMarker({
    required LatLng position,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.markerColor = Colors.blue,
    this.iconData = Icons.place,
    required this.plazasLibres, // Asegúrate de incluir este parámetro
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
  final Color markerColor; // Nuevo parámetro para el color

  ParkingMarker({
    required LatLng position,
    required this.markedTime,
    this.markerColor = Colors.red, // Color por defecto
  }) : super(
    point: position,
    width: 40, // Aumenté el tamaño para mejor visualización
    height: 40,
    child: Icon(
      Icons.directions_car, // Cambié el ícono a uno de parking
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

class _MapScreenState extends State<MapScreen> {
  final mapController = MapController();
  final popupController = PopupController();
  final List<PoiMarker> poiMarkers = [];
  final PopupController poiPopupController = PopupController();
  final List<ParkingMarker> markers = [];


  void _initializePoiMarkers() {
    final barcelonaPois = [
      {
        'position': LatLng(41.397744, 2.197818), //
        'title': 'Carrer de Llull',
        'description': '20 places en total: 2 Lliures',
        'imageUrl': 'https://example.com/sagrada.jpg',
        'color': Colors.green,
        'icon': Icons.circle,
        'plazasLibres': 2,
      },
      {
        'position': LatLng(41.397711, 2.198890), //
        'title': 'Carrer de la Ciutat de Granada',
        'description': '30 places en total: 4 Lliures',
        'imageUrl': 'https://example.com/sagrada.jpg',
        'color': Colors.green,
        'icon': Icons.circle,
        'plazasLibres': 4,
      },
      {
        'position': LatLng(41.396884, 2.198882), //
        'title': 'Carrer de Ramón Turró',
        'description': '15 places en total: 0 Lliures',
        'imageUrl': 'https://example.com/sagrada.jpg',
        'color': Colors.red,
        'icon': Icons.circle,
        'plazasLibres': 0,
      },
      {
        'position': LatLng(41.396913, 2.197731), //
        'title': 'Carrer de Badajoz',
        'description': '23 places en total: 3 Lliures',
        'imageUrl': 'https://example.com/sagrada.jpg',
        'color': Colors.green,
        'icon': Icons.circle,
        'plazasLibres': 3,
      },
      {
        'position': LatLng(41.398602, 2.196627), //
        'title': 'Carrer de Pujades',
        'description': '18 places en total: 0 Lliures',
        'imageUrl': 'https://example.com/sagrada.jpg',
        'color': Colors.red,
        'icon': Icons.circle,
        'plazasLibres': 0,
      },
      {
        'position': LatLng(41.396023, 2.198906), //
        'title': 'Carrer de Badajoz',
        'description': '21 places en total: 0 Lliures',
        'imageUrl': 'https://example.com/sagrada.jpg',
        'color': Colors.red,
        'icon': Icons.circle,
        'plazasLibres': 0,
      },
      {
        'position': LatLng(41.396829, 2.200082), //
        'title': 'Carrer de la Ciutat de Granada',
        'description': '18 places en total: 0 Lliures',
        'imageUrl': 'https://example.com/sagrada.jpg',
        'color': Colors.red,
        'icon': Icons.circle,
        'plazasLibres': 0,
      },
      {
        'position': LatLng(41.396068, 2.200092), //
        'title': 'Carrer del Doctor Trueta',
        'description': '21 places en total: 1 Lliure',
        'imageUrl': 'https://example.com/sagrada.jpg',
        'color': Colors.green,
        'icon': Icons.circle,
        'plazasLibres': 1,
      },
      {
        'position': LatLng(41.398558, 2.197783), //
        'title': 'Carrer de la Ciutat de Granada',
        'description': '18 places en total: 0 Lliures',
        'imageUrl': 'https://example.com/sagrada.jpg',
        'color': Colors.red,
        'icon': Icons.circle,
        'plazasLibres': 0,
      },
      {
        'position': LatLng(41.397778, 2.196579), //
        'title': 'Carrer de Badajoz',
        'description': '21 places en total: 1 Lliure',
        'imageUrl': 'https://example.com/sagrada.jpg',
        'color': Colors.green,
        'icon': Icons.circle,
        'plazasLibres': 1,
      },
      {
        'position': LatLng(41.397757, 2.195503), //
        'title': 'Carrer de Pujades',
        'description': '18 places en total: 0 Lliures',
        'imageUrl': 'https://example.com/sagrada.jpg',
        'color': Colors.red,
        'icon': Icons.circle,
        'plazasLibres': 0,
      },
      {
        'position': LatLng(41.396933, 2.196709), //
        'title': 'Carrer de Llull',
        'description': '21 places en total: 1 Lliure',
        'imageUrl': 'https://example.com/sagrada.jpg',
        'color': Colors.green,
        'icon': Icons.circle,
        'plazasLibres': 1,
      },
      {
        'position': LatLng(41.396039, 2.197775), //
        'title': 'Carrer de Ramon Turró',
        'description': '18 places en total: 0 Lliures',
        'imageUrl': 'https://example.com/sagrada.jpg',
        'color': Colors.red,
        'icon': Icons.circle,
        'plazasLibres': 0,
      },
      {
        'position': LatLng(41.395203, 2.198927), //
        'title': 'Carrer del Doctor Trueta',
        'description': '21 places en total: 1 Lliure',
        'imageUrl': 'https://example.com/sagrada.jpg',
        'color': Colors.green,
        'icon': Icons.circle,
        'plazasLibres': 1,
      },

      {
        'position': LatLng(41.396918, 2.195469), //
        'title': "Carrer d'Àvila",
        'description': '21 places en total: 1 Lliure',
        'imageUrl': 'https://example.com/sagrada.jpg',
        'color': Colors.green,
        'icon': Icons.circle,
        'plazasLibres': 1,
      },
      {
        'position': LatLng(41.396020, 2.196645), //
        'title': "Carrer d'Àvila",
        'description': '18 places en total: 0 Lliures',
        'imageUrl': 'https://example.com/sagrada.jpg',
        'color': Colors.red,
        'icon': Icons.circle,
        'plazasLibres': 0,
      },
      {
        'position': LatLng(41.395165, 2.197750), //
        'title': "Carrer d'Àvila",
        'description': '21 places en total: 1 Lliure',
        'imageUrl': 'https://example.com/sagrada.jpg',
        'color': Colors.green,
        'icon': Icons.circle,
        'plazasLibres': 1,
      },
    ];

    setState(() {
      for (var poi in barcelonaPois) {
        poiMarkers.add(PoiMarker(
          position: poi['position'] as LatLng,
          title: poi['title'] as String,
          description: poi['description'] as String,
          imageUrl: poi['imageUrl'] as String,
          markerColor: poi['color'] as Color,
          iconData: poi['icon'] as IconData,
          plazasLibres: poi['plazasLibres'] as int, // Añade este parámetro
        ));
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
    _initializePoiMarkers();
  }

  Future<void> _checkLocationPermission() async {
    final status = await Permission.location.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permiso de ubicación denegado')),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      final currentLocation = LatLng(position.latitude, position.longitude);
      mapController.move(currentLocation, 17);

      final shouldAddMarker = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Añadir marcador'),
          content: const Text('¿Quieres marcar tu posición actual?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Añadir'),
            ),
          ],
        ),
      );

      if (shouldAddMarker == true) {
        _addMarkerAt(currentLocation);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error obteniendo ubicación: $e')),
      );
    }
  }

  Future<LatLng?> _searchAddress(String address) async {
    final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$address&format=json&limit=1');
    final response = await http.get(url, headers: {
      'User-Agent': 'Flutter Parking App',
    });

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

  void _addMarkerAt(LatLng position) {
    setState(() {
      markers.add(ParkingMarker(
        position: position,
        markedTime: DateTime.now(),
        markerColor: Colors.red, // Puedes usar cualquier color
      ));
    });
  }
  // Puedes añadir esta función para manejar el tiempo de reserva
  void _iniciarTemporizadorReserva(PoiMarker marker) {
    // Muestra un diálogo con cuenta regresiva
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reserva activa'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Tu plaza está reservada por:'),
              const SizedBox(height: 10),
              TweenAnimationBuilder(
                duration: const Duration(minutes: 10),
                tween: Tween(begin: 10.0, end: 0.0),
                builder: (context, value, _) {
                  final minutes = value.toInt();
                  return Text(
                    '$minutes minutos restantes',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Cierra el AlertDialog
                // Oculta todos los popups del mapa
                popupController.hideAllPopups();
                poiPopupController.hideAllPopups();
              },
              child: const Text('Cerrar'),
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
            Text('Ubicación: ${marker.title}'),
            const SizedBox(height: 10),
            const Text('Tarifa: 5€/hora'),
            const Text('Tienes 10 minutos para llegar'),
            const SizedBox(height: 10),
            const Text('¿Confirmas la reserva?'),
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
      final provider = Provider.of<ReservationProvider>(context, listen: false);
      provider.addReservation(marker.title);

      // Actualizar marcador
      final updatedMarker = PoiMarker(
        position: marker.point,
        title: marker.title,
        description: '${marker.plazasLibres - 1} places lliures',
        imageUrl: marker.imageUrl,
        markerColor: marker.plazasLibres - 1 > 0 ? Colors.green : Colors.red,
        iconData: Icons.local_parking,
        plazasLibres: marker.plazasLibres - 1,
      );

      setState(() {
        poiMarkers.remove(marker);
        poiMarkers.add(updatedMarker);
      });

      _iniciarTemporizadorReserva(updatedMarker);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('INICI'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('Menú', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: Icon(Icons.chat),
              title: Text('Assistent de ParkSwap'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChatPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Buscar adreça...',
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
                    const SnackBar(content: Text('Adreça no trobada')),
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
                initialCenter: const LatLng(41.403957, 2.193989), // Añade const
                initialZoom: 15,
                onTap: (_, latlng) {
                  // Añadir nuevo marcador de parking al tocar
                  _addMarkerAt(latlng);
                  // Cerrar todos los popups
                  popupController.hideAllPopups();
                  poiPopupController.hideAllPopups();
                },
                onLongPress: (_, __) {
                  // Cerrar todos los popups al hacer long press
                  popupController.hideAllPopups();
                  poiPopupController.hideAllPopups();
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                ),
                // Capa para tus marcadores de parking originales
                PopupMarkerLayerWidget(
                  options: PopupMarkerLayerOptions(
                    markers: markers,
                    popupController: popupController,
                    markerTapBehavior: MarkerTapBehavior.togglePopup(),
                    popupDisplayOptions: PopupDisplayOptions(
                      builder: (context, marker) {
                        if (marker is ParkingMarker) {
                          final duration = DateTime.now().difference(marker.markedTime);
                          final hours = duration.inHours;
                          final minutes = duration.inMinutes.remainder(60);

                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Marcat fa:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    hours > 0
                                        ? '$hours h $minutes min'
                                        : '$minutes min',
                                    style: TextStyle(fontSize: 14),
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

// Capa adicional para los nuevos marcadores POI
                PopupMarkerLayerWidget(
                  options: PopupMarkerLayerOptions(
                    markers: poiMarkers,
                    popupController: poiPopupController,
                    markerTapBehavior: MarkerTapBehavior.togglePopup(),
                    popupDisplayOptions: PopupDisplayOptions(
                      builder: (context, marker) {
                        if (marker is PoiMarker) {
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    marker.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(marker.description),
                                  const SizedBox(height: 12),
                                  // Mostrar botón solo si hay plazas libres
                                  if (marker.plazasLibres > 0)
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green, // Color verde
                                        minimumSize: const Size(double.infinity, 40),
                                      ),
                                      onPressed: () => _reservarPlaza(context, marker),
                                      child: const Text('Reservar Plaça',
                                          style: TextStyle(color: Colors.white)),
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}