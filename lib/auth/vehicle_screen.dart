// lib/auth/vehicle_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:parkswap/auth/auth_provider.dart';
import 'package:parkswap/auth/payment_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VehicleScreen extends StatefulWidget {
  const VehicleScreen({super.key});

  @override
  State<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _matriculaController = TextEditingController();
  final _marcaController = TextEditingController();
  final _modeloController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Afegeix el teu vehicle'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'Afegir vehicle',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text(
                'Pots afegir el teu vehicle ara o més tard des del teu perfil.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 30),
              const Text(
                'Matrícula',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              TextFormField(
                controller: _matriculaController,
                decoration: const InputDecoration(
                  hintText: 'Ex: 1234ABC',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Si us plau, introdueix la matrícula';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              const Text(
                'Marca',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              TextFormField(
                controller: _marcaController,
                decoration: const InputDecoration(
                  hintText: 'Ex: Seat',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Si us plau, introdueix la marca';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              const Text(
                'Model',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              TextFormField(
                controller: _modeloController,
                decoration: const InputDecoration(
                  hintText: 'Ex: León',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Si us plau, introdueix el model';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    await _addVehicle();
                    // Navegar a la pantalla de pago
                    if (!mounted) return;
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PaymentScreen()),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Afegir vehicle'),
              ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: () {
                  // Saltar este paso y navegar a la pantalla de pago
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PaymentScreen()),
                  );
                },
                child: const Text('Afegir més tard'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addVehicle() async {
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    if (user == null) return;

    try {
      final supabase = Supabase.instance.client;
      await supabase.from('vehicles').insert({
        'id_usuari': user.id,
        'matricula': _matriculaController.text.trim(),
        'marca': _marcaController.text.trim(),
        'model': _modeloController.text.trim(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehicle afegit correctament')),
      );
    } catch (e) {
      print('Error al afegir vehicle: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al afegir vehicle: $e')),
      );
    }
  }
}