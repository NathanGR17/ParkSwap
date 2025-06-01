import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:parkswap/models/reservation_model.dart';
import 'package:parkswap/auth/auth_provider.dart';
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final List<String> _availableStreets = [
    'Carrer Roc Boronat, 138',
    'Av. Diagonal 88',
    'Carrer dels Almogàvers, 23'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cercar zona'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cerca una adreça o zona',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _searchController.clear(),
                ),
              ),
              onSubmitted: (value) => _searchStreet(value),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Recents',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _availableStreets.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(_availableStreets[index]),
                  onTap: () => _showStreetInfo(_availableStreets[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _searchStreet(String street) {
    if (_availableStreets.contains(street)) {
      _showStreetInfo(street);
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text("S'ha produit un error. Torna a intentar més tard."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tornar'),
            ),
          ],
        ),
      );
    }
  }

  void _showStreetInfo(String street) {
    final reservationProvider = Provider.of<ReservationProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para reservar.')),
      );
      return;
    }

    // Simulación de IDs (ajusta según tu lógica real)
    final vehicleId = "aa2078a8-bad9-4bbd-af69-ed306bac2f00";
    final carrerId = _availableStreets.indexOf(street) + 1;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(street, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text('Tarifa: 5€/hora'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  onPressed: () {
                    reservationProvider.addReservation(
                      userId: user.id,
                      vehicleId: vehicleId,
                      carrerId: carrerId.toString(),
                      vehicleMatricula: user.licensePlate,
                      carrerNom: street,
                    );
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Reserva confirmada. Tens 10 minuts per arribar.')),
                    );
                  },
                  child: const Text('Ocupar', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}