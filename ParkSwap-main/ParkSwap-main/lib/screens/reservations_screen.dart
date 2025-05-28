import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:parkswap/models/reservation_model.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  @override
  Widget build(BuildContext context) {
    final reservation = Provider.of<ReservationProvider>(context).currentReservation;

    if (reservation == null) {
      return const Center(child: Text('No tens reserves actives'));
    }

    // Calcula el tiempo restante
    final endTime = reservation.startTime.add(Duration(minutes: reservation.durationMinutes));
    final remaining = endTime.difference(DateTime.now());

    return Scaffold(
      appBar: AppBar(title: const Text('Reserves')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Reserva actual', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ubicació: ${reservation.street}'),
                    const SizedBox(height: 10),
                    Text('Hora inici: ${reservation.startTime.toString().substring(11, 16)}'),
                    const SizedBox(height: 10),
                    Text('Temps restant: ${remaining.inMinutes} minuts'),
                    const SizedBox(height: 10),
                    Text('Cost: ${reservation.totalCost} € (${reservation.pricePerHour}€/h)'),
                    const SizedBox(height: 20),
                    const Text('Accions disponibles:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Provider.of<ReservationProvider>(context, listen: false)
                                  .extendReservation(30);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Reserva ampliada 30 minuts')),
                              );
                            },
                            child: const Text('+30 min'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Provider.of<ReservationProvider>(context, listen: false)
                                  .extendReservation(60);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Reserva ampliada 1 hora')),
                              );
                            },
                            child: const Text('+1 hora'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () {
                          Provider.of<ReservationProvider>(context, listen: false)
                              .cancelReservation();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Reserva cancel·lada')),
                          );
                        },
                        child: const Text('Finalitzar reserva', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.help_outline),
                label: const Text('Ajuda o incidència'),
                onPressed: () => showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Incidència'),
                    content: const Text('Descriu el problema:'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel·lar'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Incidència reportada')),
                          );
                        },
                        child: const Text('Enviar'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}