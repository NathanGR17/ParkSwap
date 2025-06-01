import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Reservation {
  final String id;
  final String idUsuari;
  final DateTime horaInici;
  final DateTime horaFinal;
  final String idVehicle;
  final String idCarrer;
  final String vehicleMatricula;
  final String carrerNom;

  // Camps locals opcionals
  final double pricePerHour;
  int durationMinutes;

  Reservation({
    required this.id,
    required this.idUsuari,
    required this.horaInici,
    required this.horaFinal,
    required this.idVehicle,
    required this.idCarrer,
    required this.vehicleMatricula,
    required this.carrerNom,
    this.pricePerHour = 5.0,
    this.durationMinutes = 60,
  });

  // Constructor des de Supabase
  factory Reservation.fromMap(Map<String, dynamic> map) {
    return Reservation(
      id: map['id'].toString(),
      idUsuari: map['id_usuari'],
      horaInici: DateTime.parse(map['hora_inici']),
      horaFinal: DateTime.parse(map['hora_final']),
      idVehicle: map['id_vehicle'],
      idCarrer: map['id_carrer'],
      vehicleMatricula: map['vehicle_matricula'] ?? '',
      carrerNom: map['carrer_nom'] ?? '',
      // Si vols, pots calcular pricePerHour i durationMinutes a partir de la resposta
    );
  }

  String get endTime => horaFinal.toString().substring(11, 16);
  String get totalCost {
    final minuts = horaFinal.difference(horaInici).inMinutes;
    return (pricePerHour * minuts / 60).toStringAsFixed(2);
  }
}

class ReservationProvider with ChangeNotifier {
  List<Reservation> _history = [];
  Reservation? _currentReservation;
  final Map<String, int> _parkingSpots = {};

  List<Reservation> get history => _history;
  Reservation? get currentReservation => _currentReservation;

  // Carrega historial des de Supabase
  Future<void> fetchUserReservations(String userId) async {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('reserves_with_vehicle')
        .select()
        .eq('id_usuari', userId)
        .order('hora_inici', ascending: false);

    ///print('Resposta Supabase: $response');

    if (response != null && response is List) {
      _history = response
          .map((r) => Reservation.fromMap(r as Map<String, dynamic>))
          .toList();
      notifyListeners();
    }
  }

  Future<void> addReservation({
    required String userId,
    required String vehicleId,
    required String carrerId,
    required String vehicleMatricula,
    required String carrerNom,
    int durationMinutes = 60,
    double pricePerHour = 5.0,
  }) async {
    final supabase = Supabase.instance.client;
    final nowLocal = DateTime.now();
    final nowUtc = nowLocal.toUtc();
    //print('Hora local: $nowLocal');
    //print('Hora UTC: $nowUtc');
    final horaFinalUtc = nowUtc.add(Duration(minutes: durationMinutes));

    final response = await supabase.from('reserves').insert({
      'id_usuari': userId,
      'id_vehicle': vehicleId,
      'id_carrer': carrerId,
      'hora_inici': nowUtc.toIso8601String(),
      'hora_final': horaFinalUtc.toIso8601String(),
    }).select().single();

    //print('Respuesta de Supabase al guardar reserva: $response');

    _currentReservation = Reservation(
      id: response['id'],
      idUsuari: userId,
      horaInici: nowUtc,
      horaFinal: horaFinalUtc,
      idVehicle: vehicleId,
      idCarrer: carrerId,
      vehicleMatricula: vehicleMatricula,
      carrerNom: carrerNom,
      pricePerHour: pricePerHour,
      durationMinutes: durationMinutes,
    );
    notifyListeners();
  }

  void addToHistory() {
    if (_currentReservation != null) {
      _history.insert(0, _currentReservation!);
      _currentReservation = null;
      notifyListeners();
    }
  }

  void updateParkingSpots(String location, int spots) {
    _parkingSpots[location] = spots;
    notifyListeners();
  }

  int getAvailableSpots(String location) {
    return _parkingSpots[location] ??
        _history.where((r) => r.carrerNom == location).length;
  }

  void extendReservation(int minutes) {
    if (_currentReservation != null) {
      _currentReservation!.durationMinutes += minutes;
      notifyListeners();
    }
  }

  void cancelReservation() {
    if (_currentReservation != null) {
      addToHistory();
    }
  }
}