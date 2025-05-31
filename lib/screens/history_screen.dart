import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:parkswap/models/reservation_model.dart';
import 'package:parkswap/auth/auth_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (!_loaded && user != null) {
      Provider.of<ReservationProvider>(context, listen: false)
          .fetchUserReservations(user.id);
      _loaded = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final history = Provider.of<ReservationProvider>(context).history;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Historial de reserves')),
      body: history.isEmpty
          ? const Center(child: Text('No tens historial de reserves'))
          : ListView.builder(
        itemCount: history.length,
        itemBuilder: (context, index) {
          final reservation = history[index];
          final date =
              '${reservation.horaInici.day}/${reservation.horaInici.month}/${reservation.horaInici.year.toString().substring(2)}';
          final start =
              '${reservation.horaInici.hour.toString().padLeft(2, '0')}:${reservation.horaInici.minute.toString().padLeft(2, '0')}';
          final end =
              '${reservation.horaFinal.hour.toString().padLeft(2, '0')}:${reservation.horaFinal.minute.toString().padLeft(2, '0')}';
          return Column(
            children: [
              ListTile(
                leading: Text(date),
                title: Text(reservation.carrerNom),
                subtitle: Text('$start - $end'),
                trailing: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${reservation.totalCost} €'),
                    Text('${reservation.pricePerHour}€/h', style: const TextStyle(fontSize: 12)),
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