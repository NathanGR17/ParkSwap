import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:parkswap/auth/auth_provider.dart';
import 'package:parkswap/auth/register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Lista de usuarios de prueba
  final List<Map<String, String>> testUsers = [
    {
      'email': 'usuario1@test.com',
      'password': '123456',
      'name': 'Carlos',
      'surname': 'Mendoza',
      'phone': '+34 678056559',
      'licensePlate': 'JNX 7295'
    },
    {
      'email': 'usuario2@test.com',
      'password': '123456',
      'name': 'Ana',
      'surname': 'García',
      'phone': '+34 600112233',
      'licensePlate': 'ABC 1234'
    },
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo personalizado - reemplaza con tu imagen
              Image.asset(
                'assets/images/logo_parkswap.png', // Ruta a tu logo
                height: 100,
                width: 100,
              ),
              const SizedBox(height: 20),
              const Text(
                'ParkSwap',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Troba aparcament fàcilment',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 5),
              const Text(
                'Comparteix. Reserva. Aparca.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 30),
              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  return testUsers
                      .map((user) => user['email']!)
                      .where((email) => email
                      .toLowerCase()
                      .contains(textEditingValue.text.toLowerCase()));
                },
                onSelected: (String email) {
                  final user = testUsers.firstWhere(
                          (user) => user['email'] == email);
                  _emailController.text = email;
                  _passwordController.text = user['password']!;
                },
                fieldViewBuilder: (BuildContext context,
                    TextEditingController emailController,
                    FocusNode focusNode,
                    VoidCallback onFieldSubmitted) {
                  return TextFormField(
                    controller: emailController,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Correu electrònic',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Si us plau, introdueix el teu correu';
                      }
                      if (!value.contains('@')) {
                        return 'Correu electrònic invàlid';
                      }
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contrasenya',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Si us plau, introdueix la contrasenya';
                  }
                  if (value.length < 6) {
                    return 'La contrasenya ha de tenir mínim 6 caràcters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // Navegar a pantalla de recuperación
                  },
                  child: const Text('Has oblidat la contrasenya?'),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _loginWithTestUser(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.blue[800],
                ),
                child: const Text(
                  'Iniciar sessió',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const RegisterScreen()),
                  );
                },
                child: const Text('Encara no tens compte? Registra\'t'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _loginWithTestUser(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = _emailController.text.trim(); // Añadido trim()
    final password = _passwordController.text.trim(); // Añadido trim()

    try {
      final user = testUsers.firstWhere(
              (u) => u['email']?.toLowerCase() == email.toLowerCase() &&
              u['password'] == password
      );

      authProvider.login(
        email: user['email']!,
        name: user['name']!,
        surname: user['surname']!,
        phone: user['phone']!,
        licensePlate: user['licensePlate']!,
      );

      // Navegar al home después del login
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Credenciales incorrectas. Usuarios disponibles:\n${testUsers.map((u) => u['email']).join('\n')}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}