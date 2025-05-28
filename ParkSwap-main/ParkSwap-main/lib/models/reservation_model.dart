import 'package:flutter/foundation.dart';

class Reservation {
  final String id;
  final String street;
  final DateTime startTime;
  final double pricePerHour;
  int durationMinutes;

  Reservation({
    required this.id,
    required this.street,
    required this.startTime,
    this.pricePerHour = 5.0,
    this.durationMinutes = 60, // 1 hora por defecto
  });

  String get endTime => startTime.add(Duration(minutes: durationMinutes)).toString().substring(11, 16);
  String get totalCost => (pricePerHour * durationMinutes / 60).toStringAsFixed(2);
}

class ReservationProvider with ChangeNotifier {
  List<Reservation> _history = [];
  Reservation? _currentReservation;
  final Map<String, int> _parkingSpots = {}; // Almacena plazas disponibles por ubicación

  List<Reservation> get history => _history;
  Reservation? get currentReservation => _currentReservation;

  void addReservation(String street) {
    _currentReservation = Reservation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      street: street,
      startTime: DateTime.now(),
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

  // Nuevo método para actualizar plazas disponibles
  void updateParkingSpots(String location, int spots) {
    _parkingSpots[location] = spots;
    notifyListeners();
  }

  // Nuevo método para obtener plazas disponibles
  int getAvailableSpots(String location) {
    return _parkingSpots[location] ??
        _history.where((r) => r.street == location).length;
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