import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:parkswap/auth/auth_provider.dart';
import 'package:parkswap/screens/home_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_stripe/flutter_stripe.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Nova funció per afegir targeta a Stripe
  Future<void> addCardToStripe(String customerId, String userId) async {
    // 1. Obtenir clientSecret del backend
    final response = await http.post(
      Uri.parse('http://10.0.2.2:4242/create-setup-intent'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'customerId': customerId}),
    );
    final clientSecret = json.decode(response.body)['clientSecret'];

    // 2. Presentar el formulari de Stripe per afegir la targeta
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        merchantDisplayName: 'ParkSwap',
        customerId: customerId,
        setupIntentClientSecret: clientSecret,
        style: ThemeMode.light,
      ),
    );
    await Stripe.instance.presentPaymentSheet();

    // 3. Obtenir el paymentMethodId (opcional: podries obtenir-lo via webhook)
    // Alternativament, fes servir Stripe webhooks per associar payment method a customer i guardar-ho a Supabase.
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Afegir targeta de crèdit'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text(
                'Per fer pagaments a través de l\'app, si us plau afegeix una targeta de crèdit',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              const Text(
                'Número de targeta',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              TextFormField(
                controller: _cardNumberController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: '1234 5678 9012 3456',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Si us plau, introdueix el número de targeta';
                  }
                  if (value.length < 16) {
                    return 'El número de targeta ha de tenir 16 dígits';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Data de caducitat',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),
                        TextFormField(
                          controller: _expiryController,
                          keyboardType: TextInputType.datetime,
                          decoration: const InputDecoration(
                            hintText: 'MM/AA',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Requerit';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CVV',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5),
                        TextFormField(
                          controller: _cvvController,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          decoration: const InputDecoration(
                            hintText: '123',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Requerit';
                            }
                            if (value.length != 3) {
                              return 'CVV ha de tenir 3 dígits';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              const Text(
                'Titular de la targeta',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              TextFormField(
                controller: _cardHolderController,
                decoration: const InputDecoration(
                  hintText: 'Nom del titular',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Si us plau, introdueix el nom del titular';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    authProvider.addPaymentCard(
                      '${_cardNumberController.text}|${_expiryController.text}|${_cvvController.text}',
                    );

                    // Navegar a la pantalla principal
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const HomeScreen()),
                          (route) => false,
                    );
                  }
                },
                /*onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final authProvider = Provider.of<AuthProvider>(context, listen: false);
                    final userId = authProvider.userId; // Assegura't que tens l'userId
                    final customerId = authProvider.customerId; // Assegura't que tens el customerId

                    await addCardToStripe(customerId, userId);

                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const HomeScreen()),
                          (route) => false,
                    );
                  }
                },*/
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text('Guardar targeta'),
              ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: () {
                  // Omitir por ahora y navegar a la pantalla principal
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const HomeScreen()),
                        (route) => false,
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
}