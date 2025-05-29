import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:parkswap/auth/auth_provider.dart';
import 'package:parkswap/auth/payment_screen.dart';

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
  final _licensePlateController = TextEditingController();
  final _carBrandController = TextEditingController();
  final _carModelController = TextEditingController();

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
                  hintText: 'Introdueix el teu email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Si us plau, introdueix el teu email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              const Text(
                'Matrícula',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              TextFormField(
                controller: _licensePlateController,
                decoration: const InputDecoration(
                  hintText: 'Introdueix la matrícula del cotxe',
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
                'Marca del cotxe',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              TextFormField(
                controller: _carBrandController,
                decoration: const InputDecoration(
                  hintText: 'Exemple: Toyota, BMW...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Si us plau, introdueix la marca del cotxe';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              const Text(
                'Model del cotxe',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              TextFormField(
                controller: _carModelController,
                decoration: const InputDecoration(
                  hintText: 'Exemple: Corolla, Sèrie 3...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Si us plau, introdueix el model del cotxe';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    Provider.of<AuthProvider>(context, listen: false).register(
                      name: _nameController.text,
                      surname: _surnameController.text,
                      phone: _phoneController.text,
                      email: _emailController.text,
                      licensePlate: _licensePlateController.text,
                      carBrand: _carBrandController.text,
                      carModel: _carModelController.text,
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PaymentScreen()),
                    );
                  }
                },
                child: const Text('Registrar-se'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
