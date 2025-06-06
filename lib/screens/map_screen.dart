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
import 'package:parkswap/pages/chat_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';


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

// Primero, añade esta clase para el marcador de tu ubicación
class UserLocationMarker extends Marker {
  UserLocationMarker({
    required LatLng point,
  }) : super(
    point: point,
    width: 30,
    height: 30,
    child: Container(
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.5),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: const Icon(
        Icons.my_location,
        color: Colors.white,
        size: 18,
      ),
    ),
  );
}

class _MapScreenState extends State<MapScreen> with WidgetsBindingObserver {
  final mapController = MapController();
  final popupController = PopupController();
  final List<PoiMarker> poiMarkers = [];
  final PopupController poiPopupController = PopupController();
  final List<ParkingMarker> markers = [];
  bool _tapProcessed = false;
  UserLocationMarker? userLocationMarker;
  Timer? _locationTimer;

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
    _checkLocationPermission().then((_) {
      _updateUserLocation(); // Ubicación inicial

      // Actualizar ubicación cada 15 segundos
      _locationTimer = Timer.periodic(const Duration(seconds: 15), (_) {
        _updateUserLocation(showSnackbar: false);
      });
    });

    _fetchParkingDataFromSupabase();
    _loadRecentSearches();
    _loadParkingMarker();

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
    _locationTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }
  Future<void> _updateUserLocation({bool showSnackbar = true}) async {
    try {
      final position = await Geolocator.getCurrentPosition();
      final userLocation = LatLng(position.latitude, position.longitude);

      setState(() {
        userLocationMarker = UserLocationMarker(point: userLocation);
      });
    } catch (e) {
      if (showSnackbar && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error amb la ubicació: $e')),
        );
      }
      print('Error al obtener ubicación: $e');
    }
  }

// Actualiza el método existente para centrar el mapa en tu ubicación
  Future<void> _getCurrentLocation() async {
    try {
      await _updateUserLocation();

      if (userLocationMarker != null && mounted) {
        mapController.move(userLocationMarker!.point, 17);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error amb la ubicació: $e')),
        );
      }
    }
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

    // Valores por defecto para la reserva
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    int durationHours = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Para que el modal sea más alto
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(street, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  const Text('Tarifa: 5€/hora'),
                  const SizedBox(height: 20),

                  // Selector de fecha
                  ListTile(
                    leading: const Icon(Icons.calendar_today),
                    title: const Text('Data'),
                    subtitle: Text('${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 7)),
                      );
                      if (picked != null) {
                        setState(() {
                          selectedDate = picked;
                        });
                      }
                    },
                  ),

                  // Selector de hora
                  ListTile(
                    leading: const Icon(Icons.access_time),
                    title: const Text('Hora'),
                    subtitle: Text('${selectedTime.hour}:${selectedTime.minute.toString().padLeft(2, '0')}'),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (picked != null) {
                        setState(() {
                          selectedTime = picked;
                        });
                      }
                    },
                  ),

                  // Selector de duración
                  ListTile(
                    leading: const Icon(Icons.timer),
                    title: const Text('Durada'),
                    subtitle: Text('$durationHours hores'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: durationHours > 1
                              ? () => setState(() => durationHours--)
                              : null,
                        ),
                        Text('$durationHours'),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: durationHours < 6
                              ? () => setState(() => durationHours++)
                              : null,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  Row(
                    children: [
                      // Botón para cancelar
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Botón para reservar
                      Expanded(
                        child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                        onPressed: () async {

                        final userVehicle = await _getUserVehicle(user.id);
                        if (userVehicle == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                        content: Text('Necessites afegir un vehicle a la teva conta abans de reservar'),
                        backgroundColor: Colors.red,
                        ),
                        );
                        Navigator.pop(context);
                        return;
                        }
                        // Verificar disponibilidad
                        final bool available = await _checkAvailability(
                        carrerId.toString(),
                        selectedDate,
                        selectedTime,
                        durationHours
                        );

                        if (!available) {
                        ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                        content: Text('No hi ha places disponibles en aquesta franja horària.'),
                        backgroundColor: Colors.red,
                        ),
                        );
                        return;
                        }

                        // Crear DateTime para la hora de inicio
                        final startTime = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        selectedTime.hour,
                        selectedTime.minute,
                        );

                        // Realizar la reserva
                        reservationProvider.addReservation(
                        userId: user.id,
                        vehicleId: vehicleId,
                        carrerId: carrerId.toString(),
                        vehicleMatricula: user.licensePlate ?? '-',
                        carrerNom: street,
                        startTime: startTime,
                        durationHours: durationHours,
                        );

                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Reserva confirmada.')),
                        );
                        },
                        child: const Text('Reservar', style: TextStyle(color: Colors.white)),
                      ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

