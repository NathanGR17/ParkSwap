// lib/auth/auth_provider.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:bcrypt/bcrypt.dart';

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
  }) {
    _user = User(
      id: id,
      name: name,
      surname: surname,
      email: email,
      phone: phone,
      licensePlate: licensePlate,
    );
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
    notifyListeners();
  }

  void addPaymentCard(String cardInfo) {
    _cardInfo = cardInfo;
    notifyListeners();
  }

  void logout() {
    _user = null;
    _cardInfo = null;
    notifyListeners();
  }
}