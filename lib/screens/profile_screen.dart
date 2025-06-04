import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:parkswap/auth/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('El meu perfil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundImage: AssetImage('assets/images/default-profile.png'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${user.name} ${user.surname}',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.email,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Informació personal',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildInfoCard([
              _buildInfoRow(Icons.phone, 'Telèfon', user.phone),
              _buildInfoRow(Icons.directions_car, 'Matrícula', user.licensePlate ?? '-'),
              _buildInfoRow(Icons.credit_card, 'Mètode de pagament',
                  authProvider.cardInfo ?? 'Cap mètode afegit'),
            ]),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Els meus vehicles',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Afegir'),
                  onPressed:_addVehicle,
                ),
              ],
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<dynamic>>(
              future: _fetchUserVehicles(user.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final vehicles = snapshot.data;
                if (vehicles == null || vehicles.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(
                        child: Text('No tens vehicles registrats'),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: vehicles.length,
                  itemBuilder: (context, index) {
                    final vehicle = vehicles[index] as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const Icon(Icons.directions_car),
                        title: Text(vehicle['matricula'] ?? 'Matrícula no disponible'),
                        subtitle: Text('${vehicle['marca'] ?? ''} ${vehicle['model'] ?? ''}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.info),
                          onPressed: () => _showVehicleInfo(context, user.id),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () {
                  authProvider.logout();
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text(
                  'Tancar sessió',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Future<List<dynamic>> _fetchUserVehicles(String userId) async {
    try {


      // Consulta a Supabase
      final result = await Supabase.instance.client
          .from('vehicles')
          .select('*')
          .eq('id_usuari', userId);


      // Devuelve el resultado
      return result as List<dynamic>;
    } catch (e) {
      print('Error al obtener vehículos: $e');
      // En caso de error, devuelve una lista vacía
      return [];
    }
  }
  Future<void> _addVehicle() async {
    final supabase = Supabase.instance.client;
    final user = Provider.of<AuthProvider>(context, listen: false).user;
    final TextEditingController matriculaController = TextEditingController();
    final TextEditingController marcaController = TextEditingController();
    final TextEditingController modeloController = TextEditingController();
    if (user == null) return;

    // Comprobar si ya existe un vehículo para este usuario
    final existingVehicles = await supabase
        .from('vehicles')
        .select()
        .eq('id_usuari', user.id);

    if (existingVehicles != null && (existingVehicles as List).isNotEmpty) {
      // El usuario ya tiene un vehículo
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Només pots tenir un vehicle registrat. Elimina l\'actual per afegir-ne un de nou.'),
          backgroundColor: Colors.red,
        ),
      );
      return; // Salir de la función sin añadir otro vehículo
    }
    bool? result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Afegir vehicle'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: matriculaController,
                  decoration: const InputDecoration(
                    labelText: 'Matrícula',
                    hintText: 'Ex: 1234ABC',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: marcaController,
                  decoration: const InputDecoration(
                    labelText: 'Marca',
                    hintText: 'Ex: Seat',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: modeloController,
                  decoration: const InputDecoration(
                    labelText: 'Model',
                    hintText: 'Ex: León',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel·lar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Afegir'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      final user = Provider.of<AuthProvider>(context, listen: false).user;
      if (user != null) {
        try {
          final supabase = Supabase.instance.client;
          await supabase.from('vehicles').insert({
            'id_usuari': user.id,
            'matricula': matriculaController.text.trim(),
            'marca': marcaController.text.trim(),
            'model': modeloController.text.trim(),
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Vehicle afegit correctament')),
            );
            setState(() {
              // Esto fuerza una recarga de la pantalla
            });
          }
        } catch (e) {
          if (mounted) {
            print('Error al afegir vehicle: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error al afegir vehicle: $e')),
            );
          }
        }
      }
    }
  }
  Future<void> _deleteVehicle(BuildContext context, String vehicleId) async {
    // Mostrar diálogo de confirmación
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminació'),
        content: const Text('Estàs segur que vols eliminar aquest vehicle?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel·lar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmDelete != true) return;

    try {
      // Cerrar el diálogo de información
      Navigator.pop(context);

      // Eliminar de la base de datos
      await Supabase.instance.client
          .from('vehicles')
          .delete()
          .eq('id', vehicleId);

      // Mostrar mensaje de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehicle eliminat correctament')),
        );

        // Actualizar la lista de vehículos
        setState(() {
          // Esto fuerza una recarga de la pantalla
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar el vehicle: $e')),
        );
      }
    }
  }
  void _showVehicleInfo(BuildContext context, String userId) async {
    try {
      // Mostrar loading mientras se obtienen los datos
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator()),
      );

      // Obtener vehículos del usuario
      final response = await Supabase.instance.client
          .from('vehicles')
          .select()
          .eq('id_usuari', userId)
          .maybeSingle();


      // Cerrar diálogo de loading
      Navigator.of(context, rootNavigator: true).pop();

      if (response == null) {
        _showNoVehicleDialog(context);
        return;
      }

      // Convertir la respuesta a Map
      final vehicleData = response as Map<String, dynamic>;

      // Mostrar información en diálogo
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Informació del vehicle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildVehicleInfoRow("Matrícula:", vehicleData['matricula']?.toString() ?? 'No disponible'),
              _buildVehicleInfoRow("Marca:", vehicleData['marca']?.toString() ?? 'No disponible'),
              _buildVehicleInfoRow("Model:", vehicleData['model']?.toString() ?? 'No disponible'),
              // Otros campos de información
              const SizedBox(height: 20),
              // Botón para eliminar el vehículo
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  onPressed: () => _deleteVehicle(context, vehicleData['id']),
                  child: const Text('Eliminar vehicle', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),

        ),
      );
    } catch (e) {
      // Cerrar diálogo de loading si hay error
      Navigator.of(context, rootNavigator: true).pop();

      // Mostrar error
      print('Error al obtener información del vehículo: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showNoVehicleDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Sense vehicles"),
          content: const Text("No tens cap vehicle registrat."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Tancar"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVehicleInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}