import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:parkswap/models/reservation_model.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final history = Provider.of<ReservationProvider>(context).history;

    return Scaffold(
      appBar: AppBar(title: const Text('Historial de reserves')),
      body: history.isEmpty
          ? const Center(child: Text('No tens historial de reserves'))
          : ListView.builder(
        itemCount: history.length,
        itemBuilder: (context, index) {
          final reservation = history[index];
          final date = '${reservation.startTime.day}/${reservation.startTime.month}/${reservation.startTime.year.toString().substring(2)}';

          return Column(
            children: [
              ListTile(
                leading: Text(date),
                title: Text(reservation.street),
                subtitle: Text(
                  '${reservation.startTime.hour}:${reservation.startTime.minute.toString().padLeft(2, '0')} - ${reservation.durationMinutes} min',
                ),
                trailing: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${reservation.totalCost} €'),
                    Text('${reservation.pricePerHour}€/h', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              const Divider(),
            ],
          );
        },
      ),
    );
  }
}