// Método para verificar disponibilidad
  Future<bool> _checkAvailability(
      String carrerId,
      DateTime selectedDate,
      TimeOfDay selectedTime,
      int durationHours
      ) async {
    try {
      final supabase = Supabase.instance.client;

      // Crear la fecha de inicio y fin para la reserva solicitada
      final startDateTime = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        selectedTime.hour,
        selectedTime.minute,
      ).toUtc();

      final endDateTime = startDateTime.add(Duration(hours: durationHours));

      // Consultar todas las reservas para esta calle que puedan solaparse
      final response = await supabase
          .from('reserves')
          .select('*, carrers!inner(*)')
          .eq('id_carrer', carrerId)
          .or('hora_inici.lte.${endDateTime.toIso8601String()},hora_final.gte.${startDateTime.toIso8601String()}');

      if (response == null) return true;

      // Obtener información sobre la cantidad de plazas en esta calle
      final streetInfoResponse = await supabase
          .from('carrers')
          .select('places_disponibles')
          .eq('id', carrerId)
          .single();

      final totalPlazas = streetInfoResponse['places_disponibles'] ?? 1;

      // Contar cuántas reservas se solapan con nuestra franja horaria
      final reservasExistentes = (response as List).length;

      // Si hay menos reservas que plazas, hay disponibilidad
      return reservasExistentes < totalPlazas;

    } catch (e) {
      print('Error al verificar disponibilidad: $e');
      return false;
    }
  }

