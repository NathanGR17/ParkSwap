import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:parkswap/auth/auth_provider.dart';
import 'package:parkswap/models/reservation_model.dart';
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
                      content: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Carrer: ${carrer?['nom'] ?? res['carrer_nom']}'),
                            Text('Matrícula: $matricula'),
                            Text('Hora inici: $startStr'),
                            Text('Hora final: $endStr'),
                            Text('Temps restant: $remainingStr'),
                            const SizedBox(height: 20),
                            const Text('Accions disponibles:', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () async {
                                      await Provider.of<ReservationProvider>(context, listen: false)
                                          .extendReservation(res['id'].toString(), 30);
                                      setState(() {});
                                      Navigator.pop(context);
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
                                    onPressed: () async {
                                      await Provider.of<ReservationProvider>(context, listen: false)
                                          .extendReservation(res['id'].toString(), 60);
                                      setState(() {});
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Reserva ampliada 1 hora')),
                                      );
                                    },
                                    child: const Text('+1 hora'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.help_outline),
                                label: const Text('Ajuda o incidència'),
                                // Dins del teu onPressed de 'Ajuda o incidència':
                                onPressed: () {
                                  final TextEditingController _controller = TextEditingController();
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Incidència'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text('Descriu el problema:'),
                                          const SizedBox(height: 10),
                                          TextField(
                                            controller: _controller,
                                            maxLines: 3,
                                            decoration: const InputDecoration(
                                              border: OutlineInputBorder(),
                                              hintText: 'Escriu aquí la teva incidència',
                                            ),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Cancel·lar'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () async {
                                            final text = _controller.text;
                                            final userId = Provider.of<AuthProvider>(context, listen: false).user?.id ?? '';
                                            final reservaId = res['id'].toString();
                                            await Provider.of<ReservationProvider>(context, listen: false)
                                                .reportIncidence(userId: userId, reservaId: reservaId, descripcio: text);
                                            Navigator.pop(context);
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Incidència reportada')),
                                            );
                                          },
                                          child: const Text('Enviar'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 16),
                            Center(
                              child: TextButton.icon(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                label: const Text(
                                  'Cancel·lar reserva',
                                  style: TextStyle(color: Colors.red),
                                ),
                                onPressed: () async {
                                  await _deleteReservation(res['id'].toString());
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Reserva cancel·lada')),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
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