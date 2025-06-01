import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:parkswap/auth/auth_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late String userId;

  Future<List<Map<String, dynamic>>> _fetchPastReservations() async {
    final response = await Supabase.instance.client
        .from('reserves_with_vehicle')
        .select('*')
        .eq('id_usuari', userId)
        .lt('hora_final', DateTime.now().toUtc().toIso8601String())
        .order('hora_inici', ascending: false);

    return (response as List<dynamic>).cast<Map<String, dynamic>>();
  }

  String _formatDateTime(DateTime dt) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    return dateFormat.format(dt);
  }

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    userId = authProvider.user?.id ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historial de reserves')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchPastReservations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No tens reserves anteriors'));
          }
          final reservations = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reservations.length,
            itemBuilder: (context, index) {
              final res = reservations[index];
              final matricula = res['vehicle_matricula'] ?? res['id_vehicle'];
              final carrer = res['carrers'];
              final startUtc = DateTime.parse(res['hora_inici']).toLocal();
              final endUtc = DateTime.parse(res['hora_final']).toLocal();

              final startStr = _formatDateTime(startUtc);
              final endStr = _formatDateTime(endUtc);

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.history, color: Colors.grey),
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
                      if (res['preu_total'] != null)
                        Text('Cost total: ${res['preu_total']}€'),
                    ],
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