// Método para obtener el vehículo del usuario
  Future<Map<String, dynamic>?> _getUserVehicle(String userId) async {
    try {
      final result = await Supabase.instance.client
          .from('vehicles')
          .select()
          .eq('id_usuari', userId)
          .maybeSingle();

      return result;
    } catch (e) {
      print('Error al obtener vehículo: $e');
      return null;
    }
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

  void _iniciarTemporizadorReserva(PoiMarker? marker, DateTime endTime) {
    // Timer para actualizar el contador
    Timer? timer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Iniciar timer al mostrar el diálogo
            timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
              setState(() {}); // Forzar reconstrucción para actualizar tiempo
            });

            // Calcular tiempo restante actual
            final now = DateTime.now();
            final remaining = endTime.difference(now);
            final hours = remaining.inHours;
            final minutes = remaining.inMinutes.remainder(60);
            final seconds = remaining.inSeconds.remainder(60);

            // Formatear tiempo restante
            final remainingText = '${hours}h ${minutes}m ${seconds}s';

            return AlertDialog(
              title: const Text('Temps restant de reserva'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Carrer: ${marker?.title ?? ""}'),
                  const SizedBox(height: 10),
                  Text(
                    remainingText,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    timer?.cancel(); // Cancelar timer al cerrar
                    Navigator.pop(context);
                  },
                  child: const Text('Tancar'),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      // Asegurar cancelación del timer si se cierra el diálogo
      timer?.cancel();
    });
  }

  void _reservarPlaza(BuildContext context, PoiMarker marker) async {
    if (marker.plazasLibres <= 0) return;

    // Variable para almacenar el mensaje de distancia/tiempo
    String distanceMessage = 'Tens 10 minuts per arribar';

    try {
      // Comprobar permisos de ubicación
      LocationPermission permission = await Geolocator.checkPermission();
      bool hasPermission = permission != LocationPermission.denied &&
          permission != LocationPermission.deniedForever;

      if (hasPermission) {
        // Obtener ubicación actual
        final position = await Geolocator.getCurrentPosition();
        final currentLocation = LatLng(position.latitude, position.longitude);

        // Calcular distancia en metros
        final distance = Geolocator.distanceBetween(
            currentLocation.latitude,
            currentLocation.longitude,
            marker.point.latitude,
            marker.point.longitude
        );

        // Convertir a kilómetros y calcular tiempo estimado (velocidad media de 30 km/h)
        final distanceInKm = distance / 1000;
        final estimatedTimeInMinutes = (distanceInKm / 30) * 60;

        // Formatear mensaje
        distanceMessage = 'Distància: ${distanceInKm.toStringAsFixed(1)} km\n'
            'Temps estimat d\'arribada: ${estimatedTimeInMinutes.round()} minuts';
      } else {
        distanceMessage = 'Activa la ubicació per saber el temps d\'arribada';
      }
    } catch (e) {
      print('Error al obtener la ubicación: $e');
      distanceMessage = 'Activa la ubicació per saber el temps d\'arribada';
    }

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
            Text(distanceMessage),
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

      // Obtener el vehículo del usuario
      final userVehicle = await _getUserVehicle(user.id);
      if (userVehicle == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Necessites afegir un vehicle al teu perfil abans de reservar'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final vehicleId = userVehicle['id'];
      final carrerId = marker.carrerId;

      try {
        final DateTime startTime = DateTime.now();
        final DateTime endTime = startTime.add(const Duration(hours: 1));
        await reservationProvider.addReservation(
          userId: user.id,
          vehicleId: vehicleId,
          carrerId: carrerId.toString(),
          vehicleMatricula: userVehicle['matricula'] ?? '-',
          carrerNom: marker.title,
        );
        if (!mounted) return;
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;
        await _fetchParkingDataFromSupabase();
        if (!mounted) return;
        _iniciarTemporizadorReserva(marker, endTime);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al reservar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            padding: const EdgeInsets.only(top: 50, left: 16, right: 16, bottom: 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Cercar carrer...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onSubmitted: (value) {
                          _searchStreet(value);
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () {
                        if (_searchController.text.isNotEmpty) {
                          _searchStreet(_searchController.text);
                        }
                      },
                      tooltip: 'Cercar',
                    ),
                  ],
                ),
                if (_showRecentSearches)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: _recentSearches.map((search) {
                        return ListTile(
                          leading: const Icon(Icons.history),
                          title: Text(search),
                          onTap: () {
                            _searchController.text = search;
                            _searchStreet(search);
                          },
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: mapController,
                  options: MapOptions(
                    initialCenter: LatLng(41.39726788435298, 2.1971287495157217),
                    initialZoom: 15,
                    onTap: (tapPosition, point) {
                      _tapProcessed = false;
                      // Siempre cierra los popups (si los hay)
                      popupController.hideAllPopups();
                      poiPopupController.hideAllPopups();

                      // Muestra el diálogo para añadir marcador
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
                    // Capa para la ubicación del usuario
                    MarkerLayer(
                      markers: userLocationMarker != null ? [userLocationMarker!] : [],
                    ),
                    // Resto de capas existentes
                    PopupMarkerLayer(
                      options: PopupMarkerLayerOptions(
                        markers: poiMarkers,
                        popupController: poiPopupController,
                        popupDisplayOptions: PopupDisplayOptions(
                          builder: (BuildContext context, Marker marker) {
                            if (marker is PoiMarker) {
                              return SizedBox(
                                width: 200,
                                child: Card(
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
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          marker.description,
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: [
                                            ElevatedButton(
                                              onPressed: () {
                                                _reservarPlaza(context, marker);
                                              },
                                              style: ElevatedButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              ),
                                              child: const Text(
                                                'Reservar',
                                                style: TextStyle(fontSize: 12),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                poiPopupController.hidePopupsOnlyFor([marker]);
                                              },
                                              style: TextButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              ),
                                              child: const Text(
                                                'Cancelar',
                                                style: TextStyle(fontSize: 12),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
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
                // Botón para centrar en la ubicación actual
                Positioned(
                  right: 16,
                  bottom: 50,
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor: Colors.white,
                    onPressed: _getCurrentLocation,
                    child: const Icon(Icons.my_location, color: Colors.blue),
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