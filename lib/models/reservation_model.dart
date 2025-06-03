import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Reservation {
  final String id;
  final String userId;
  final String vehicleId;
  final String vehicleMatricula;
  final String carrerId;
  final String carrerNom;
  final DateTime horaInici;
  final DateTime horaFinal;
  final double pricePerHour;
  final double totalCost;

  Reservation({
    required this.id,
    required this.userId,
    required this.vehicleId,
    required this.vehicleMatricula,
    required this.carrerId,
    required this.carrerNom,
    required this.horaInici,
    required this.horaFinal,
    required this.pricePerHour,
    required this.totalCost,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id'],
      userId: json['id_usuari'],
      vehicleId: json['id_vehicle'],
      vehicleMatricula: json['vehicle_matricula'] ?? '',
      carrerId: json['id_carrer'],
      carrerNom: json['carrer_nom'] ?? '',
      horaInici: DateTime.parse(json['hora_inici']),
      horaFinal: DateTime.parse(json['hora_final']),
      pricePerHour: (json['preu_hora'] ?? 5.0).toDouble(),
      totalCost: (json['preu_total'] ?? 0.0).toDouble(),
    );
  }
}

class ReservationProvider with ChangeNotifier {
  final List<Reservation> _reservations = [];

  List<Reservation> get reservations => [..._reservations];

  Future<void> addReservation({
    required String userId,
    required String vehicleId,
    required String carrerId,
    required String vehicleMatricula,
    required String carrerNom,
    DateTime? startTime,
    int durationHours = 1,
  }) async {
    final now = DateTime.now();
    final startDateTime = startTime ?? now;
    final endDateTime = startDateTime.add(Duration(hours: durationHours));
    final pricePerHour = 5.0; // Precio fijo por hora
    final totalCost = pricePerHour * durationHours;

    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.from('reserves').insert({
        'id_usuari': userId,
        'id_vehicle': vehicleId,
        'id_carrer': carrerId,
        'hora_inici': startDateTime.toUtc().toIso8601String(),
        'hora_final': endDateTime.toUtc().toIso8601String(),
      }).select();

      if (response != null && response.isNotEmpty) {
        final newReservation = Reservation.fromJson(response[0]);
        _reservations.add(newReservation);
        notifyListeners();
      }
    } catch (e) {
      print('Error al crear reserva: $e');
      rethrow;
    }
  }
  Future<void> extendReservation(String id, int minuts) async {
    // Obté la reserva actual
    final response = await Supabase.instance.client
        .from('reserves')
        .select('hora_final')
        .eq('id', id)
        .single();

    final currentEnd = DateTime.parse(response['hora_final']);
    final newEnd = currentEnd.add(Duration(minutes: minuts));

    await Supabase.instance.client
        .from('reserves')
        .update({'hora_final': newEnd.toUtc().toIso8601String()})
        .eq('id', id);


    notifyListeners(); // Refresca la llista
  }

  Future<void> reportIncidence({
    required String userId,
    required String reservaId,
    required String descripcio,
  }) async {
    final now = DateTime.now().toUtc().toIso8601String();
    await Supabase.instance.client.from('incidencies').insert({
      'usuari_id': userId,
      'reserva_id': reservaId,
      'descripcio': descripcio,
      'data_incidencia': now,
      'estat': 'Pendent',
    });
  }

  Future<List<Reservation>> fetchUserReservations(String userId) async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('reserves_with_vehicle')
          .select()
          .eq('id_usuari', userId)
          .lt('hora_final', DateTime.now().toIso8601String()) // Solo reservas pasadas
          .order('hora_inici', ascending: false);

      final List<Reservation> pastReservations = [];
      for (var item in response) {
        pastReservations.add(Reservation.fromJson(item));
      }

      return pastReservations;
    } catch (e) {
      print('Error al obtener historial de reservas: $e');
      return [];
    }
  }
}