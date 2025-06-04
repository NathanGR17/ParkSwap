// lib/auth/auth_provider.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:shared_preferences/shared_preferences.dart';

class User {
  final String id;
  final String name;
  final String surname;
  final String email;
  final String phone;
  final String licensePlate;
  final int points;
  final String? cardInfo;

  User({
    required this.id,
    required this.name,
    required this.surname,
    required this.email,
    required this.phone,
    required this.licensePlate,
    this.points = 200,
    this.cardInfo,
  });
}

class AuthProvider with ChangeNotifier {
  User? _user;
  String? _cardInfo;

  User? get user => _user;
  String? get cardInfo => _cardInfo;

  void login({
    required String id,
    required String email,
    required String name,
    required String surname,
    required String phone,
    required String licensePlate,
  }) async {
    _user = User(
      id: id,
      name: name,
      surname: surname,
      email: email,
      phone: phone,
      licensePlate: licensePlate,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userId', id);
    await clearChatMessages();
    notifyListeners();
  }

  Future<void> register({
    required String name,
    required String surname,
    required String email,
    required String phone,
    required String licensePlate,
    required String password,
  }) async {
    final supabase = Supabase.instance.client;
    final passwordHash = BCrypt.hashpw(password, BCrypt.gensalt());

    final response = await supabase
        .from('usuaris')
        .insert({
      'email': email,
      'password_hash': passwordHash,
      'nom': '$name $surname',
      'punts': 200,
      'bloquejat': false,
      'data_creacio': DateTime.now().toIso8601String(),
    })
        .select()
        .single();

    final String id = response['id'];

    _user = User(
      id: id,
      name: name,
      surname: surname,
      email: email,
      phone: phone,
      licensePlate: licensePlate,
    );
    await clearChatMessages();
    notifyListeners();
  }

  void addPaymentCard(String cardInfo) {
    _cardInfo = cardInfo;
    notifyListeners();
  }

  void logout() async{
    _user = null;
    _cardInfo = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await clearChatMessages();
    notifyListeners();
  }

  // Metodo para limpiar los mensajes del chat
  Future<void> clearChatMessages() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('chat_messages');
  }

  // Metodo para intentar restaurar sesión:
  Future<void> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId');
    print('Intentando auto-login. userId: $userId');
    if (userId != null) {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('usuaris')
          .select()
          .eq('id', userId)
          .single();
      print('Respuesta de Supabase: $response');
      if (response != null) {
        login(
          id: response['id'],
          email: response['email'] ?? '',
          name: (response['nom'] ?? '').split(' ').first,
          surname: (response['nom'] ?? '').split(' ').skip(1).join(' '),
          phone: response['telefon'] ?? '',
          licensePlate: response['matricula'] ?? '',
        );
      }
    }
  }
}