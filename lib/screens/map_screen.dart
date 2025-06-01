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
import 'package:parkswap/auth/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';


class PoiMarker extends Marker {
  final String title;
  final String description;
  final String imageUrl;
  final Color markerColor;
  final IconData iconData;
  final int plazasLibres;
  final String carrerId;

  PoiMarker({
    required LatLng position,
    required this.title,
    required this.description,
    required this.imageUrl,
    this.markerColor = Colors.blue,
    this.iconData = Icons.place,
    required this.plazasLibres,
    required this.carrerId,
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

class _MapScreenState extends State<MapScreen> with WidgetsBindingObserver {
  final mapController = MapController();
  final popupController = PopupController();
  final List<PoiMarker> poiMarkers = [];
  final PopupController poiPopupController = PopupController();
  final List<ParkingMarker> markers = [];

  final TextEditingController _searchController = TextEditingController();
  bool _showRecentSearches = false;
  final List<String> _availableStreets = [
    'Carrer Roc Boronat, 138',
    'Av. Diagonal 88',
    'Carrer dels Almogàvers, 23'
  ]; // Mantenemos esta lista para la lógica de reservas
  List<String> _recentSearches = []; // Nueva lista para búsquedas recientes
  static const String _recentSearchesKey = 'recent_searches';
  static const String _parkingMarkerKey = 'parking_marker';
  static const String _parkingMarkerTimeKey = 'parking_marker_time';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLocationPermission();
    _fetchParkingDataFromSupabase();
    _loadRecentSearches();
    _loadParkingMarker(); // Añade esta línea

    _searchController.addListener(() {
      setState(() {
        _showRecentSearches = _searchController.text.isNotEmpty;
      });
    });
  }

// Nuevo método para cargar búsquedas recientes
  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    final searches = prefs.getStringList(_recentSearchesKey) ?? [];
    setState(() {
      _recentSearches = searches;
    });
  }
  Future<void> _saveRecentSearch(String search) async {
    if (search.isEmpty) return;

    setState(() {
      // Eliminar si ya existe para evitar duplicados
      _recentSearches.remove(search);
      // Añadir al principio de la lista
      _recentSearches.insert(0, search);
      // Limitar a 5 búsquedas
      if (_recentSearches.length > 5) {
        _recentSearches.removeLast();
      }
    });

    // Guardar en SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentSearchesKey, _recentSearches);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  void _searchStreet(String street) async {
    setState(() {
      _showRecentSearches = false;
    });

    final coordinates = await _searchAddress(street);

    if (coordinates != null) {
      mapController.move(coordinates, 15);
      // Guardar la búsqueda exitosa
      await _saveRecentSearch(street);
    }

    if (_availableStreets.contains(street)) {
      _showStreetInfo(street);
    } else if (coordinates == null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text("No s'ha trobat aquesta adreça. Torna a intentar més tard."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tornar'),
            ),
          ],
        ),
      );
    }
  }

  void _showStreetInfo(String street) {
    final reservationProvider = Provider.of<ReservationProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Has d\'iniciar sessió per reservar.')),
      );
      return;
    }

    // Simulación de IDs (ajusta según tu lógica real)
    final vehicleId = "aa2078a8-bad9-4bbd-af69-ed306bac2f00";
    final carrerId = _availableStreets.indexOf(street) + 1;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(street, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text('Tarifa: 5€/hora'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () {
                    reservationProvider.addReservation(
                      userId: user.id,
                      vehicleId: vehicleId,
                      carrerId: carrerId.toString(),
                      vehicleMatricula: user.licensePlate,
                      carrerNom: street,
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Reserva confirmada. Tens 10 minuts per arribar.')),
                    );
                    _iniciarTemporizadorReserva(null); // Inicia el temporizador sin un marcador específico
                  },
                  child: const Text('Ocupar', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchParkingDataFromSupabase();
    }
  }

  Future<void> _checkLocationPermission() async {
    final status = await Permission.location.request();
    if (!status.isGranted && mounted) {
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

      if (!mounted) return;
      setState(() {
        poiMarkers.clear();
        for (var item in data) {
          poiMarkers.add(PoiMarker(
            position: LatLng(
              item['latitud'] ?? 41.40338,
              item['longitud'] ?? 2.17403,
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
            carrerId: item['id'].toString(),
          ));
        }
      });
    } catch (e) {
      if (!mounted) return;
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

      if (shouldAdd == true && mounted) _addMarkerAt(currentLocation);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error amb la ubicació: $e')),
      );
    }
  }

  void _addMarkerAt(LatLng position) async {
    final now = DateTime.now();
    final newMarker = ParkingMarker(
      position: position,
      markedTime: now,
      markerColor: Colors.red,
    );

    setState(() {
      // Elimina marcadores anteriores para mantener solo uno
      markers.clear();
      markers.add(newMarker);
    });

    // Guardar el marcador en SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('${_parkingMarkerKey}_lat', position.latitude);
    await prefs.setDouble('${_parkingMarkerKey}_lng', position.longitude);
    await prefs.setString(_parkingMarkerTimeKey, now.toIso8601String());

    // Espera a que se actualice el estado y muestra el popup
    Future.delayed(const Duration(milliseconds: 100), () {
      popupController.showPopupsOnlyFor([newMarker]);
    });
  }

  Future<void> _loadParkingMarker() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('${_parkingMarkerKey}_lat');
    final lng = prefs.getDouble('${_parkingMarkerKey}_lng');
    final timeStr = prefs.getString(_parkingMarkerTimeKey);

    if (lat != null && lng != null && timeStr != null) {
      final position = LatLng(lat, lng);
      final markedTime = DateTime.parse(timeStr);

      setState(() {
        markers.add(ParkingMarker(
          position: position,
          markedTime: markedTime,
          markerColor: Colors.red,
        ));
      });
    }
  }
  Future<void> _removeMarker(ParkingMarker marker) async {
    setState(() {
      markers.remove(marker);
    });

    // Eliminar el marcador de SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_parkingMarkerKey}_lat');
    await prefs.remove('${_parkingMarkerKey}_lng');
    await prefs.remove(_parkingMarkerTimeKey);

    popupController.hideAllPopups();
  }

  void _iniciarTemporizadorReserva(PoiMarker? marker) {
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
                  final minutes = value.floor();
                  final seconds = ((value - minutes) * 60).floor();
                  return Text(
                    '$minutes:${seconds.toString().padLeft(2, '0')} minuts',
                    style: const TextStyle(
                        fontSize: 32, fontWeight: FontWeight.bold),
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
      if (!mounted) return;
      final reservationProvider = Provider.of<ReservationProvider>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final user = authProvider.user;

      if (user == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Has d\'iniciar sessió per reservar.')),
        );
        return;
      }

      final vehicleId = "aa2078a8-bad9-4bbd-af69-ed306bac2f00";
      final carrerId = marker.carrerId;

      try {
        await reservationProvider.addReservation(
          userId: user.id,
          vehicleId: vehicleId,
          carrerId: carrerId.toString(),
          vehicleMatricula: user.licensePlate,
          carrerNom: marker.title,
        );
        if (!mounted) return;
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;
        await _fetchParkingDataFromSupabase();
        if (!mounted) return;
        _iniciarTemporizadorReserva(marker);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al fer la reserva: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appBar: AppBar(
        //title: const Text('INICI'),
      //),
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Image.asset('assets/images/logo_parkswap_IA_png.png'),
            onPressed: () {
              Scaffold.of(context).openDrawer(); // Abre el Drawer
            },
          ),
        ),
        title: const Text('INICI', style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Color(0xFF538878)),
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
            padding: const EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Cerca una adreça o zona',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => _searchController.clear(),
                          ),
                        ),
                        onSubmitted: (value) => _searchStreet(value),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.my_location),
                      onPressed: _getCurrentLocation,
                    ),
                  ],
                ),
                if (_showRecentSearches)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 1,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            'Recents',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        _recentSearches.isEmpty
                            ? const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('No hi ha cerques recents'),
                        )
                            : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _recentSearches.length,
                          itemBuilder: (context, index) {
                            return ListTile(
                              leading: const Icon(Icons.history),
                              title: Text(_recentSearches[index]),
                              onTap: () {
                                _searchController.text = _recentSearches[index];
                                setState(() {
                                  _showRecentSearches = false;
                                });
                                _searchStreet(_recentSearches[index]);
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: LatLng(41.39726788435298, 2.1971287495157217),
                initialZoom: 15,
                onTap: (tapPosition, point) {
                  // Primero oculta los popups existentes
                  popupController.hideAllPopups();
                  poiPopupController.hideAllPopups();

                  // Luego pregunta si desea añadir un marcador en este punto
                  showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Afegir marcador'),
                      content: const Text('Vols marcar aquesta ubicació com el teu aparcament?'),
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
                  ).then((shouldAdd) {
                    if (shouldAdd == true) {
                      _addMarkerAt(point);
                    }
                  });
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
                      builder: (BuildContext context, Marker marker) {
                        if (marker is PoiMarker) {
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(marker.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text(marker.description),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () => _reservarPlaza(context, marker),
                                    child: const Text('Reservar'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ),
                PopupMarkerLayer(
                  options: PopupMarkerLayerOptions(
                    markers: markers,
                    popupController: popupController,
                    popupDisplayOptions: PopupDisplayOptions(
                      builder: (BuildContext context, Marker marker) {
                        if (marker is ParkingMarker) {
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('Has marcat aquesta ubicació'),
                                  Text('Hora: ${marker.markedTime.hour}:${marker.markedTime.minute.toString().padLeft(2, '0')}'),
                                  const SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () {
                                      _removeMarker(marker as ParkingMarker);
                                    },
                                    child: const Text('Eliminar marcador'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
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