import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:parkswap/auth/auth_provider.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  late String userId;

  Future<List<Map<String, dynamic>>> _fetchReservations() async {
    print('Hora actual: ${DateTime.now().toIso8601String()}'); // <-- Añade este print
    print('ID de usuario: $userId'); // <-- Añade este print
    final response = await Supabase.instance.client
        .from('reserves_with_vehicle')
        .select('*')
        .eq('id_usuari', userId)
        .gt('hora_final', DateTime.now().toUtc().toIso8601String())
        .order('hora_inici', ascending: false);

    print('Reservas obtenidas de Supabase: $response'); // <-- Añade este print

    return (response as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<void> _deleteReservation(String id) async {
    await Supabase.instance.client.from('reserves').delete().eq('id', id);
    setState(() {}); // Recarrega la llista
  }

  String _formatDateTime(DateTime dt) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    return dateFormat.format(dt);
  }

  String _formatRemaining(Duration remaining) {
    if (remaining.inSeconds <= 0) return 'Caducada';
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    return '${hours}h ${minutes}min';
  }

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    userId = authProvider.user?.id ?? '';
  }
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reserves actives')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchReservations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No tens reserves actives'));
          }
          final reservations = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reservations.length,
            itemBuilder: (context, index) {
              final res = reservations[index];
              final vehicles = res['vehicles'];
              final matricula = res['vehicle_matricula'] ?? res['id_vehicle'];
              final carrer = res['carrers'];
              final startUtc = DateTime.parse(res['hora_inici']).toUtc();
              final endUtc = DateTime.parse(res['hora_final']).toUtc();
              final nowUtc = DateTime.now().toUtc();
              final remaining = endUtc.difference(nowUtc);

// Para mostrar en local:
              final startStr = _formatDateTime(startUtc.toLocal());
              final endStr = _formatDateTime(endUtc.toLocal());
              final remainingStr = _formatRemaining(remaining);

              return GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Detalls de la reserva'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Carrer: ${carrer?['nom'] ?? res['carrer_nom']}'),
                          Text('Matrícula: $matricula'),
                          Text('Hora inici: $startStr'),
                          Text('Hora final: $endStr'),
                          Text('Temps restant: $remainingStr'),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                  onPressed: () async {
                                    await _deleteReservation(res['id'].toString());
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Reserva cancel·lada')),
                                    );
                                  },
                                  child: const Text('Cancel·lar reserva', style: TextStyle(color: Colors.white)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.local_parking, color: Colors.blue),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                carrer?['nom'] ?? 'Carrer: ${res['carrer_nom']}',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text('Matrícula: $matricula'),
                        const SizedBox(height: 6),
                        Text('Inici: $startStr'),
                        Text('Fi: $endStr'),
                        Text('Temps restant: $remainingStr'),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}