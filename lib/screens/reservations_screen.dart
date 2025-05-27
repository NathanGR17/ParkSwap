import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  final String userId = 'a0fb52ec-6500-4655-9e4e-c31e0a4d2dc0';

  Future<List<Map<String, dynamic>>> _fetchReservations() async {
    final response = await Supabase.instance.client
        .from('reserves_with_vehicle')
        .select('*')
        .eq('id_usuari', userId)
        .gt('hora_final', DateTime.now().toIso8601String())
        .order('hora_inici', ascending: false);

    return (response as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<void> _deleteReservation(String id) async {
    await Supabase.instance.client.from('reserves').delete().eq('id', id);
    setState(() {}); // Recarrega la llista
  }

  @override
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
              print(res);
              final vehicles = res['vehicles'];
              final matricula = res['vehicle_matricula'] ?? res['id_vehicle'];
              final carrer = res['carrers'];
              final start = DateTime.parse(res['hora_inici']);
              final end = DateTime.parse(res['hora_final']);
              final remaining = end.difference(DateTime.now());

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
                          Text('Hora inici: ${start.toString().substring(0, 16).replaceAll('T', ' ')}'),
                          Text('Hora final: ${end.toString().substring(0, 16).replaceAll('T', ' ')}'),
                          Text('Temps restant: ${remaining.inMinutes > 0 ? "${remaining.inMinutes} minuts" : "Caducada"}'),
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
                        Text('Inici: ${start.toString().substring(11, 16)}'),
                        Text('Fi: ${end.toString().substring(11, 16)}'),
                        Text('Temps restant: ${remaining.inMinutes > 0 ? "${remaining.inMinutes} minuts" : "Caducada"}'),
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