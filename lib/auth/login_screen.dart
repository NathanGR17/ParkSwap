import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:parkswap/auth/auth_provider.dart';
import 'package:parkswap/auth/register_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bcrypt/bcrypt.dart';

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
      'email': 'demo@parkswap.com',
      'password': 'demo123',
      'name': 'Carlos',
      'surname': 'Mendoza',
      'phone': '+34 678056559',
      'licensePlate': 'JNX 7295'
    }
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
                'assets/images/logo_parkswap.png',
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
              TextFormField(
                controller: _emailController,
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
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    await _loginWithSupabase(context);
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

  Future<void> _loginWithSupabase(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('usuaris')
        .select()
        .eq('email', email)
        .maybeSingle();

    if (response == null) {
      _showError('No existeix cap usuari amb aquest correu.');
      return;
    }

    final passwordHash = response['password_hash'] as String?;
    if (passwordHash == null || !BCrypt.checkpw(password, passwordHash)) {
      _showError('Contrasenya incorrecta.');
      return;
    }

    // Extraeix dades de l'usuari
    final nomComplet = (response['nom'] as String?) ?? '';
    final parts = nomComplet.split(' ');
    final name = parts.isNotEmpty ? parts.first : '';
    final surname = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    final phone = response['telefon'] ?? '';
    final licensePlate = response['matricula'] ?? '';

    authProvider.login(
      id: response['id'],
      email: email,
      name: name,
      surname: surname,
      phone: phone,
      licensePlate: licensePlate,
    );

    Navigator.pushReplacementNamed(context, '/home');
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
      // Navegar al home después del login
      Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Credencials incorrectes.'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}