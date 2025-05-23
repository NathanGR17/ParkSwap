import 'package:flutter/foundation.dart';

class User {
  final String name;
  final String surname;
  final String email;
  final String phone;
  final String licensePlate;
  final int points;
  final String? cardInfo;

  User({
    required this.name,
    required this.surname,
    required this.email,
    required this.phone,
    required this.licensePlate,
    this.points = 200, // Puntos iniciales
    this.cardInfo,
  });
}

class AuthProvider with ChangeNotifier {
  User? _user;
  String? _cardInfo;

  User? get user => _user;
  String? get cardInfo => _cardInfo;

  void login({
    required String email,
    required String name,
    required String surname,
    required String phone,
    required String licensePlate,
  }) {
    _user = User(
      name: name,
      surname: surname,
      email: email,
      phone: phone,
      licensePlate: licensePlate,
    );
    notifyListeners();
  }

  void register({
    required String name,
    required String surname,
    required String email,
    required String phone,
    required String licensePlate,
  }) {
    _user = User(
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