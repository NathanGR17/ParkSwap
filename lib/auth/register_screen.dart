// En lib/auth/register_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:parkswap/auth/auth_provider.dart';
import 'package:parkswap/auth/vehicle_screen.dart'; // Importar nueva pantalla

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  // Eliminamos _licensePlateController
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crea el teu compte'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'Nom',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Introdueix el teu nom',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Si us plau, introdueix el teu nom';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              const Text(
                'Cognoms',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              TextFormField(
                controller: _surnameController,
                decoration: const InputDecoration(
                  hintText: 'Introdueix els teus cognoms',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Si us plau, introdueix els teus cognoms';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              const Text(
                'Telèfon',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: 'Introdueix el teu telèfon',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Si us plau, introdueix el teu telèfon';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              const Text(
                'Correu electrònic',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'Introdueix el teu correu electrònic',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Si us plau, introdueix el teu correu electrònic';
                  }
                  if (!value.contains('@')) {
                    return 'Si us plau, introdueix un correu electrònic vàlid';
                  }
                  return null;
                },
              ),
              // Eliminamos el campo de matrícula
              const SizedBox(height: 15),
              const Text(
                'Contrasenya',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  hintText: 'Introdueix la teva contrasenya',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Si us plau, introdueix la teva contrasenya';
                  }
                  if (value.length < 6) {
                    return 'La contrasenya ha de tenir almenys 6 caràcters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    await authProvider.register(
                      name: _nameController.text,
                      surname: _surnameController.text,
                      email: _emailController.text,
                      phone: _phoneController.text,
                      password: _passwordController.text,
                      // Ya no pasamos licensePlate
                    );
                    // Navegar a la pantalla de vehículo en lugar de pago
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const VehicleScreen()),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Crear compte'),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Ja tens un compte? Inicia sessió'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}